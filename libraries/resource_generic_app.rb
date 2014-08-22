require 'chef/resource'

class Chef
  class Resource
    class GenericApp < Chef::Resource
      def initialize(name, run_context=nil)
        super
        @resource_name = :generic_app
        @provider = Chef::Provider::GenericApp
        @action = :deploy
        @allowed_actions = [:deploy, :remove]
      end

      def deploy_key(arg=nil)
        set_or_return(:deploy_key,
                      arg,
                      kind_of: String,
                      default: nil)
      end

      def site_names(arg=nil)
        set_or_return(:site_names,
                      arg,
                      kind_of: Array,
                      default: [])
      end

      def path(arg=nil)
        set_or_return(:path,
                      arg,
                      kind_of: String,
                      required: true)
      end

      def repository(arg=nil)
        set_or_return(:repository,
                      arg,
                      kind_of: String,
                      required: true)
      end

      def revision(arg=nil)
        set_or_return(:revision,
                      arg,
                      kind_of: String,
                      default: 'master')
      end

      def owner(arg=nil)
        set_or_return(:owner,
                      arg,
                      kind_of: String,
                      required: true)
      end

      def group(arg=nil)
        set_or_return(:group,
                      arg,
                      kind_of: String,
                      required: true)
      end

      def web_server(arg=nil)
        set_or_return(:web_server,
                      arg,
                      kind_of: String,
                      equal_to: %w(nginx apache),
                      default: 'apache')
      end

      def web_template(arg=nil)
        set_or_return(:web_template,
                      arg,
                      kind_of: String,
                      default: nil)
      end

      def web_params(arg=nil)
        set_or_return(:web_params,
                      arg,
                      kind_of: Hash,
                      default: {})
      end

      def after_checkout(arg=nil, &block)
        arg ||= block
        set_or_return(:after_checkout,
                      arg,
                      kind_of: Proc)
      end
    end
  end
end
