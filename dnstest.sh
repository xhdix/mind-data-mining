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
  echo "e.g.: ./$0 vodafone-dot ../src/probe-engine/miniooni 8.8.8.8 dot://1.1.1.1 dns.google.com dot://9.9.9.9 https://cloudflare-dns.com/dns-query"  1>&2
  echo ""
  echo "e.g.: ./$0 vodafone-full-test ../src/probe-engine/miniooni \$(cat ./dnslist)"  1>&2
  echo ""
  exit 1
}

inputCount=$#

[ $inputCount -ge 1 ] || usage_then_die

mkdir -p ./tmp
log_file=./tmp/`date +%Y%m%dT%H%M%SZ`-$1.log
report_file=./tmp/`date +%Y%m%dT%H%M%SZ`-$1.jsonl
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

function require() {
  checking "for $1"
  if ! [ -x "$(command -v $1)" ]; then
    fatal "not found; please run: $2"
  fi
  log "ok"
}

require jq "sudo apt install jq (or sudo apk add jq)"

function getipv4second() {
  echo $(tail -n1 $report_file|jq -r ".test_keys.queries|.[0]|select(.hostname==\"$1\")|select(.query_type==\"A\")|.answers|.[1].ipv4")
}

function run() {
  echo ""      >> $log_file
  echo "+ $@"  >> $log_file
  "$@"        2>> $log_file
}

function urlgetterdo53() {
  run $path -v -o $report_file -OResolverURL=udp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over UDP is done."
  run $path -v -o $report_file -OResolverURL=udp://"$1":53 -i dnslookup://twitter.com urlgetter &
  wait
  log "DNS over UDP is done. (Twitter)"
  run $path -v -o $report_file -OResolverURL=udp://"$1":53 -i dnslookup://pornhub.com urlgetter &
  wait
  log "DNS over UDP is done. (Pornhub)"
  run $path -v -o $report_file -OResolverURL=udp://"$1":53 -i dnslookup://www.who.int urlgetter &
  wait
  log "DNS over UDP is done. (www.who.int)"
  run $path -v -o $report_file -OResolverURL=tcp://"$1":53 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TCP is done."
  run $path -v -o $report_file -OResolverURL=tcp://"$1":53 -i dnslookup://twitter.com urlgetter &
  wait
  log "DNS over TCP is done. (Twitter)"
  run $path -v -o $report_file -OResolverURL=tcp://"$1":53 -i dnslookup://pornhub.com urlgetter &
  wait
  log "DNS over TCP is done.(Pornhub)"
  run $path -v -o $report_file -OResolverURL=tcp://"$1":53 -i dnslookup://www.who.int urlgetter &
  wait
  log "DNS over TCP is done.(www.who.int)"
}

