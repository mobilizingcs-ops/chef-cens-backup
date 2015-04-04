#
# Cookbook Name:: cens-backup
# Recipe:: generic_webserver
#
include_recipe 'cens-backup::default'
# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
slack = ChefVault::Item.load('slack', 'backup-gem')
webhook_url = slack['webhook']

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

    notify_by Slack do |slack|
      slack.on_success = false
      slack.on_warning = true
      slack.on_failure = true
      slack.webhook_url = '#{webhook_url}'
      slack.channel = '#cens'
      slack.username = 'backup-gem'
      slack.icon_emoji = ':whale:'
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
