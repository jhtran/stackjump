#!/bin/bash

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
          "address": "192.168.1.195",
          "netmask": "255.255.255.0",
          "bond-mode": "active-backup",
          "gateway": "192.168.1.1"
        }
      },
      "udev": {
        "bus_order": [
          "0000:06:00.0",
          "0000:06:00.1",
          "0000:03:00.0",
          "0000:03:00.1"
        ]
      }
    }
  }
}
EOF
knife role from file /root/extras/chef-repo/roles/setup-network.json
knife node run_list add $FQDN "role[setup-network]"
chef-client
