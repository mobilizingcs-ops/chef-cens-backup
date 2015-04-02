#
# Cookbook Name:: cens-backup
# Recipe:: ohmage
#
include_recipe 'cens-backup::default'

# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
ohmage_db_password = ChefVault::Item.load('passwords', 'ohmage_db')
fqdn = node['fqdn']

backup_model :ohmage do
  description 'Back up ohmage database and data dirs'

  definition <<-DEF

    database MySQL do |db|
      db.name = 'ohmage'
      db.username = 'ohmage'
      db.password = '#{ohmage_db_password[fqdn]}'
      db.host = 'localhost'
      db.port = '3306'
      db.additional_options = ['--quick', '--single-transaction']
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

  schedule(
    minute: 0,
    hour: 1
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end
