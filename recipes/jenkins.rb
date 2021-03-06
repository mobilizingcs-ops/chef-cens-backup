#
# Cookbook Name:: cens-backup
# Recipe:: jenkins
#
include_recipe 'cens-backup::default'

node.set['backup']['addl_flags'] = '--tmp-path=/mnt/backups/tmp'

backup_model :jenkins do
  description 'Back up jenkins config'

  definition <<-DEF

    archive :jenkins_dirs do |archive|
      archive.add '/var/lib/jenkins/'
    end

    compress_with Gzip

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 1
    end

    notify_by Slack
  DEF

  schedule(
    minute: 0,
    hour: 1
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end
