# Stackjump

A framework for generating custom Ubuntu auto-install ISO image and incorporates a Chef Server daemon in which the node will register itself against, auto configure knife as well as automatically register itself via chef-client against localhost.  It can be used to standup the initial jump node of an openstack zone.  It requires no network to stand up and can be incorporated with additional cookbooks such as complicated network interface configurations (bonding, vlan tagging) that will converge itself up to par once it has completed its initial installation and starts chef-client registration automatically.

NOTE: When using the ISO image, after the Ubuntu installation is complete it will reboot once and run the "first_boot.sh" script to setup chef-server and other post installation final touches.   During the reboot you will see the Ubuntu loading screen and it may appear to hang but the startup process takes about ~5 minutes to get back to a login screen.  If it takes significantly longer, you can do an Alt+F2 to get an alternate login console for troubleshooting.

This AT&T version of stackjump will automatically add cookbook-networking to the run list.  In order to execute this, a custom 'jumpnode.json' will be loaded via knife node from file jumpnode.json and carries custom networking attributes, such as bus_order and bond info, that the networking cookbook requires.  On the first chef-client run, this cookbook execution should converge the bonded and vlan nic configurations as you'd expect, in order to connect to the various networks including the public internet.

## Usage

Before you run the command, edit the 'stackjump.config' and customize any of the parameters to fit your needs.

 * Simplest - no args will default to Ubuntu 12.04.3 Precise 64-bit and output "custom.iso" to your current directory, and chef will only upload and run minimal chef-client cookbook.
   Stackjump will upload (cookbooks, roles, envs) from the designated chef-repo directory to your new jump server

   However, '-c /path/to/your/chef-repo' is the only required flag, at minimum you need to ensure the cookbook "networking" exists in that chef-repo

   ./stackjump -c /path/to/my/chef-repo

 * Custom iso name

  ./stackjump -c /path/to/my/chef-repo -o /home/me/foobar.iso

 * Dry-run - don't actually create the iso

  ./stackjump -d

 * Keep tempfiles

  ./stackjump -c /path/to/my/chef-repo -k

 * verbose

  ./stackjump -c /path/to/my/chef-repo -V

 * Advanced - although the framework has options to specify other Ubuntu versions, releases and arch, it hasn't been tested yet.

   ./stackjump -c /path/to/my/chef-repo -v 14.04 -r trusty -a i386

 * custom scripts at first run - any custom scripts you want to execute at first run, put into the custom_scripts directory (instead of modifying the first_run.sh, it will automatically be executed

 * by default only the chef-client and networking cookbooks are added to the jump node's run list at first chef-client execution.  You can add custom run_list add items to the jumpnode.json file

## Chef Server

By default, Stackjump will load only the minimal chef-client cookbook, which enables automatic chef-client interval jobs against itself (localhost).  However, the framework can accept additional chef-repo (cookbooks, roles, environments).  Use -c to point it to your chef-repo directory.  This will ensure all of the cookbooks will get uploaded to its chef-server installation.  Then modify the jumpnode.json to add any cookbooks or recipes or roles to the node's initial run_list.

As an example:

* git clone git@github.com:att-cloud/chef-repo /home/me/chef-repo

* cd /home/me/chef-repo && bundle exec berks install --path /home/me/chef-repo/cookbooks

* add "recipe[mycookbook::myrecipe]" to the run_list in jumpnode.json

* customize ./stackump.config

* ./stackjump -c /home/me/chef-repo

Once the node auto installs and stands up , you should be able to login as root and do a "knife cookbook list" and see the new cookbook(s) you've uploaded.  As well as "knife node show mynode.mydomain.com" and see the updated run_list.
