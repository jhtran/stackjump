PATH="$PATH:.."
GITURL="https://github.com/jhtran"
GITREPO="https://github.com/jhtran/stackjump_skeleton.git"
BADREPO="https://github.com/jhtran/BAD_skeleton.git"
alias sj="stackjump -t "

randomn() {
  openssl rand -base64 32
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
