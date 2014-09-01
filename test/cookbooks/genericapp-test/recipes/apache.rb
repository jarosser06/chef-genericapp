include_recipe 'apache2'

generic_app 'magic.com' do
  repository 'https://github.com/TAMUArch/magic.git'
  owner node['apache']['user']
  group node['apache']['group']
  site_names %w(www.magic.com dev.magic.com)
  path '/var/www/magic'
  after_checkout do
    file '/var/www/magic/test.txt' do
      action :create
      content 'testing the callback'
    end
  end
end
