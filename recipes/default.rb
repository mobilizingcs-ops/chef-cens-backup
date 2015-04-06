#
# Cookbook Name:: cens-backup
# Recipe:: default
#

# having some weird trouble with nokogiri, so i'm going to install some extra packages so we can build it
%w(libxslt-dev libxml2-dev liblzma-dev zlib1g-dev).each do |pkg|
  package pkg
end

# require chef-vault
chef_gem 'chef-vault'
require 'chef-vault'
slack = ChefVault::Item.load('slack', 'backup-gem')
webhook_url = slack['webhook']

node.set['backup']['version'] = '4.1.7'
include_recipe 'build-essential'
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

directory '/mnt/backups' do
  owner 'root'
  group 'root'
  mode '0750'
  action :create
end

mount '/mnt/backups' do
  device "starbuck.ohmage.org:/export/backups/#{node['fqdn']}"
  fstype 'nfs'
  options '_netdev,defaults,acl'
  action [:mount, :enable]
end
