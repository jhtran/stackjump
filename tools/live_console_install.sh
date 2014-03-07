#!/bin/sh

# using ubuntu-builder console, these are the steps you'll need to configure

GITHUB_USERNAME="mygituser"

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
apt-get install python-software-properties git ethtool ifenslave vlan curl aptitude openssh-server ipmitool -y

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

UDEVF="/etc/udev/rules.d/70-persistent-net.rules"
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

for i in /root /home/ubuntu; do
if [ ! -d $i/.ssh ]; then
  mkdir -p $i/.ssh
fi
done

echo 'ssh-dss AAAAB3NzaC1kc3MAAACBAOJba+6pCO6cKl3MvDctH1EQwKd+qpLtI3NhEzB3TZLDTDZ59mbThWWdeTAyFiutryysDozUeR50G0OSF0iXfCzQ++ntM/VNrUJDn72IsfEFXv24YAOVhBeM0Voq2hl34Sdcy/UdBxBWRDRbRPp/BaLrQa9ERq030TTLS4FNBG19AAAAFQCJLc5UDT0J+LayGBEhCg8gI1Gz9QAAAIAQL3q7smp3CkB6SpVHyRw4Y4GHCyiMu7qhfEz9lFhDa3OJIyPXgOV4dnIIokCze3YB97hg7cNp3tB4/istRhyoXeQ7/dr1wNCg/5pkOfq9eJJNAt0C6XiVAx7ydAKDG1HW3BU1vEoCaABzJR9S8Z5BOD9MKEPPdeuADpNXsYrbMQAAAIAoOnf+VQC2IHj5yGdMJ8jdeG3u9a8t1UTqTNfl8VwOA1sG6QLiS7HmY1SICLwLZu/7pkTOKK1wkaMPem8WoNabb1oe3ezK/VFgy5P8WifAeTWuESk7j7K65RvfUcb9yjSWf9sqZA439vJssQtC9pYUi/zlAkToC4IzvmtjXUzMxQ== jtran@ubuntu' >> /root/.ssh/authorized_keys

echo "********************"
echo "* INSTALL COMPLETE *"
echo "********************"
echo "Don't forget to install ssh public keys in /root/.ssh/authorized_keys and or /home/ubuntu/.ssh/authorized_keys"
