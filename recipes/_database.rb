
mysql2_chef_gem 'default' do
  action :install
end

python_pip "MySQL-python"

%w(libldap2-dev libsasl2-dev libssl-dev).each {|p| package p}

python_pip "python-ldap"

db_connection = {host: node['mo_graphite']['db']['host'], 
                 username: node['mo_graphite']['db']['superuser'], 
                 password: node['mo_graphite']['db']['superuser_password'] || node['mysql']['server_root_password']
                }

mysql_database node['mo_graphite']['db']['name'] do
  connection db_connection
end

["127.0.0.1", node.ipaddress].each do |ip|
  mysql_database_user "#{ip}_#{node['mo_graphite']['db']['username']}" do
    connection db_connection
    username node['mo_graphite']['db']['username']
    database_name node['mo_graphite']['db']['name']
    password node['mo_graphite']['db']['password']
    host  ip
    action [:create, :grant]
  end
end

