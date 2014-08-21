include_recipe 'genericapp-test'
include_recipe 'nginx'

generic_app 'magic.com' do
  repository 'https://github.com/TAMUArch/magic.git'
  owner node['apache']['user']
  group node['apache']['group']
  web_server 'nginx'
  path '/var/www/magic'
end
