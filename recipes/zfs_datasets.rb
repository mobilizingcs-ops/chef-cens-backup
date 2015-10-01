#
# Cookbook Name:: cens-backup
# Recipe:: zfs_datasets
#
include_recipe 'cens-backup::default'
include_recipe 'cron::default' # https://github.com/chef-cookbooks/cron/commit/5ec9b142ea2f19ade0f94d10284096af1f0e4fc7

node.set['backup']['addl_flags'] = '--tmp-path=/tank/tmp'
# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
fqdn = node['fqdn']
aws_creds = ChefVault::Item.load('aws', 'backup')

backup_model :dataset_rstudiohome do
  description 'Back up rstudiohome'

  definition <<-DEF

    archive :data_dirs do |archive|
      archive.add '/export/rstudio-home'
    end

    store_with S3 do |s3|
      s3.access_key_id = '#{aws_creds["key"]}'
      s3.secret_access_key = '#{aws_creds["secret"]}'
      s3.bucket = 'mobilize-ohmage-backup'
      s3.path = '#{node["fqdn"]}'
      s3.chunk_size = 50
      s3.keep = 1
    end
    
    notify_by Slack do |slack|
      slack.on_warning = false
    end
  DEF

  schedule(
    minute: 0,
    hour: 2,
    weekday: 0
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end

backup_model :dataset_owncloud do
  description 'Back up owncloud'

  definition <<-DEF

    archive :data_dirs do |archive|
      archive.add '/export/owncloud'
    end

    compress_with Gzip

    store_with S3 do |s3|
      s3.access_key_id = '#{aws_creds["key"]}'
      s3.secret_access_key = '#{aws_creds["secret"]}'
      s3.bucket = 'mobilize-ohmage-backup'
      s3.path = '#{node["fqdn"]}'
      s3.chunk_size = 50
      s3.keep = 1
    end
    
    notify_by Slack do |slack|
      slack.on_warning = false
    end
  DEF

  schedule(
    minute: 0,
    hour: 3,
    weekday: 0
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end