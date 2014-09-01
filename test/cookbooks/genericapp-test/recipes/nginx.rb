node.default['nginx']['default_site_enabled'] = false
include_recipe 'nginx'

generic_app 'magic.com' do
  repository 'https://github.com/TAMUArch/magic.git'
  owner node['nginx']['user']
  group node['nginx']['group']
  web_server 'nginx'
  path '/var/www/magic'
  after_checkout do
    file '/var/www/magic/test.txt' do
      action :create
      content 'testing the callback'
    end
  end
end
