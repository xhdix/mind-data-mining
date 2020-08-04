#!/bin/bash
#
#https://github.com/bassosimone/aladdin/blob/master/domain-check.bash
#
#
#

function usage_then_die() {
  echo ""
  echo "usage: $0 <test-name> <miniooni-path> <IP> <domain> <URI>" 1>&2
  echo ""
  echo "e.g.: ./$0 vodafone ../src/probe-engine/miniooni sitename.com" 1>&2
  echo ""
  exit 1
}

inputCount=$#

[ $inputCount -ge 1 ] || usage_then_die

mkdir -p ./tmp
log_file=./tmp/`date +%Y%m%d`-$1.log
report_file=./tmp/`date +%Y%m%d`-$1.jsonl
shift

function log() {
  echo "$@" 1>&2
}

if [ ! -x $1 ]; then
   log "miniooni not found in $1"
   usage_then_die
else
  path=$1
  shift
fi

function checking() {
  log -n "checking $@... "
}

function fatal() {
  log "$@"
  exit 1
}

function run() {
  echo ""      >> $log_file
  echo "+ $@"  >> $log_file
  "$@"        2>> $log_file
}

function urlgetter() {
  run $path -v -o $report_file -A step=host_header_blocking -i http://"$1" urlgetter &
  wait
  log "http test is done."
}

inputCounter=0
inputCount=$#

while [[ $1 != "" ]]; do
  ((inputCounter++))
  input=$1
  log "[$inputCounter/$inputCount] running with input: $input"
  urlgetter $input &
  wait
  sleep 1
  shift
done
