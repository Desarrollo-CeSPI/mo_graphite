include_recipe "nginx"

template "/etc/nginx/sites-enabled/graphite" do
  source "graphite-nginx.erb"
  variables(port: node['mo_graphite']['port'])
  notifies :restart, "service[nginx]"
end

nginx_site "graphite"

