#
# Cookbook Name:: cens-backup
# Recipe:: ldap
#
include_recipe 'cens-backup::default'

# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
slack = ChefVault::Item.load('slack', 'backup-gem')
webhook_url = slack['webhook']

backup_model :ldap do
  description 'Back up openldap db'

  definition <<-DEF

    database OpenLDAP do |db|
    end

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 30
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
