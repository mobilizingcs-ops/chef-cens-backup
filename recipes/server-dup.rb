#
# Cookbook Name:: cens-backup
# Recipe:: server-dup
#

include_recipe 'sanoid'

# for cleanliness, scrub daily :)
cron "scrub" do
  minute '0'
  hour '21'
  command "zpool scrub tank"
end

# mimic tank/home, tank/owncloud and tank/backups from starbuck. we'll use syncoid to get them here.
zfs 'tank/home' do
  compression 'on'
end

zfs 'tank/rstudio-home' do
  compression 'on'
end

zfs 'tank/owncloud' do
  compression 'on'
end

zfs 'tank/backups' do
  compression 'on'
end

# now the real fun begins.  Let's search on our linux hosts, and loop through making a backup dir for each host
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
else
  hosts = search(:node, 'os:linux AND role:guest')
  hosts.sort! { |x, y| x[:fqdn] <=> y[:fqdn] }

  hosts.each do |cur_host|
    zfs "tank/backups/#{cur_host['fqdn']}" do
    end
  end
end
