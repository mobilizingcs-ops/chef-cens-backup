#
# Cookbook Name:: cens-backup
# Recipe:: rt4
#
# assumes rt4 installed from debian packages
include_recipe 'cens-backup::default'

# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
fqdn = node['fqdn']
aws_creds = ChefVault::Item.load('aws', 'backup')

backup_model :rt4 do
  description 'Back up database, config files, and source for rt4'

  definition <<-DEF

    database MySQL do |db|
      db.name = 'rt4mobilize'
      db.username = 'root'
      db.password = '#{node['mysql']['server_root_password']}'
      db.host = 'localhost'
      db.port = '3306'
      db.additional_options = ["--quick", "--single-transaction"]
    end

    archive :config_dir do |archive|
      archive.add '/etc/request-tracker4/'
    end

    archive :fetchmail do |archive|
      archive.add '/root/bin/fetchmail_multi.sh'
    end

    archive :source_and_customizations_dir do |archive|
      archive.add '/usr/share/request-tracker4'
    end

    compress_with Gzip

    encrypt_with OpenSSL do |encryption|
      encryption.password = '#{aws_creds["encryption_key"]}'
      encryption.base64   = false
      encryption.salt     = true
    end

    store_with S3 do |s3|
      s3.access_key_id = '#{aws_creds["key"]}'
      s3.secret_access_key = '#{aws_creds["secret"]}'
      s3.bucket = 'mobilize-ohmage-backup'
      s3.path = '#{node["fqdn"]}'
      s3.chunk_size = 50
      s3.keep = 1
    end

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
