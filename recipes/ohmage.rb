#
# Cookbook Name:: cens-backup
# Recipe:: ohmage
#
include_recipe "cens-backup::default"

backup_model :ohmage do
  description "Back up ohmage database and data dirs"

  definition <<-DEF

    database MySQL do |db|
      db.name = 'ohmage'
      db.username = 'ohmage'
      db.password = node['ohmage']['db']['password']
      db.host = 'localhost'
      db.port = '3306'
      db.additional_options = ["--quick", "--single-transaction"]
    end

    archive :data_dirs do |archive|
      archive.add '/var/lib/ohmage/'
    end

    compress_with Gzip

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 1
    end
  DEF

  schedule({
    :minute => 0,
    :hour   => 1
  })
end