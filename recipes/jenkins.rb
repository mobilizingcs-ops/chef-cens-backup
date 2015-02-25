#
# Cookbook Name:: cens-backup
# Recipe:: jenkins
#
include_recipe "cens-backup::default"

backup_model :jenkins do
  description "Back up jenkins config"

  definition <<-DEF

    archive :jenkins_dirs do |archive|
      archive.add '/var/lib/jenkins/'
    end

    compress_with Gzip

    store_with Local do |local|
      local.path = '/mnt/backups/'
      local.keep = 30
  DEF

  schedule({
    :minute => 0,
    :hour   => 1
  })
end