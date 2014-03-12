#!/bin/bash

source /root/extras/stackjump.config
export FQDN=`hostname -f`

BUSORDER=${BUSORDER:-'"0000:00:05.0","0000:00:06.0","0000:00:07.0","0000:00:08.0"'}

BOND0IP=${BOND0_IP:-192.168.112.11}
BOND0MASK=${BOND0_NETMASK:-255.255.255.128}
BOND0GW=${BOND0_GATEWAY:-192.168.112.1}
BOND0MODE=${BOND0_MODE:-active-backup}

MGMT_CIDR=${MANAGEMENT_CIDR:-'192.168.0.0/20'}

BOND12002IP=${BOND1_2002_IP:-75.55.108.11}
BOND12002MASK=${BOND1_2002_NETMASK:-255.255.240.0}
DEFAULTGW=${DEFAULT_GATEWAY:-75.55.108.1}
BOND12001IP=${BOND1_2001_IP:-192.168.128.11}
BOND12001MASK=${BOND1_2001_NETMASK:-255.255.255.128}

ZONE=${ZONE:-myzone}
IS_VM=${IS_VM:-false}  # is this a vm? or bare metal?
GHUSER=${GH_USER:-myghuser}
GHPW=${GH_PW:-myghpassword}
SUBSDECRYPTPW=${SUBS_DECRYPT_PW:-subsdecryptpassword}

ROLESD="/root/extras/chef-repo/roles"
cat<<EOF > $ROLESD/setup-network.json
{
  "name": "setup-network",
  "default_attributes": {
  },
  "json_class": "Chef::Role",
  "env_run_lists": {
  },
  "run_list": [
    "recipe[chef-client]",
    "recipe[networking]"
  ],
  "description": "Initial network bonding and vlan convergence",
  "chef_type": "role",
  "override_attributes": {
    "reboot-handler": {
      "enabled_role": "setup-network",
      "post_boot_runlist": [
        "role[INSTALLATION_PENDING-upload_data_bags]"
      ]
    }
  }
}
EOF
knife role from file $ROLESD/setup-network.json

CUSTOM_IPRULES=''
if [ $IS_VM = true ]; then
  read -r -d '' CUSTOM_IPRULES<<EOF
  "iptables": {
    "input_rules": [
      "-A INPUT -i eth4 -j ACCEPT",
      "-A INPUT -i eth4 -m state --state RELATED,ESTABLISHED -j ACCEPT",
      "-A INPUT -i eth4 -p tcp --dport 22 -j ACCEPT"
    ]
  },
EOF

  cat<<EOF > /root/extras/is_vm
sed -i 's,gateway.*,,g' /etc/network/interfaces.d/bond1.2002
grep eth4 /etc/network/interfaces
if [ $? != 0 ]; then
cat<<EOH>> /etc/network/interfaces
auto eth4
iface eth4 inet dhcp
EOH
fi
route delete -net 0.0.0.0/0
ifdown eth4 --force
ifup eth4
EOF

  chmod 755 /root/extras/is_vm
  cat<<EOF > /etc/init/is_vm.conf
description "remove default gw of lacp bond when using vm"

start on starting networking

task

exec bash /root/extras/is_vm
EOF
fi

JUMPF="$ROLESD/first_jump.json"
cat<<EOF > $JUMPF
{
  "run_list": [
    "role[setup-network]"
  ],
  $CUSTOM_IPRULES
  "zone": "${ZONE}",
  "infra-management": {
    "ghuser": "${GHUSER}",
    "ghpw": "${GHPW}",
    "decryptpw": "${SUBSDECRYPTPW}",
    "is_vm": $IS_VM
  },
  "networking": {
    "interfaces": {
      "bond0": {
        "address": "${BOND0IP}",
        "netmask": "${BOND0MASK}",
        "bond-mode": "${BOND0MODE}",
        "dns-nameservers": [ "8.8.8.8" ],
        "gateway": "${BOND0GW}"
      },
      "bond1.2001": {
        "address": "${BOND12001IP}",
        "netmask": "${BOND12001MASK}"
      },
      "bond1.2002": {
        "address": "${BOND12002IP}",
        "netmask": "${BOND12002MASK}",
        "gateway": "${DEFAULTGW}"
      }
    },
    "udev": {
      "bus_order": [
        $BUSORDER
      ]
    }
  }
}
EOF

