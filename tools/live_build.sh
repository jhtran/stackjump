#!/bin/sh

# using ubuntu-builder, these are the steps you'll need to configure

apt-get update
apt-get install python-software-properties ethtool ifenslave vlan curl aptitude openssh-server -y
add-apt-repository ppa:jared-dominguez/wsmancli
apt-get update
apt-get install wsmancli -y
curl -u mygitusername -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/stackjump/contents/tools/live_cd_netconfig" -o /etc/init.d/live_cd_netconfig

curl -u mygitusername -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/substructure/contents/substructure/management/dell/configure_system.bash" -o /root/dell_configure_system.bash
curl -u mygitusername -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/substructure/contents/substructure/management/dell/Create-Virtual-Disk-0.xml" -o /root/Create-Virtual-Disk-0.xml

curl -u mygitusername -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/substructure/contents/substructure/management/dell/Create-Virtual-Disk-1.xml" -o /root/Create-Virtual-Disk-1.xml

chmod 755 /etc/init.d/live_cd_netconfig
sed -i 's/exit 0/\/etc\/init.d\/live_cd_netconfig start/' /etc/rc.local
