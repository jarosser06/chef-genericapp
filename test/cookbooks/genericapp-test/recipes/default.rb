package 'git'

directory '/var/www' do
  action :create
  owner node['apache']['user']
  group node['apache']['group']
end
