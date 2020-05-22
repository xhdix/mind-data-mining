#!/bin/bash
#
#https://github.com/ooni/probe-engine/pull/616
#https://github.com/bassosimone/aladdin/blob/master/domain-check.bash
#
function usage_then_die() {
  echo ""
  echo "usage: $0 <minioonipath> <IP> <IP> <domain> <domain> <domain>" 1>&2
  echo ""
  echo ""
  exit 1
}

inputCount=$#

[ $inputCount -ge 1 ] || usage_then_die

if [ ! -x $1 ]; then
   log "miniooni not found in $1"
   usage_then_die
else
  path=$1
  shift
fi

function log() {
  echo "$@" 1>&2
}

function fatal() {
  log "$@"
  exit 1
}

log_file=dnstest.log
log -n "removing stale $log_file from previous runs if needed... "
rm -f $log_file
log "done"

function run() {
  echo ""      >> $log_file
  echo "+ $@"  >> $log_file
  "$@"        2>> $log_file
}

function urlgetterip() {
  run $path -v -OResolverURL=udp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over UDP is done."
  run $path -v -OResolverURL=tcp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TCP is done."
  run $path -v -OResolverURL=dot://"$1":853 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TLS is done."
  PTR=$(dig +short -x $1)
  run $path -v -OResolverURL=https://${PTR%?}/dns-query -i dnslookup://example.com urlgetter &
  wait
  log "DNS over HTTPS is done."
}

function urlgetterdomain() {
  run $path -v -OResolverURL=https://$1/dns-query -i dnslookup://example.com urlgetter &
  wait
  log "DNS over HTTPS is done."
}

inputCounter=0
((inputCount--))
while [[ $1 != "" ]]; do
  ((inputCounter++))
  log "[$inputCounter/$inputCount] running with input: $1"
  if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    urlgetterip $1 &
  else
    urlgetterdomain $1 &
  fi
  wait
  sleep 1
  shift
done


