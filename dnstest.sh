#!/bin/bash
#
#https://github.com/ooni/probe-engine/pull/616
#https://github.com/bassosimone/aladdin/blob/master/domain-check.bash
#
#
#

function usage_then_die() {
  echo ""
  echo "usage: $0 <test-name> <miniooni-path> <IP> <domain> <URI>" 1>&2
  echo ""
  echo "e.g.: ./$0 vodafone-dot dot://1.1.1.1 dns.google.com dot://9.9.9.9"  1>&2
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

function run() {
  echo ""      >> $log_file
  echo "+ $@"  >> $log_file
  "$@"        2>> $log_file
}

function urlgetterdo53() {
  run $path -v -o $report_file -OResolverURL=udp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over UDP is done."
  run $path -v -o $report_file -OResolverURL=tcp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TCP is done."
}

function urlgetterdot() {
  run $path -v -o $report_file -OResolverURL=dot://$1:853 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TLS is done."
}

function urlgetterdoh() {
  run $path -v -o $report_file -OResolverURL=$1 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over HTTPS is done."
}

inputCounter=0
inputCount=$#
((inputCount--))

while [[ $1 != "" ]]; do
  ((inputCounter++))
  input=$1
  log "[$inputCounter/$inputCount] running with input: $input"
  if [[ $input =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ; then
    urlgetterdo53 $input &
  elif [[ ${input:0:8} == "https://" ]] ; then
    urlgetterdoh $input &
  elif [[ ${input:0:6} == "dot://" ]] ; then
    urlgetterdot ${input:6} &
  else
    urlgetterdot $input &
  fi
  wait
  sleep 1
  shift
done


