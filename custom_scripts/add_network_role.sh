#!/bin/sh

knife node run_list add $FQDN "recipe[networking]"
