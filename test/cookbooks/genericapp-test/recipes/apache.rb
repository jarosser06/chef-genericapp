include_recipe 'genericapp-test'
include_recipe 'apache2'

generic_app 'magic.com' do
  repository 'https://github.com/TAMUArch/magic.git'
  owner node['apache']['user']
  group node['apache']['group']
  path '/var/www/magic'
end