#!/bin/sh

# dafault stackjump late_command.sh
# DO NOT MODIFY THIS FILE

mkdir /root/.ssh /home/ubuntu/.ssh
chown -R ubuntu:ubuntu /home/ubuntu
cp -r /media/cdrom/extras /root
chmod 700 /root/.ssh /root/first_run.sh
sed -i 's,quiet splash,quiet,' /etc/default/grub
echo 'GRUB_GFXPAYLOAD_LINUX=text' >> /etc/default/grub
sed -i 's,exit 0,sh /root/first_run.sh,' /etc/rc.local;
