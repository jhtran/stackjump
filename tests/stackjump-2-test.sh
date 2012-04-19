#!/usr/bin/env roundup

. ./test_helper.sh

it_uses_chef_solo_json_when_dir_already_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  mkdir -p $RANDOMD/root/chef-solo
  echo "dir_solo.json" > $RANDOMD/root/chef-solo/solo.json
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  test `wc -l $TMPDIR/$SOLOPATH/solo.json|awk '{print $1}'` = 1
  test "`head -1 $TMPDIR/$SOLOPATH/solo.json`" = 'dir_solo.json'
  #teardown $TMPDIR
}

#it_uses_chef_solo_json_when_github_no_haz() {
#  TMPDIR=`sj -g $GITREPO -k|grep Temp|awk '{print $3}'`
#  teardown $PRESEED
#  test -f $TMPDIR/$SOLOPATH/solo.json
#  # i stubbed a blank line in github file cuz json can't have comment stubs
#  test `wc -l $TMPDIR/$SOLOPATH/solo.json|awk '{print $1}'` = 4
#  teardown $TMPDIR
#}
