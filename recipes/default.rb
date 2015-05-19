include_recipe "runit"
include_recipe "graphite::carbon"
include_recipe "graphite::_web_packages"
include_recipe "mo_graphite::_database"
include_recipe "mo_graphite::_nginx"


node.set['graphite']["uwsgi"]['listen_http']  = true
node.set["graphite"]["uwsgi"]["port"] = node['mo_graphite']['port']

storage_dir = node['graphite']['storage_dir']

graphite_carbon_cache "default" do
  config ({
            enable_logrotation: true,
            user: node['graphite']['user'],
            max_cache_size: "inf",
            max_updates_per_second: 500,
            max_creates_per_minute: 50,
            line_receiver_interface: "0.0.0.0",
            line_receiver_port: node['mo_graphite']['carbon']['port'],
            udp_receiver_port: node['mo_graphite']['carbon']['port'],
            pickle_receiver_port: 2004,
            enable_udp_listener: true,
            cache_query_port: "7002",
            cache_write_strategy: "sorted",
            use_flow_control: true,
            log_updates: false,
            log_cache_hits: false,
            whisper_autoflush: false,
            local_data_dir: "#{storage_dir}/whisper/"
          })
end

node['mo_graphite']['storage_schemas'].each do |name, definition|
  graphite_storage_schema name do
    config definition
  end
end

graphite_service "cache"

base_dir = "#{node['graphite']['base_dir']}"

graphite_web_config "#{base_dir}/webapp/graphite/local_settings.py" do
  config({
           secret_key: SecureRandom.hex(64),
           time_zone: node['mo_graphite']['timezone'],
           conf_dir: "#{base_dir}/conf",
           storage_dir: storage_dir,
           databases: {
             default: {
               NAME: node['mo_graphite']['db']['name'],
               ENGINE: 'django.db.backends.mysql',
               USER: node['mo_graphite']['db']['username'],
               PASSWORD: node['mo_graphite']['db']['password'],
               HOST: node['mo_graphite']['db']['host'],
               PORT: node['mo_graphite']['db']['port']
             }
           },
           use_ldap_auth: node['mo_graphite']['ldap']['enabled'],
           ldap_uri: node['mo_graphite']['ldap']['uri'],
           ldap_search_base: node['mo_graphite']['ldap']['search_base'],
           ##LDAP_BASE_USER = "CN=some_readonly_account,DC=mycompany,DC=com"
           ##LDAP_BASE_PASS = "readonly_account_password"
           ldap_user_query: node['mo_graphite']['ldap']['user_query'],
           dashboard_require_authentication: node['mo_graphite']['dahsboard_require_authentication']
         })
  notifies :restart, 'service[graphite-web]', :delayed
end
if node['mo_graphite']['ldap']['enabled']

end

directory "#{storage_dir}/log/webapp" do
  owner node['graphite']['user']
  group node['graphite']['group']
  recursive true
end

execute "python manage.py syncdb --noinput" do
  user node['graphite']['user']
  group node['graphite']['group']
  cwd "#{base_dir}/webapp/graphite"
  notifies :run, "python[set admin password]"
  only_if do
    Gem.clear_paths
    require 'mysql2'
    db = node['mo_graphite']['db'] || Hash.new
    client = ::Mysql2::Client.new(db.merge(database: db['name']))
    client.query("show tables").count == 0
  end
end

# creates an initial user, doesn't require the set_admin_password
# script. But srsly, how ugly is this? could be
# crazy and wrap this as a graphite_user resource with a few
# improvements...
python "set admin password" do
  action :nothing
  cwd "#{base_dir}/webapp/graphite"
  user node['graphite']['user']
  code <<-PYTHON
import os,sys
sys.path.append("#{base_dir}/webapp/graphite")
os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
from django.contrib.auth.models import User

username = "#{node['graphite']['user']}"
password = "#{node['graphite']['password']}"

try:
    u = User.objects.create_user(username, password=password)
    u.save()
except Exception,err:
    print "could not create %s" % username
    print "died with error: %s" % str(err)
  PYTHON
  not_if { node['mo_graphite']['ldap']['enabled'] }
end


runit_service 'graphite-web' do
  cookbook 'graphite'
  default_logger true
end

