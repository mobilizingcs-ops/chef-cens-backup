# apply to the dup storage node to allow it to share content via NFS
#
# Cookbook Name:: cens-backup
# Recipe:: server
#
include_recipe 'sanoid'

# for cleanliness, scrub daily :)
cron "scrub" do
  minute '0'
  hour '21'
  command "zpool scrub tank"
end

service 'mountd' do
  action :nothing
  supports reload: true
  reload_command 'service mountd onereload'
end

# i want to manage zfs mounts on freebsd zfs server. first i'll manage the ones I have

zfs 'tank/home' do
  compression 'on'
  mountpoint '/export/home'
end

zfs 'tank/rstudio-home' do
  compression 'on'
  mountpoint '/export/rstudio-home'
end

#zfs 'tank/vm' do
#  compression 'on'
#  mountpoint '/export/vm'
#end

zfs 'tank/backups' do
  compression 'on'
  mountpoint '/export/backups'
  quota '2T'
end

zfs 'tank/apps' do
  compression 'on'
  mountpoint '/export/apps'
  quota '50G'
end

zfs 'tank/owncloud' do
  compression 'on'
  mountpoint '/export/owncloud'
  quota '100G'
end

# now the real fun begins.  Let's search on our linux hosts, and loop through making a backup dir for each host
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
else
  hosts = search(:node, 'os:linux AND role:guest')
  hosts.sort! { |x, y| x[:fqdn] <=> y[:fqdn] }
  hosts.each do |cur_host|
    zfs "tank/backups/#{cur_host['fqdn']}" do
      mountpoint "/export/backups/#{cur_host['fqdn']}"
    end
  end

  template '/etc/zfs/exports' do
    source 'zfs_exports_dup.erb'
    owner 'root'
    group 'wheel'
    mode 0600
    notifies :reload, 'service[mountd]'
    variables(
      linux_hosts: hosts
    )
  end
end
