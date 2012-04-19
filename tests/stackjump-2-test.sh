#!/usr/bin/env roundup

. ./test_helper.sh

check_solo_files() {
  TMPDIR=$1
  SOLOD="$TMPDIR/initrd/root_skel/root/chef-solo"
  CHFBKD="$SOLOD/cookbooks/chef-server"
  RECIPE="$CHFBKD/recipes/default.rb"
  CHEFSEED="$CHFBKD/files/default/chef-server.seed"
  test -f $SOLOD/solo.rb
  test -f $SOLOD/solo.json
  test -f $RECIPE
  test -f $CHEFSEED
  expr "`head -1 $SOLOD/solo.rb`" : 'file_cache_path "/root/chef-solo"'
  test "`head -2 $SOLOD/solo.json|tail -1`" = '  "run_list": [ "recipe[chef-server::default]" ]'
  test "`head -1 $RECIPE`" = "package 'chef-server' do"
  test "`head -3 $RECIPE|tail -1`" = '  response_file "chef-server.seed"'
  expr "`head -1 $CHEFSEED`" : 'chef-server-webui'
  if [ $2 ] && [ $2 = 'githaz' ]; then
    test "`tail -1 $SOLOD/solo.rb`" = '# stackjump default solo.rb'
    test `wc -l $SOLOD/solo.json|awk '{print $1}'` = 4
    expr "`tail -1 $CHEFSEED`" : '# stackjump default chef-server debconf seed file'
  else
    expr "`tail -1 $SOLOD/solo.rb`" : 'cookbook_path "/root/chef-solo/cookbooks"'
    test `wc -l $SOLOD/solo.json|awk '{print $1}'` = 3
    expr "`tail -1 $CHEFSEED`" : 'chef-solr chef-solr'
  fi
}

it_creates_chef_solo_files_when_only_preseed() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  check_solo_files $TMPDIR
  teardown $TMPDIR
}

it_creates_chef_solo_files_when_github_no_haz() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -g $BADREPO -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  check_solo_files $TMPDIR
  teardown $TMPDIR
}

it_creates_chef_solo_files_when_dir_no_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  check_solo_files $TMPDIR
  teardown $TMPDIR
}

it_uses_chef_solo_files_when_github_already_haz() {
  TMPDIR=`sj -g $GITREPO -k|grep Temp|awk '{print $3}'`
  check_solo_files $TMPDIR githaz
  teardown $TMPDIR
}

it_uses_chef_solo_files_when_dir_already_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  mkdir -p $RANDOMD/root/chef-solo
  echo "dir_solo.json" > $RANDOMD/root/chef-solo/solo.json
  echo "dir_solo.rb" > $RANDOMD/root/chef-solo/solo.rb
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  SOLOD="$TMPDIR/initrd/root_skel/root/chef-solo"
  test `wc -l $SOLOD/solo.json|awk '{print $1}'` = 1
  test "`head -1 $SOLOD/solo.json`" = 'dir_solo.json'
  test `wc -l $SOLOD/solo.rb|awk '{print $1}'` = 1
  test "`head -1 $SOLOD/solo.rb`" = 'dir_solo.rb'
  teardown $TMPDIR
}
