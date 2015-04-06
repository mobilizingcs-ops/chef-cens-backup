#
# Cookbook Name:: cens-backup
# Recipe:: rstudio
#
include_recipe 'cens-backup::default'

node.set['backup']['addl_flags']   = '--tmp-path=/mnt/backups/tmp'

backup_model :rstudio do
  description 'Back up config files and home dir'

  definition <<-DEF

    archive :libraries do |archive|
      archive.add '/usr/local/lib/R/site-library/'
    end

    archive :config_dir do |archive|
      archive.add '/etc/rstudio/'
    end

    compress_with Gzip

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 1
    end
  DEF

  schedule(
    minute: 0,
    hour: 2
  )
  cron_options(
    path: '/opt/chef/embedded/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
  )
end
