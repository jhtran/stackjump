#!/bin/bash

source /root/extras/stackjump.config

BUSORDER=${BUSORDER:-'"0000:00:05.0","0000:00:06.0","0000:00:07.0","0000:00:08.0"'}

BOND0IP=${BOND0_IP:-192.168.199.199}
BOND0MASK=${BOND0_NETMASK:-255.255.255.0}
BOND0GW=${BOND0_GATEWAY:-192.168.1.1}
BOND0MODE=${BOND0_MODE:-active-backup}

MGMT_CIDR=${MANAGEMENT_CIDR:-'192.168.199.0/20'}

BOND12002IP=${BOND1_2002_IP:-192.168.199.199}
BOND12002MASK=${BOND1_2002_NETMASK:-255.255.255.0}
DEFAULTGW=${DEFAULT_GATEWAY:-192.168.199.1}
BOND12001IP=${BOND1_2002_IP:-192.168.199.199}
BOND12001MASK=${BOND1_2002_NETMASK:-255.255.255.0}

ZONE=${ZONE:-myzone}
IS_VM=${IS_VM:-false}  # is this a vm? or bare metal?
GHUSER=${GH_USER:-myghuser}
GHPW=${GH_PW:-myghpassword}
SUBSDECRYPTPW=${SUBS_DECRYPT_PW:-subsdecryptpassword}


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
      "decryptpw": "$SUBSDECRYPTPW",
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
        "ops": "0.0.0.0/0",
        "mgmt": "$MGMT_CIDR"
      },
      "is_vm": $IS_VM,
      "interfaces": {
        "ops": "bond1.2002",
        "bond0": {
          "address": "$BOND0IP",
          "netmask": "$BOND0MASK",
          "bond-mode": "$BOND0MODE",
          "dns-nameservers": [ "8.8.8.8" ],
          "gateway": "$BOND0GW"
        },
        "bond1.2001": {
          "address": "$BOND12001IP",
          "netmask": "$BOND12001MASK"
        },
        "bond1.2002": {
          "address": "$BOND12002IP",
          "netmask": "$BOND12002MASK",
          "gateway": "$DEFAULTGW"
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
    "recipe[apt]",
    "recipe[infra-management::subs_bootstrap]",
    "recipe[infra-management::chef-repo]",
    "recipe[infra-management::setup_ipmi]"
  ],
  "description": "Initial network bonding and vlan convergence",
  "chef_type": "role",
  "override_attributes": {
    "zone": "$ZONE",
    "infra-management": {
      "ghuser": "$GHUSER",
      "ghpw": "$GHPW",
      "decryptpw": "$SUBSDECRYPTPW",
      "is_vm": $IS_VM
    },
    "networking": {
      "cidr": {
        "ops": "0.0.0.0/0",
        "mgmt": "$MGMT_CIDR"
      },
      "is_vm": $IS_VM,
      "interfaces": {
        "ops": "bond1.2002",
        "bond0": {
          "address": "$BOND0IP",
          "netmask": "$BOND0MASK",
          "bond-mode": "$BOND0MODE",
          "dns-nameservers": [ "8.8.8.8" ],
          "gateway": "$BOND0GW"
        },
        "bond1.2001": {
          "address": "$BOND12001IP",
          "netmask": "$BOND12001MASK"
        },
        "bond1.2002": {
          "address": "$BOND12002IP",
          "netmask": "$BOND12002MASK",
          "gateway": "$DEFAULTGW"
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
