#!/bin/sh

# using ubuntu-builder console, these are the steps you'll need to configure

GITHUB_USERNAME="jhtran"

BUSORDER="06:00.0 06:00.1 03:00.0 03:00.1"
MGMT_IP="192.168.112.12"
MGMT_NETMASK="255.255.255.128"
MGMT_GW="192.168.112.1"
IPMI_CIDR="172.16.0.0/16"
DNS_IP="8.8.8.8"

PUBLIC_IP="75.55.108.12"
PUBLIC_NETMASK="255.255.254.0"
PUBLIC_GW="75.55.108.1"


apt-get update
apt-get install git ethtool ifenslave vlan curl aptitude openssh-server ipmitool -y

add-apt-repository ppa:jared-dominguez/wsmancli
apt-get update
apt-get install wsmancli -y

curl -u $GITHUB_USERNAME -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/substructure/contents/substructure/management/dell/configure_system.bash" -o /root/dell_configure_system.bash
curl -u $GITHUB_USERNAME -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/substructure/contents/substructure/management/dell/Create-Virtual-Disk-0.xml" -o /root/Create-Virtual-Disk-0.xml

curl -u $GITHUB_USERNAME -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/att-cloud/substructure/contents/substructure/management/dell/Create-Virtual-Disk-1.xml" -o /root/Create-Virtual-Disk-1.xml

cat<<EOF>/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
  bond-master bond0

auto eth1
iface eth1 inet manual
  bond-master bond0
  pre-up sleep 10

auto eth2
iface eth2 inet manual
  bond-master bond1

auto eth3
iface eth3 inet manual
  bond-master bond1
  pre-up sleep 10

auto bond1
iface bond1 inet manual
  bond-mode 802.3ad
  bond-slaves none
  bond-miimon 100
  bond-downdelay 200
  bond-updelay 200
  bond-xmit-hash-policy 1
  bond-ad-select 1
  bond-lacp-rate 1

source /etc/network/interfaces.d/*
EOF

UDEVF="/etc/udev/rules.d/70-persistent-net-rules.conf"
PREFX='ACTION=="add", SUBSYSTEM=="net", SUBSYSTEMS=="pci", KERNELS=="'
ETHCOUNT=0

echo "" > $UDEVF
for i in $BUSORDER; do
  echo "${PREFX}0000:$i\", NAME=\"eth${ETHCOUNT}\"" >> $UDEVF
  ETHCOUNT=`expr $ETHCOUNT + 1`
done

mkdir /etc/network/interfaces.d
cat<<EOF>>/etc/network/interfaces.d/bond0
auto bond0
iface bond0 inet static
  address ${MGMT_IP}
  netmask ${MGMT_NETMASK}
  dns-nameservers ${DNS_IP}
  post-up route add -net ${IPMI_CIDR} gw ${MGMT_GW}
  bond-mode 1
  bond-slaves none
EOF

cat<<EOF>>/etc/network/interfaces.d/bond1.2002
auto bond1.2002
iface bond1.2002 inet static
  address ${PUBLIC_IP}
  netmask ${PUBLIC_NETMASK}
  gateway ${PUBLIC_GW}
  vlan-raw-device bond1
EOF

sed -i '21i\exit 0' /usr/share/initramfs-tools/scripts/casper-bottom/23networking
update-initramfs -u -k all

if [ ! -d /home/ubuntu/.ssh ]; then
  mkdir -p /home/ubuntu/.ssh
fi

echo "********************"
echo "* INSTALL COMPLETE *"
echo "********************"
echo "Don't forget to install ssh public keys in /root/.ssh/authorized_keys and or /home/ubuntu/.ssh/authorized_keys"
