#
# Cookbook Name:: cens-backup
# Recipe:: server-dup
#

include_recipe "sanoid"

#mimic tank/home and tank/backups from starbuck. we'll use syncoid to get them here.

zfs "tank/home" do
  compression "on"
end

zfs "tank/backups" do
  compression "on"
end

#now the real fun begins.  Let's search on our linux hosts, and loop through making a backup dir for each host

hosts = search(:node, 'os:linux AND role:guest')
hosts.sort!{|x, y| x[:fqdn] <=> y[:fqdn]}

#remove hosts we know don't need data backups
%w(analysis02.ohmage.org anvil.ohmage.org dev.opencpu.org dev1.opencpu.org dev2.opencpu.org ocpu.ohmage.org).each do |no_backup|
 hosts.delete(no_backup)
end
hosts.each do |cur_host|
  zfs "tank/backups/#{cur_host['fqdn']}" do
  end
end