default['mo_graphite']['port'] = 9090
default['mo_graphite']['carbon']['port'] = 2003
default['mo_graphite']['timezone'] = 'America/Argentina/Buenos_Aires'
default['mo_graphite']['db']['name'] = 'graphite'
default['mo_graphite']['db']['superuser'] = 'root'
default['mo_graphite']['db']['username'] = 'graphite'
default['mo_graphite']['db']['password'] = 'change_me'
default['mo_graphite']['db']['host'] = '127.0.0.1'
default['mo_graphite']['db']['port'] = '3306'
default['mo_graphite']['ldap']['enabled'] = false
default['mo_graphite']['ldap']['uri'] = "ldap://localhost"
default['mo_graphite']['ldap']['search_base'] = "dc=example,dc=com"
default['mo_graphite']['ldap']['user_query'] = "(username=%s)"
default['mo_graphite']['dahsboard_require_authentication'] = true
default['mo_graphite']['storage_schemas'] = {
  "carbon" => {
    pattern: "^carbon\.",
    retentions: "60:90d"
  },
  "collectd" => {
    pattern: "^collectd.*",
    retentions: "10s:1d,1m:7d,10m:1y"
  },
  "default_1min_for_1day" => {
    pattern: ".*",
    retentions: "60s:1d"
  },
}

default['nginx']['default_site_enabled'] = false
