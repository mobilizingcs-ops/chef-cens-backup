#
# Cookbook Name:: cens-backup
# Recipe:: offsite_lausd
#
include_recipe 'cens-backup::default'

backup_model :offsite_lausd do
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
  command "/opt/chef/embedded/bin/backup perform --trigger offsite_lausd --config-file /usr/local/etc/backup/config.rb --log-path=/var/log >> /dev/null"
end