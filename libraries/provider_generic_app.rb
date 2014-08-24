require 'chef/resource'
require 'chef/provider'
require 'chef/resource/git'
require 'chef/provider/git'
require 'chef/resource/directory'
require 'chef/provider/directory'
require 'chef/resource/template'
require 'chef/provider/template'
require 'chef/resource/file'
require 'chef/provider/file'
require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

class Chef
  class Provider
    class GenericApp < Chef::Provider
      def load_current_resource
        @current_resource ||= Chef::Resource::GenericApp.new(new_resource.name)
        @current_resource
      end

      def action_deploy
        run_checkout

        # Only run callbacks if something has changed
        if new_resource.updated_by_last_action?
          callback(:after_checkout, new_resource.after_checkout)
        end
        web_server_setup
      end

      def action_remove

      end

      def callback(what, callback_code=nil)
        Chef::Log.info "#{@new_resource} running callback #{what}"
        recipe_eval(&callback_code)
      end

      # Going to make sure that the web server service will exist
      # Could just look for the service in the resource list instead I suppose
      def check_recipes
        if new_resource.web_server == 'apache'
          web_server_recipe = "apache2::default"
        else
          web_server_recipe = "#{new_resource.web_server}::default"
        end

        unless run_context.loaded_recipes.include?(web_server_recipe)
          Chef::Application.fatal!("Did not include the #{web_server_recipe} recipe")
        end
      end

      def run_checkout
        check_recipes
        base_path.run_action :create
        unless new_resource.respond_to? :deploy_key
          setup_ssh_wrapper
        end

        git_repo.run_action :sync
        new_resource.updated_by_last_action true if git_repo.updated_by_last_action?
      end

      def base_path
        return @base_path unless @base_path.nil?
        @base_path = Chef::Resource::Directory.new(new_resource.path, run_context)
        @base_path.user new_resource.owner
        @base_path.group new_resource.group
        @base_path.mode 0755
        @base_path
      end

      def git_repo
        return @git_repo unless @git_repo.nil?
        @git_repo = Chef::Resource::Git.new(new_resource.name, run_context)
        @git_repo.user new_resource.owner
        @git_repo.group new_resource.group
        @git_repo.ssh_wrapper @ssh_wrapper.name unless new_resource.respond_to? :deploy_key
        @git_repo.repository new_resource.repository
        @git_repo.revision new_resource.revision
        @git_repo.destination new_resource.path
        @git_repo
      end

      def setup_ssh_wrapper
        ssh_wrapper_script.run_action :create
        deploy_key.run_action :create
        if ssh_wrapper_script.updated_by_last_action? || deploy_key.updated_by_last_action?
          new_resource.updated_by_last_action true
        end
      end

      def ssh_wrapper_script
        return @ssh_wrapper_script unless @ssh_wrapper_script.nil?
        script_name = ::File.join(new_resource.path, '.ssh_wrapper')
        @ssh_wrapper_script = Chef::Resource::Template.new(script_name, run_context)
        @ssh_wrapper_script.mode 0554
        @ssh_wrapper_script.owner new_resource.owner
        @ssh_wrapper_script.group new_resource.group
        @ssh_wrapper_script.source 'git-ssh-wrapper.erb'
        @ssh_wrapper_script.cookbook 'genericapp'
        @ssh_wrapper_script.variables(deploy_dir: new_resource.path)
        @ssh_wrapper_script
      end

      def deploy_key
        return @deploy_key unless @deploy_key.nil?
        key = ::File.join(new_resource.path, '.id_deploy')
        @deploy_key = Chef::Resource::File.new(key, run_context)
        @deploy_key.mode 0400
        @deploy_key.owner new_resource.owner
        @deploy_key.group new_resource.group
        @deploy_key.content new_resource.deploy_key
        @deploy_key
      end

      def web_server_setup
        send("#{new_resource.web_server}_setup".to_sym)
      end

      def web_conf
        if new_resource.web_template.nil?
          "generic-#{new_resource.web_server}.erb"
        else
          new_resource.web_template
        end
      end

      def web_conf_cookbook
        if new_resource.web_template.nil?
          return 'genericapp'
        else
          return run_context.cookbook_name
        end
      end

      def apache_setup
        apache_dir = run_context.node.apache.dir
        site_conf = ::File.join(apache_dir,
                                "sites-available/#{new_resource.name}.conf")
        apache_conf = Chef::Resource::Template.new(new_resource.name, run_context)
        apache_conf.path site_conf
        apache_conf.cookbook web_conf_cookbook
        apache_conf.source web_conf
        apache_conf.variables({document_root: new_resource.path,
                               server_name: new_resource.name,
                               params: new_resource.web_params})
        apache_conf.owner run_context.node.apache.user
        apache_conf.group run_context.node.apache.group
        apache_conf.mode 0644
        apache_conf.notifies :reload, "service[apache2]", :delayed
        apache_conf.run_action :create

        if apache_conf.updated_by_last_action?
          unless apache_site_enabled?
            Chef::Log.debug("Enabling Apache site #{new_resource.name}")
            shell_out("/usr/sbin/a2ensite #{new_resource.name}.conf")
          end

          new_resource.updated_by_last_action true
        end
      end

      def apache_site_enabled?
        apache_dir = run_context.node.apache.dir
        conf_name = "#{new_resource.name}.conf"
        ::File.symlink?("#{apache_dir}/sites-enabled/#{conf_name}") ||
        ::File.symlink?("#{apache_dir}/sites-enabled/000-#{conf_name}")
      end

      def nginx_setup
        nginx_dir = run_context.node.nginx.dir
        site_conf = ::File.join(nginx_dir,
                                "sites-available/#{new_resource.name}.conf")
        nginx_conf = Chef::Resource::Template.new(new_resource.name, run_context)
        nginx_conf.path site_conf
        nginx_conf.cookbook web_conf_cookbook
        nginx_conf.source web_conf
        nginx_conf.variables({document_root: new_resource.path,
                              server_name: new_resource.name,
                              params: new_resource.web_params})
        nginx_conf.owner run_context.node.nginx.user
        nginx_conf.group run_context.node.nginx.group
        nginx_conf.mode 0544
        nginx_conf.notifies :reload, "service[nginx]", :delayed
        nginx_conf.run_action :create

        if nginx_conf.updated_by_last_action?
          unless nginx_site_enabled?
            enable_script = "#{run_context.node.nginx.script_dir}/nxensite #{new_resource.name}.conf"
            Chef::Log.debug("Enabling Nginx site #{new_resource.name}")
            shell_out(enable_script)
          end

          new_resource.updated_by_last_action true
        end
      end

      def nginx_site_enabled?
        nginx_dir = run_context.node.nginx.dir
        conf_name = "#{new_resource.name}.conf"
        ::File.symlink?("#{nginx_dir}/sites-enabled/#{conf_name}") ||
        ::File.symlink?("#{nginx_dir}/sites-enabled/000-#{conf_name}")
      end
    end
  end
end
