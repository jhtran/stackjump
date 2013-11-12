#!/bin/bash

source /root/extras/stackjump.config

BOND0IP=${BOND0_IP:-192.168.199.199}
BOND0MASK=${BOND0_NETMASK:-255.255.255.0}
BOND0GW=${BOND0_GATEWAY:-192.168.1.1}
BOND0BUSORDER=${BOND0_BUSORDER:-'"0000:00:05.0","0000:00:06.0","0000:00:07.0","0000:00:08.0"'}

cat<<EOF > /root/extras/chef-repo/roles/setup-network.json
{
  "name": "setup-network",
  "default_attributes": {
  },
  "json_class": "Chef::Role",
  "env_run_lists": {
  },
  "run_list": [
    "recipe[networking]"
  ],
  "description": "Initial network bonding and vlan convergence",
  "chef_type": "role",
  "override_attributes": {
    "reboot-handler": {
      "enabled_role": "setup-network",
      "post_boot_runlist": [
        "recipe[chef-client]",
        "role[booted]"
      ]
    },
    "networking": {
      "interfaces": {
        "bond0": {
          "address": "$BOND0IP",
          "netmask": "$BOND0MASK",
          "bond-mode": "$BOND0MODE",
          "gateway": "$BOND0GW"
        }
      },
      "udev": {
        "bus_order": [
          $BOND0BUSORDER
        ]
      }
    }
  }
}
EOF
knife role from file /root/extras/chef-repo/roles/setup-network.json
knife node run_list add $FQDN "role[setup-network]"
chef-client
