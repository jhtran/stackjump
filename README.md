# Stackjump

Creates a preseeded mini iso to stand up fully automated Ubuntu install with Chef.

The mini iso created will be small, we're talking less than 20MB.

Ideal for those who don't want to mount a large DVD locally to install the OS such as over IPMI.

Useful for standing up the first admin server in a network deployment such as for Openstack or other cloud framework.

## Installation

$ gem install stackjump

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

# Examples

$
