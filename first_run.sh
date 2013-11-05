#!/bin/sh
export HOME="/root"
export FQDN=`hostname -f`
update-grub
dpkg -i /root/extras/*.deb # install chef-client|server
/usr/bin/chef-server-ctl reconfigure > /root/reconfigure.out 2>&1
echo "Waiting 60 seconds before configuring knife..."
sleep 60
chmod 755 /root/knife_first_run
if [ -d /root/.chef ]; then
  rm -rf /root/.chef
fi
/root/knife_first_run
knife configure client /etc/chef && chef-client
knife cookbook upload -o /root/extras/chef-repo/cookbooks --all
knife node run_list add $FQDN "recipe[chef-client]"
sleep 2
chef-client
sed -i 's,sh /root/first_run.sh,exit 0,' /etc/rc.local
reboot
# stackjump default first_run.sh
