#!/usr/bin/env roundup

PATH="$PATH:.."
alias sj="stackjump"

it_reqs_args() {
  ! sj
}

it_displays_usage() {
  OUT=`sj|head -2|tail -1`
  expr "$OUT" : '  -p preseed'
}
