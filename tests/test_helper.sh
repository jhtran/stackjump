PATH="$PATH:.."
GITURL="https://github.com/jhtran"
GITREPO="https://github.com/jhtran/stackjump_skeleton.git"
BADREPO="https://github.com/jhtran/BAD_skeleton.git"
REPOSUBDIRS="cookbooks certificates config data_bags environments roles"
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

randomcr() {
  # dummy chef repo
  RANDOM=`randomd`
  for sdir in $REPOSUBDIRS; do
    mkdir -p $RANDOM/$sdir
  done
  (cd $RANDOM; git init ; git add * ; git commit -am 'first commit') > /dev/null 2>&1
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
