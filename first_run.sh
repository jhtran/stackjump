#!/bin/sh

# stackjump default first_run.sh
# DO NOT MODIFY THIS FILE
# any custom commands should be added as a script in 'custom_scripts' directory

export HOME="/root"
export FQDN=`hostname -f`
update-grub
dpkg -i /root/extras/*.deb # install chef-client|server
if [ ! -d /etc/chef/chef-server ]; then
  mkdir -p /etc/chef/chef-server
fi
cat<<EOF > /etc/chef/chef-server/chef-server.rb
server_name = "192.168.112.11"
api_fqdn server_name
nginx['url'] = "https://#{server_name}"
nginx['server_name'] = server_name
nginx['enable_non_ssl'] = true
nginx['non_ssl_port'] = 4000
lb['fqdn'] = server_name
bookshelf['vip'] = server_name
EOF
/usr/bin/chef-server-ctl reconfigure > /root/reconfigure.out 2>&1
echo "Waiting 10 seconds before configuring knife..."
sleep 10
SECRETF="/etc/chef/encrypted_data_bag_secret"
if [ ! -f $SECRETF ]; then
  openssl rand -base64 512 |tr -d '\r\n' > /etc/chef/encrypted_data_bag_secret
  chmod 600 /etc/chef/encrypted_data_bag_secret
fi
chmod 755 /root/knife_first_run
if [ -d /root/.chef ]; then
  rm -rf /root/.chef
fi
/root/knife_first_run
knife configure client /etc/chef && chef-client
knife cookbook upload -o /root/extras/chef-repo/cookbooks --all
knife role from file /root/extras/chef-repo/roles/*.json
knife environment from file /root/extras/chef-repo/environments/*.json
knife node run_list add $FQDN "recipe[chef-client]"
sleep 2
chef-client
echo -e "\nCHEF & KNIFE INSTALLED AND CONFIGURED\n"
sed -i 's,sh /root/first_run.sh,exit 0,' /etc/rc.local
# *** CUSTOM SCRIPTS EXECUTE ***
CUSTOM_SCRIPTD="/root/extras/custom_scripts"
for SCRIPT in $CUSTOM_SCRIPTD/*; do
  chmod 755 $SCRIPT
  $SCRIPT
done
# *** END ***
reboot
