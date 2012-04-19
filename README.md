# Stackjump

Creates a preseeded mini iso to stand up fully automated Ubuntu install with Chef.

The mini iso created will be small, we're talking less than 20MB.

Ideal for those who don't want to mount a large DVD install ISO over IPMI.

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

If you want to keep the temp directory around

	$ stackjump -p /tmp/mypreseed.cfg -k
	Downloading linux files..
	Temp dir: /tmp/0418121303
	custom.iso successfully created

Use the -d arg and no need to pass -p, but just make sure the dir has
a preseed.cfg (named exactly as such) in its root directory.

	$ stackjump -d /tmp/root_skeleton

If you want files to be injected into the OS at runtime

NOTE if you decide to include a preseed instead of passing it as a 
seperate argument, it must be named 'preseed.cfg' and must be located 
in the root of the dir you'll be using.
See [stackjump_skeleton](http://github.com/jhtran/stackjump_skeleton) as an example dir.

	$ mkdir -p /tmp/root_skel/home/ubuntu/.ssh /tmp/root_skel/etc
	$ cp mypreseed.cfg /tmp/root_skel/preseed.cfg
	$ cp mypubkeys /tmp/root_skel/home/ubuntu/.ssh/authorized_keys
	$ cp /etc/some.config /tmp/root_skel/etc
	$ stackjump -d /tmp/root_skel

Using -p preseed arg with a -d or a -g will use the preseed from -p 
regardless if a preseed.cfg exists in those dirs

	$ stackjump -d /tmp/root_skel -p mypreseed.cfg

Output a different iso name other than default custom.iso

	$ stackjump -p mypreseed.cfg -o myubuntu.iso

Specify an architecture (i386 or amd64) if diff than your workstation

	$ stackjump -p mypreseed.cfg -a amd64

Specify an Ubuntu distro codename other than the default (natty)

	$ stackjump -p mypreseed.cfg -r oneiric
	$ stackjump -p mypreseed.cfg -r precise -a amd64
	$ stackjump -p mypreseed.cfg -r maverick -a i386

## Testing

These tests rely on roundup (https://github.com/bmizerany/roundup)

NOTE For these tests to pass successfully, it will require internet connectivity.

Just execute 'roundup' in the tests dir.

	$ cd tests && roundup
