#!/bin/sh

# stackjump default first_run.sh
# DO NOT MODIFY THIS FILE
# any custom commands should be added as a script in 'custom_scripts' directory

source /root/extras/stackjump.config

export HOME="/root"
export FQDN=`hostname -f`
update-grub
dpkg -i /root/extras/*.deb # install chef-client|server
if [ ! -d /etc/chef-server ]; then
  mkdir -p /etc/chef-server
fi
cat<<EOF > /etc/chef-server/chef-server.rb
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
echo "environment 'production'" >> /etc/chef/client.rb
knife cookbook upload -o /root/extras/chef-repo/cookbooks --all
knife role from file /root/extras/chef-repo/roles/*.json
knife environment from file /root/extras/chef-repo/environments/*.json
knife node run_list add $FQDN "recipe[chef-client]"
sleep 2
chef-client
echo -e "\nCHEF & KNIFE INSTALLED AND CONFIGURED\n"

# VM manipulation to allow internet because bond1.2002 uses lacp
# bring up a 5th network interface in the vm and use it for internet
if [ $IS_VM == true ] ;then
  ISVM_SCRIPT="/root/extras/is_vm.sh"
  cat <<EOF > $ISVM_SCRIPT
#!/bin/bash
intf="/etc/network/interfaces"
bondintf="/etc/network/interfaces.d/bond1.2002"
if [ -f $bondintf ]; then
  sed -i 's,gateway.*,,g' $intf
fi
grep eth4 $intf > /dev/null 2>&1
if [ $? != 0 ]; then
  cat <<EOH >> $intf
auto eth4
iface eth4 inet dhcp
EOH
fi
ifdown eth4 --force
ifup eth4
chef-client
EOF
  chmod 755 $ISVM_SCRIPT
  sed -i "s,sh /root/first_run.sh,bash $ISVM_SCRIPT," /etc/rc.local
else
  sed -i 's,sh /root/first_run.sh,chef-client,' /etc/rc.local
fi

# *** CUSTOM SCRIPTS EXECUTE ***
CUSTOM_SCRIPTD="/root/extras/custom_scripts"
for SCRIPT in $CUSTOM_SCRIPTD/*; do
  chmod 755 $SCRIPT
  $SCRIPT
done
# *** END ***
