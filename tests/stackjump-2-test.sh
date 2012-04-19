#!/usr/bin/env roundup

. ./test_helper.sh

it_uses_valid_github_preseed() {
  TMPDIR=`sj -g $GITREPO -k|grep Temp|awk '{print $3}'`
  expr "`head -2 $TMPDIR/initrd/preseed.cfg|tail -1`" : '.*debian-installer\/locale'
  teardown $TMPDIR
}
