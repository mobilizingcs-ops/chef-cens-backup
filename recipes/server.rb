#
# Cookbook Name:: cens-backup
# Recipe:: server
#
service "mountd" do
  action :nothing
  supports :reload => true
  reload_command "service mountd onereload"
end

#i want to manage zfs mounts on freebsd zfs server. first i'll manage the ones I have

zfs "tank/home" do
  compression "on"
  mountpoint "/export/home"
end

zfs "tank/archive" do
  compression "on"
end

zfs "tank/vm" do
  compression "on"
  mountpoint "/export/vm"
end

zfs "tank/backups" do
  compression "on"
  mountpoint "/export/backups"
  quota "2TB"
end  

#now the real fun begins.  Let's search on our linux hosts, and loop through making a backup dir for each host

hosts = search(:node, 'os:linux AND role:guest')
hosts.each do |cur_host|
  zfs "tank/backups/#{cur_host['fqdn']}" do
    mountpoint "/export/backups/#{cur_host['fqdn']}"
  end
end

template "/etc/zfs/exports" do
	source "zfs_exports.erb"
	owner "root"
	group "wheel"
	mode 0600
	notifies :reload, "service[mountd]"
    variables(
    	:linux_hosts => hosts
    )
end