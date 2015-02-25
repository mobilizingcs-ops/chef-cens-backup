#
# Cookbook Name:: cens-backup
# Recipe:: default
#

#having some weird trouble with nokogiri, so i'm going to install some extra packages so we can build it
%w(libxslt-dev libxml2-dev liblzma-dev zlib1g-dev).each do |pkg|
  package pkg
end

node.set['backup']['version'] = "4.1.7"
include_recipe "build-essential"
include_recipe "backup"

directory "/mnt/backups" do
  owner 'root'
  group 'root'
  mode '0750'
  action :create
end

mount "/mnt/backups" do
  device "starbuck.ohmage.org:/export/backups/#{node['fqdn']}"
  fstype "nfs"
  options "_netdev,defaults,acl"
  action [:mount, :enable]
end