#
# Cookbook Name:: cens-backup
# Recipe:: default
#

case node[:platform]
when 'freebsd'
  node.set['backup']['config_path'] = '/usr/local/etc/backup'
  node.set['backup']['model_path']   = "#{node['backup']['config_path']}/models"
  node.set['backup']['group'] = 'wheel'

  # prep with build-essential type stuff, but on freebsd
  # in particular, gcc is no longer included as of freebsd 10
  package 'gcc48'
  link '/usr/local/bin/gcc48' do
    to '/usr/local/bin/gcc'
  end
  link '/usr/local/bin/g++48' do
    to '/usr/local/bin/g++'
  end
  package 'rsync' # since we plan to use rsync to ship
else
  %w(libxslt-dev libxml2-dev liblzma-dev zlib1g-dev).each do |pkg|
    package pkg
  end
  include_recipe 'build-essential'
  directory '/mnt/backups' do
    owner 'root'
    group 'root'
    mode '0750'
    action :create
  end
  
  mount '/mnt/backups' do
    #device "starbuck.ohmage.org:/export/backups/#{node['fqdn']}"
    device "cavil.ohmage.org:/export/backups/#{node['fqdn']}"
    fstype 'nfs'
    options '_netdev,defaults,acl'
    action [:mount, :enable]
  end
end


# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
slack = ChefVault::Item.load('slack', 'backup-gem')
webhook_url = slack['webhook']

node.set['backup']['version'] = '4.1.7'
include_recipe 'backup'
begin
  # Replace global config file from backup cookbook with our own.
  r = resources(:template => "Backup config file")
  r.cookbook "cens-backup"
  r.variables(
      webhook_url: webhook_url
  	)
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "could not find template to override!"
end