function urlgetterdot() {
  run $path -v -o $report_file -OResolverURL=dot://$1:853 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TLS is done."
  run $path -v -o $report_file -OResolverURL=dot://$1:853 -i dnslookup://twitter.com urlgetter &
  wait
  log "DNS over TLS is done. (Twitter)"
  run $path -v -o $report_file -OResolverURL=dot://$1:853 -i dnslookup://pornhub.com urlgetter &
  wait
  log "DNS over TLS is done. (Pornhub)"
  run $path -v -o $report_file -OResolverURL=dot://$1:853 -i dnslookup://www.who.int urlgetter &
  wait
  log "DNS over TLS is done. (www.who.int)"
  ipv4_second=$(getipv4second $1)
  if [[ $ipv4_second =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    run $path -v -o $report_file -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://example.com urlgetter &
    wait
    log "DNS over TLS is done with the second IP."
    run $path -v -o $report_file -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://twitter.com urlgetter &
    wait
    log "DNS over TLS is done with the second IP. (Twitter)"
    run $path -v -o $report_file -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://pornhub.com urlgetter &
    wait
    log "DNS over TLS is done with the second IP. (Pornhub)"
    run $path -v -o $report_file -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://www.who.int urlgetter &
    wait
    log "DNS over TLS is done with the second IP. (www.who.int)"
  fi
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=dot://$1:853 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over TLS v1.3 is done."
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=dot://$1:853 -i dnslookup://twitter.com urlgetter &
  wait
  log "DNS over TLS v1.3 is done. (Twitter)"
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=dot://$1:853 -i dnslookup://pornhub.com urlgetter &
  wait
  log "DNS over TLS v1.3 is done. (Pornhub)"
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=dot://$1:853 -i dnslookup://www.who.int urlgetter &
  wait
  log "DNS over TLS v1.3 is done. (www.who.int)"
  ipv4_second=$(getipv4second $1)
  if [[ $ipv4_second =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    run $path -v -o $report_file  -OTLSVersion=TLSv1.3 -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://example.com urlgetter &
    wait
    log "DNS over TLS v1.3 is done with the second IP."
    run $path -v -o $report_file  -OTLSVersion=TLSv1.3 -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://twitter.com urlgetter &
    wait
    log "DNS over TLS v1.3 is done with the second IP. (Twitter)"
    run $path -v -o $report_file  -OTLSVersion=TLSv1.3 -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://pornhub.com urlgetter &
    wait
    log "DNS over TLS v1.3 is done with the second IP. (Pornhub)"
    run $path -v -o $report_file  -OTLSVersion=TLSv1.3 -ODNSCache="$1 $ipv4_second" -OResolverURL=dot://$1:853 -i dnslookup://www.who.int urlgetter &
    wait
    log "DNS over TLS v1.3 is done with the second IP. (www.who.int)"
  fi
}

function urlgetterdoh() {
  run $path -v -o $report_file -OResolverURL=$1 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over HTTPS is done."
  run $path -v -o $report_file -OResolverURL=$1 -i dnslookup://twitter.com urlgetter &
  wait
  log "DNS over HTTPS is done. (Twitter)"
  run $path -v -o $report_file -OResolverURL=$1 -i dnslookup://pornhub.com urlgetter &
  wait
  log "DNS over HTTPS is done. (Pornhub)"
  run $path -v -o $report_file -OResolverURL=$1 -i dnslookup://www.who.int urlgetter &
  wait
  log "DNS over HTTPS is done. (www.who.int)"
  domain=$(echo $1 | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")
  ipv4_second=$(getipv4second $domain)
  if [[ $ipv4_second =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    run $path -v -o $report_file -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://example.com urlgetter &
    wait
    log "DNS over HTTPS is done with the second IP."
    run $path -v -o $report_file -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://twitter.com urlgetter &
    wait
    log "DNS over HTTPS is done with the second IP. (Twitter)"
    run $path -v -o $report_file -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://pornhub.com urlgetter &
    wait
    log "DNS over HTTPS is done with the second IP. (Pornhub)"
    run $path -v -o $report_file -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://www.who.int urlgetter &
    wait
    log "DNS over HTTPS is done with the second IP. (www.who.int)"
  fi
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=$1 -i dnslookup://example.com urlgetter &
  wait
  log "DNS over HTTPS (TLSv1.3) is done."
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=$1 -i dnslookup://twitter.com urlgetter &
  wait
  log "DNS over HTTPS (TLSv1.3) is done. (Twitter)"
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=$1 -i dnslookup://pornhub.com urlgetter &
  wait
  log "DNS over HTTPS (TLSv1.3) is done. (Pornhub)"
  run $path -v -o $report_file -OTLSVersion=TLSv1.3 -OResolverURL=$1 -i dnslookup://www.who.int urlgetter &
  wait
  log "DNS over HTTPS (TLSv1.3) is done. (www.who.int)"
  domain=$(echo $1 | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")
  ipv4_second=$(getipv4second $domain)
  if [[ $ipv4_second =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    run $path -v -o $report_file -OTLSVersion=TLSv1.3 -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://example.com urlgetter &
    wait
    log "DNS over HTTPS (TLSv1.3) is done with the second IP."
    run $path -v -o $report_file -OTLSVersion=TLSv1.3 -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://twitter.com urlgetter &
    wait
    log "DNS over HTTPS (TLSv1.3) is done with the second IP. (Twitter)"
    run $path -v -o $report_file -OTLSVersion=TLSv1.3 -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://pornhub.com urlgetter &
    wait
    log "DNS over HTTPS (TLSv1.3) is done with the second IP. (Pornhub)"
    run $path -v -o $report_file -OTLSVersion=TLSv1.3 -ODNSCache="$domain $ipv4_second" -OResolverURL=$1 -i dnslookup://www.who.int urlgetter &
    wait
    log "DNS over HTTPS (TLSv1.3) is done with the second IP. (www.who.int)"
    
  fi
}

inputCounter=0
inputCount=$#

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


