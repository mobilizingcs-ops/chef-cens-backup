#
# Cookbook Name:: cens-backup
# Recipe:: ldap
#
include_recipe 'cens-backup::default'

backup_model :ldap do
  description 'Back up openldap db'

  definition <<-DEF

    database OpenLDAP do |db|
    end

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 1
    end

    notify_by Slack
  DEF

  schedule(
    minute: 0,
    hour: 0
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end