CHEFR_HANDLER="$ROLESD/INSTALLATION_PENDING-chef-repo.json"
cat<<EOF > $CHEFR_HANDLER
{
  "name": "INSTALLATION_PENDING-chef-repo",
  "default_attributes": {
  },
  "json_class": "Chef::Role",
  "env_run_lists": {
  },
  "run_list": [
    "recipe[infra-management::chef-repo]"
  ],
  "description": "chef-repo upload on first install",
  "chef_type": "role",
  "override_attributes": {
    "run_list_handler": {
      "enabled_role": "INSTALLATION_PENDING-chef-repo",
      "post_boot_runlist": [
        "role[chef-server]",
        "recipe[infra-auth::client]",
        "role[${ZONE}]",
        "role[infra-access]",
        "role[infra-auth-slave]"
      ]
    }
  }
}
EOF
knife role from file $CHEFR_HANDLER

DBAG_HANDLER="$ROLESD/INSTALLATION_PENDING-upload_data_bags.json"
cat<<EOF > $DBAG_HANDLER
{
  "name": "INSTALLATION_PENDING-upload_data_bags",
  "default_attributes": {
  },
  "json_class": "Chef::Role",
  "env_run_lists": {
  },
  "run_list": [
    "recipe[infra-management::upload_data_bags]"
  ],
  "description": "data bag upload on first install",
  "chef_type": "role",
  "override_attributes": {
    "run_list_handler": {
      "enabled_role": "INSTALLATION_PENDING-upload_data_bags",
      "post_boot_runlist": [
        "role[INSTALLATION_PENDING-chef-repo]"
      ]
    }
  }
}
EOF
knife role from file $DBAG_HANDLER

zonerolef="$ROLESD/$ZONE.json"
if [ ! -f $zonerolef ]; then
cat<<EOF > $zonerolef
{
  "name": "${ZONE}",
  "default_attributes": {
    "database-backup": {
      "staas": {
        "directory": "${ZONE}"
      },
      "cron": {
        "hour": "4,12,20",
        "minute": "38"
      }
    },
    "dns": {
      "public_forward_zone": "${ZONE}.attcompute.com",
      "public_forward_domain": "${ZONE}.attcompute.com"
    },
    "graphite": {
      "server_hostname": "monitoring.${ZONE}.attcompute.com",
      "cas_root_proxy_url": "https://monitoring.${ZONE}.attcompute.com:8443"
    },
    "infra-monitoring": {
      "ipmi": {
      },
      "ssl_checks": {
        "additional_hosts": [
          "monitoring.${ZONE}.attcompute.com:443",
          "dashboard.${ZONE}.attcompute.com:443"
        ]
      }
    },
    "nagios": {
      "server_hostname": "monitoring.${ZONE}.attcompute.com",
      "cas_root_proxy_url": "https://monitoring.${ZONE}.attcompute.com"
    },
    "IPS": {
      "network": "192.168.1.0",
      "netmask": "255.255.255.0",
      "bond": "bond0",
      "primary_gw": "192.168.112.129",
      "secondary_gw": "192.168.112.193"
    },
    "vizgems": {
    },
    "vms": {
      "sysconfig": {
        "shared_volume": "/vol/gridcentric",
        "vms_user": "libvirt-qemu",
        "vms_group": "kvm"
      }
    }
  },
  "json_class": "Chef::Role",
  "env_run_lists": {
  },
  "run_list": [
    "recipe[openstack-base::${ZONE}]",
    "role[base]"
  ],
  "description": "A role that all ${ZONE} nodes will have.",
  "chef_type": "role",
  "override_attributes": {
  }
}
EOF
  knife role from file $zonerolef
fi

chef-client -j $JUMPF
chef-client
