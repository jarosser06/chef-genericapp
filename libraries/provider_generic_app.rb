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
require 'mixlib/shellout'

class Chef
  class Provider
    class GenericApp < Chef::Provider
      def load_current_resource
        @current_resource ||= Chef::Resource::GenericApp.new(new_resource.name)
        @current_resource
      end

      ## TODO: Throw an error if nginx or apache aren't in the run_list
      def action_deploy
        base_path.run_action :create
        unless new_resource.deploy_key.nil?
          setup_ssh_wrapper
        end

        unless new_resource.updated_by_last_action?
          new_resource.updated_by_last_action apache_setup
        end
      end

      def action_remove

      end

      def base_path
        return @base_path unless @base_path.nil?
        @base_path = Chef::Resource::Directory.new(new_resource.path, run_context)
        @base_path.user new_resource.owner
        @base_path.group new_resource.group
        @base_path.mode 0754
        @base_path
      end

      def git_repo
        return @git_repo unless @git_repo.nil?
        @git_repo = Chef::Resource::Git.new(new_resource.repo, run_context)
        @git_repo.user new_resource.owner
        @git_repo.group new_resource.group
        @git_repo.ssh_wrapper @ssh_wrapper.name unless new_resource.depoy_key.nil?
        @git_repo.revision unless new_resource.revision.nil?
        @git_repo.path new_resource.path
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
            Mixlib::ShellOut.new("/usr/sbin/a2ensite #{new_resource.name}.conf").run_command
            Chef::Log.debug("Enabling Apache site #{new_resource.name}")
          end
          return true
        else
          return false
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
            enable_script = "#{run_context.node.nginx.script_dir}/nxensite #{new_resource.name}"
            Chef::Log.debug("Enabling Nginx site #{new_resource.name}")
            Chef::Mixin::ShellOut.new(enable_script).run_command
          end
          return true
        else
          return false
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