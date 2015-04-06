#
# Cookbook Name:: cens-backup
# Recipe:: generic_webserver
#
include_recipe 'cens-backup::default'

backup_model :generic_webserver do
  description 'Back up database, web dirs and nginx config files'

  definition <<-DEF

    database MySQL do |db|
      db.name = :all
      db.username = 'root'
      db.password = '#{node['mysql']['server_root_password']}'
      db.host = 'localhost'
      db.port = '3306'
      db.additional_options = ["--quick", "--single-transaction", "--events"]
    end

    archive :web_dir do |archive|
      archive.add '/var/www/'
    end

    archive :config_dir do |archive|
      archive.add '/etc/nginx/'
    end

    compress_with Gzip

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 1
    end
  DEF

  schedule(
    minute: 0,
    hour: 0
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end
