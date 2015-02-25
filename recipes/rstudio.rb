#
# Cookbook Name:: cens-backup
# Recipe:: rstudio
#
include_recipe "cens-backup::default"

backup_model :rstudio do
  description "Back up config files and home dir"

  definition <<-DEF

    archive :home_dir do |archive|
      archive.add '/home/'
    end

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

  schedule({
    :minute => 0,
    :hour   => 2
  })
end


