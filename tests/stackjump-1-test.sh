#!/usr/local/bin/roundup

PATH="$PATH:.."
alias sj="stackjump -t "

randomf() {
  echo "/tmp/`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 10| head -n 1`"
}

it_reqs_args() {
  ! sj
}

it_displays_usage() {
  OUT=`sj|head -2|tail -1`
  expr "$OUT" : '  -p preseed'
}

it_needs_real_preseed() {
  RANDOM=`randomf`
  ! OUT=`sj -p $RANDOM`
  test "$OUT" = "$RANDOM not a valid preseed file"
}

it_not_allow_dir_and_git() {
  ! OUT=`sj -d /tmp -g git@github.com/user/proj`
  test "$OUT" = 'Use only one of the -d or -g flags.'
}
