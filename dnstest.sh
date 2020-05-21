#!/bin/bash
#
#https://github.com/ooni/probe-engine/pull/616
#
#
function usage_then_die() {
  echo ""
  echo "usage: $0 <IP>" 1>&2
  echo ""
  echo "# Environment variables"
  echo ""
  echo "- MINIOONI_TEST_HELPER: optional domain for test helper"
  echo ""
  echo "- MINIOONI_EXTRA_OPTIONS: extra options for miniooni (e.g. -n to avoid"
  echo "submitting measurements to the OONI collector)"
  echo ""
  exit 1
}

inputCount=$#

[ $inputCount -ge 1 ] || usage_then_die

function log() {
  echo "$@" 1>&2
}

function checking() {
  log -n "checking $@... "
}

function fatal() {
  log "$@"
  exit 1
}

log_file=dnstest.log
log -n "removing stale $log_file and temp files from previous runs if needed... "
rm -f $log_file
log "done"

function run() {
  echo ""      >> $log_file
  echo "+ $@"  >> $log_file
  "$@"        2>> $log_file
}

report_file=report.jsonl

function fatal_with_logs() {
  log "$@"
  log "please, check $log_file and $report_file for more insights"
  exit 1
}

function must() {
  "$@" || fatal_with_logs "failure"
}

function urlgetterip() {
  run ../src/probe-engine/miniooni -v -OResolverURL=udp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  run ../src/probe-engine/miniooni -v -OResolverURL=tcp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  run ../src/probe-engine/miniooni -v -OResolverURL=dot://"$1":853 -i dnslookup://example.com urlgetter &
  wait
  run ../src/probe-engine/miniooni -v -OResolverURL=doh://https://$(resolveip -s $1)/dns-query -i dnslookup://example.com urlgetter &
  wait
}

function urlgetterdomain() {
  run ../src/probe-engine/miniooni -v -OResolverURL=doh://https://$(resolveip -s $1)/dns-query -i dnslookup://example.com urlgetter &
  wait
}

inputCounter=0
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


