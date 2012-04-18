# Stackjump

Creates a preseeded mini iso to stand up fully automated Ubuntu install with Chef.

The mini iso created will be small, we're talking less than 20MB.

Ideal for those who don't want to mount a large DVD locally to install the OS such as over IPMI.

Useful for standing up the first admin server in a network deployment such as for Openstack or other cloud framework.

## Installation

Just download the stackjump script and execute it

## Usage

	$ stackjump 
	stackjump options
	  -p preseed (or use [-d|-g] but -p will take precedence)
	  -d directory (preseed.cfg must exist in dir root)
	  -g github repo (must be github hosted)
	  -a architecture [i386|amd64]
	  -r release_codename (lsb_release -c)
	  -o <file> Write output to <file> instead of custom.iso
	  -k keep tmp dir

	  See http://github.com/jhtran/stackjump_skeleton

## Examples

Simplest run, just give it your preseed file

	$ stackjump -p mypreseed.cfg 
	Downloading linux files..
	custom.iso successfully created

Run if you want to keep the temp directory around

	$ stackjump -p /tmp/mypreseed.cfg -k
	Downloading linux files..
	Temp dir: /tmp/0418121303
	custom.iso successfully created

Use this if you want files to be injected into the OS at runtime
NOTE: if you decide to include a preseed, it must be named 'preseed.cfg'
and must be located in the root of the dir you'll be using

	$ mkdir -p /tmp/root_skel/home/ubuntu /tmp/root_skel/etc
	$ cp mypreseed.cfg /tmp/root_skel/preseed.cfg
	$ cp myfile /tmp/root_skel/home/ubuntu
	$ cp /etc/some.config /tmp/root_skel/etc
	$ stackjump -d /tmp/root_skel

Same as above but in case you decide to pass preseed on the fly

	$ stackjump -d /tmp/root_skel -p mypreseed.cfg

Output a custom iso name instead of default custom.iso

	$ stackjump -p mypreseed.cfg -o myubuntu.iso

Specify an architecture (i386 or amd64) if diff than your workstation

	$ stackjump -p mypreseed.cfg -a amd64

Specify a distribution codename diff than the default (natty)

	$ stackjump -p mypreseed.cfg -r oneiric
	$ stackjump -p mypreseed.cfg -r precise
	$ stackjump -p mypreseed.cfg -r maverick
