#
# Cookbook Name:: cens-backup
# Recipe:: alerts
#
include_recipe 'cens-backup::default'

backup_model :alerts do
  description 'Backs up data from services on alerts.ohmage.org: graphite whisper and grafana elasticsearch dashboards'

  definition <<-DEF

    archive :graphite_data do |archive|
      archive.add '/opt/graphite/storage/'
      archive.tar_options '--warning=no-file-changed --warning=no-file-removed'
    end

    archive :elasticsearch_data do |archive|
      archive.add '/usr/local/var/data/elasticsearch/'
      archive.tar_options '--warning=no-file-changed --warning=no-file-removed'
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
