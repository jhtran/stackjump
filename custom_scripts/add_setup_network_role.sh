#!/bin/bash

source /root/extras/stackjump.config

BUSORDER=${BUSORDER:-'"0000:00:05.0","0000:00:06.0","0000:00:07.0","0000:00:08.0"'}

BOND0IP=${BOND0_IP:-192.168.199.199}
BOND0MASK=${BOND0_NETMASK:-255.255.255.0}
BOND0GW=${BOND0_GATEWAY:-192.168.1.1}
BOND0MODE=${BOND0_MODE:-active-backup}

BOND1IP=${BOND1_IP:-192.168.199.199}
BOND1MASK=${BOND1_NETMASK:-255.255.255.0}
BOND1GW=${BOND1_GATEWAY:-192.168.1.1}
BOND1MODE=${BOND1_MODE:-active-backup}

ZONE=${ZONE:-myzone}
IS_VM=${IS_VM:-false}  # is this a vm? or bare metal?
GHUSER=${GH_USER:-myghuser}
GHPW=${GH_PW:-myghpassword}


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
    "zone": "$ZONE",
    "infra-management": {
      "ghuser": "$GHUSER",
      "ghpw": "$GHPW",
      "is_vm": $IS_VM
    },
    "reboot-handler": {
      "enabled_role": "setup-network",
      "post_boot_runlist": [
        "recipe[chef-client]",
        "role[setup-bootstrap]"
      ]
    },
    "networking": {
      "cidr": {
        "mgmt": "0.0.0.0/0"
      },
      "is_vm": $IS_VM,
      "interfaces": {
        "bond0": {
          "address": "$BOND0IP",
          "netmask": "$BOND0MASK",
          "bond-mode": "$BOND0MODE",
          "dns-nameservers": [ "8.8.8.8" ],
          "gateway": "$BOND0GW"
        },
        "bond1.2001": {
          "address": "$BOND1IP",
          "netmask": "$BOND1MASK"
        }
      },
      "udev": {
        "bus_order": [
          $BUSORDER
        ]
      }
    }
  }
}
EOF
cat<<EOF > /root/extras/chef-repo/roles/setup-bootstrap.json
{
  "name": "setup-bootstrap",
  "default_attributes": {
  },
  "json_class": "Chef::Role",
  "env_run_lists": {
  },
  "run_list": [
    "recipe[infra-management::subs_bootstrap]"
  ],
  "description": "Initial network bonding and vlan convergence",
  "chef_type": "role",
  "override_attributes": {
    "zone": "$ZONE",
    "infra-management": {
      "ghuser": "$GHUSER",
      "ghpw": "$GHPW",
      "is_vm": $IS_VM
    },
    "networking": {
      "cidr": {
        "mgmt": "0.0.0.0/0"
      },
      "is_vm": $IS_VM,
      "interfaces": {
        "bond0": {
          "address": "$BOND0IP",
          "netmask": "$BOND0MASK",
          "bond-mode": "$BOND0MODE",
          "dns-nameservers": [ "8.8.8.8" ],
          "gateway": "$BOND0GW"
        },
        "bond1.2001": {
          "address": "$BOND1IP",
          "netmask": "$BOND1MASK"
        }
      },
      "udev": {
        "bus_order": [
          $BUSORDER
        ]
      }
    }
  }
}
EOF
knife role from file /root/extras/chef-repo/roles/*.json
knife node run_list add $FQDN "role[setup-network]"
chef-client
