# Stackjump

A framework for generating custom Ubuntu auto-install ISO image and incorporates a Chef Server daemon in which the node will register itself against, auto configure knife as well as automatically register itself via chef-client against localhost.  It can be used to standup the initial jump node of an openstack zone.  It requires no network to stand up and can be incorporated with additional cookbooks such as complicated network interface configurations (bonding, vlan tagging) that will converge itself up to par once it has completed its initial installation and starts chef-client registration automatically.

## Post Install Note

Using the stackjump generated ISO, after the Ubuntu installation is complete it will reboot once and run the "first_boot.sh" script to setup chef-server and other post installation final touches.   

During the reboot you will see the Ubuntu loading screen and it may appear to hang but the startup process takes about ~5 minutes to get back to a login screen briefly, before it is restarted a second time (see below).  The duration of that hang time depends on how large your chef-repo directory was and how many cookbooks were in it.

During this loading screen you can hit ESC to watch the console or do an Alt+F2 to get an alternate login console for troubleshooting.

After the second reboot, the system should be ready for you to login and verify the network configuration is correct and the network(s) accessible.

The expected run_list after the second reboot is "recipe[chef-client]" and "role[booted]"

## Initial Network Convergence

This AT&T version of stackjump will automatically add cookbook-networking & cookbook-reboot-handler to the run list and therefore some custom packages (vlan & ifenslave-2.6) have been added to the stackjump build process.  On the first chef-client run, this cookbook execution should converge the bonded and vlan nic configurations as you'd expect, in order to connect to the various networks including the public internet.  

Currently, the cookbook-networking default recipe relies on some pre-existing attributes for node['networking']['bus_order'] & node['networking']['bond'] information, as well as node['reboot-handler'] attrs, usually injected by a manul intervention via substructure.  However, we've configured a custom role "setup-network" with these attrs as an override, however, this role will be removed from the node run_list when the networking::default recipe executes reboot-handler it will clean out the run_list.

## TODO

If we could make the att-cloud "networking" & "reboot-handler" cookbooks public (not requiring authentication in order to clone them), then it would be more easily automated into stackjump without having to designate it in a chef-repo manually.

## Chef-repo

Your chef-repo must be in the following directory structure:

* chef-repo/roles
* chef-repo/environments
* chef-repo/cookbooks
* TODO: databags

## Usage

Before you run the command, edit the 'stackjump.config' and customize any of the parameters to fit your needs.

 * Simplest - no args will default to Ubuntu 12.04.3 Precise 64-bit and output "custom.iso" to your current directory, and chef will only upload and run minimal chef-client cookbook.

   However, for AT&T's custom deployment, the  '-c /path/to/your/chef-repo' is a required flag, at minimum you need to ensure the cookbooks "networking" & "reboot-handler" exists in that chef-repo so that it can converge the   bonding and vlan configuration to enable the jump node to connect to internal networks and public internet.

   ./stackjump -c /path/to/my/chef-repo

 * Custom iso name

  ./stackjump -c /path/to/my/chef-repo -o /home/me/foobar.iso

 * Dry-run - don't actually create the iso

  ./stackjump -c /path/to/my/chef-repo -d

 * Keep tempfiles

  ./stackjump -c /path/to/my/chef-repo -k

 * verbose

  ./stackjump -c /path/to/my/chef-repo -V

 * Advanced - although the framework has options to specify other Ubuntu versions and releases, it hasn't been tested yet.

   ./stackjump -c /path/to/my/chef-repo -v 14.04 -r trusty

 * custom scripts at first run - any custom scripts you want to execute at first run, put into the custom_scripts directory (instead of modifying the first_run.sh, it will automatically be executed

## Chef Server

By default, Stackjump will load only the minimal chef-client cookbook, which enables automatic chef-client interval jobs against itself (localhost).  However, the framework can accept additional chef-repo (cookbooks, roles, data_bags).  Use -c to point it to your chef-repo directory.  This will ensure all of the cookbooks will get uploaded to its chef-server installation.  Then to add any cookbooks or recipes or roles to the node's initial run_list, create a script in the ./custom_scripts directory.

As an example:

* git clone git@github.com:me/chef-repo /home/me/chef-repo

* cd /home/me/chef-repo && bundle exec berks install

* add ' knife node run_list add mynode.mydomain.com "recipe[mycookbook::myrecipe]" ' to ./custom_scripts/my_add_run_list_custom_script.sh

* ./stackjump -c /home/me/chef-repo

Once the node auto installs and stands up , you should be able to login as root and do a "knife cookbook list" and see the new cookbook(s) you've uploaded.  As well as "knife node show mynode.mydomain.com" and see the updated run_list.

## VM Configuration

The stackjump generated ISOs have been tested on VirtualBox as well as Parallels.  Just make sure you configure 4 network interfaces, emulating one of our real bare metal boxes.  Ensure the first two network interfaces belong to a network with internet connectivity and the last two network interfaces on an isolated network completely seperate from the first two interfaces.  When you modify the stackjump.config just ensure the BOND0_IP && NETMASK && GW information are legitimate address information that'll allow the vm to connect to your network, specifically at the minimum a legitimate ip for the gateway.
