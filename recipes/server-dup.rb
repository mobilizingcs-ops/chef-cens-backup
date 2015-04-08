#
# Cookbook Name:: cens-backup
# Recipe:: server-dup
#

include_recipe 'sanoid'

# for cleanliness, scrub daily :)
cron "scrub" do
  minute '0'
  hour '21'
  command "zpool scrub tank"
end

# mimic tank/home, tank/owncloud and tank/backups from starbuck. we'll use syncoid to get them here.
zfs 'tank/home' do
  compression 'on'
end

zfs 'tank/rstudio-home' do
  compression 'on'
end

zfs 'tank/owncloud' do
  compression 'on'
end

zfs 'tank/backups' do
  compression 'on'
end

# now the real fun begins.  Let's search on our linux hosts, and loop through making a backup dir for each host
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
else
  hosts = search(:node, 'os:linux AND role:guest')
  hosts.sort! { |x, y| x[:fqdn] <=> y[:fqdn] }

  hosts.each do |cur_host|
    zfs "tank/backups/#{cur_host['fqdn']}" do
    end
  end
end

# offsite backups
# prep with build-essential type stuff, but on freebsd
# in particular, gcc is no longer included as of freebsd 10
package 'gcc48'
link '/usr/local/bin/gcc48' do
  to '/usr/local/bin/gcc'
end
link '/usr/local/bin/g++48' do
  to '/usr/local/bin/g++'
end
package 'rsync' # since we plan to use rsync to ship

node.set['backup']['config_path'] = '/usr/local/etc/backup'
node.set['backup']['model_path']   = "#{node['backup']['config_path']}/models"
node.set['backup']['group'] = 'wheel'
node.set['backup']['version'] = '4.1.7'
include_recipe 'backup'

backup_model :lausd do
  description 'Back up lausd data offsite'

  definition <<-DEF

    sync_with RSync::Push do |rsync|

      rsync.mode = :ssh
      rsync.host = "util.technolengy.com"
      rsync.port = 22
      rsync.ssh_user = "cens"
      rsync.mirror = true
      rsync.compress = true

      rsync.directories do |directory|
        directory.add "/tank/backups/lausd.mobilizingcs.org"
      end

      rsync.path = "~/backup"
    end

    notify_by Slack

  DEF
end

cron "offsite_lausd" do
  minute '0'
  hour '5'
  command "/opt/chef/embedded/bin/backup perform --trigger lausd --config-file /usr/local/etc/backup/config.rb --log-path=/var/log >> /dev/null"
end


