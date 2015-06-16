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

sanoid_dataset 'tank/home' do
  use_template 'home'
end

sanoid_syncoid 'sync-home' do
  user 'root'
  server 'cavil.ohmage.org'
  dataset 'tank/home'
  target 'tank/home'
  cron '0 2 * * *'
end

zfs 'tank/rstudio-home' do
  compression 'on'
  mountpoint '/export/rstudio-home'
end

sanoid_dataset 'tank/rstudio-home' do
  use_template 'home'
end

sanoid_syncoid 'sync-rstudio-home' do
  user 'root'
  server 'cavil.ohmage.org'
  dataset 'tank/rstudio-home'
  target 'tank/rstudio-home'
  cron '0 2 * * *'
end

zfs 'tank/archive' do
  compression 'on'
end

zfs 'tank/vm' do
  compression 'on'
  mountpoint '/export/vm'
end

sanoid_dataset 'tank/vm' do
  use_template 'vm'
end

zfs 'tank/backups' do
  compression 'on'
  mountpoint '/export/backups'
  quota '2T'
end

sanoid_dataset 'tank/backups' do
  use_template 'backups'
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

sanoid_dataset 'tank/owncloud' do
  use_template 'home'
end

sanoid_syncoid 'sync-ownloud' do
  user 'root'
  server 'cavil.ohmage.org'
  dataset 'tank/owncloud'
  target 'tank/owncloud'
  cron '0 2 * * *'
end

# sanoid templates to use for snapshots
sanoid_template 'backups' do
  daily 7
  weekly 4
  monthly 12
  autosnap 'yes'
  autoprune 'yes'
end

sanoid_template 'home' do
  daily 7
  autosnap 'yes'
  autoprune 'yes'
end

sanoid_template 'vm' do
  daily 3
  autosnap 'yes'
  autoprune 'yes'
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

    sanoid_dataset "tank/backups/#{cur_host['fqdn']}" do
      use_template 'backups'
    end

    sanoid_syncoid "sync-#{cur_host['fqdn']}" do
      user 'root'
      server 'cavil.ohmage.org'
      dataset "tank/backups/#{cur_host['fqdn']}"
      target "tank/backups/#{cur_host['fqdn']}"
      cron '0 3 * * *'
    end
  end

  template '/etc/zfs/exports' do
    source 'zfs_exports.erb'
    owner 'root'
    group 'wheel'
    mode 0600
    notifies :reload, 'service[mountd]'
    variables(
      linux_hosts: hosts
    )
  end
end
