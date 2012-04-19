export PATH="$PATH:.."
export GITURL="git@github.com:jhtran"
export GITREPO="git@github.com:jhtran/stackjump_skeleton.git"
alias sj="stackjump -t "

randomn() {
  echo "/tmp/`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 10| head -n 1`"
}
randomf() {
  RANDOM=`randomn`
  echo "preseed_file" > $RANDOM
  echo $RANDOM
}
randomd() {
  RANDOM=`randomn`
  mkdir $RANDOM
  echo "preseed_dir" > $RANDOM/preseed.cfg
  echo $RANDOM
}

teardown() {
  for i in $@; do
    if [ -d $i ]; then
      if [ `expr "$i" : '/tmp'` ]; then  
        rm -rf $i
      fi
    elif [ -f $i ]; then
      if [ `expr "$i" : '/tmp'` ]; then  
        rm -f $i
      fi
    fi
  done
  if [ -f custom.iso ]; then
    rm -f custom.iso
  fi
}
