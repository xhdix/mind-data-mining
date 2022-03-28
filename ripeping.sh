#!/bin/bash

probelist='123456,456789'
ripekey='key-here'
inputfile='./iplistp.txt'
outputfile="measurement-name.txt"
emailaddr="name@email.com"
tags='"tag1","tag2"'

probecount=$(echo $probelist| tr ',' ' ' | wc -w)

function runcurl() {
    poststring='{"definitions":[{"target":"'$1'","af":4,"packets":10,"size":48,"description":"Ping measurement to '$1'","tags":['$tags'],"resolve_on_probe":false,"packet_interval":500,"skip_dns_check":true,"include_probe_id":false,"type":"ping"}],"probes":[{"value":"'$probelist'","type":"probes","requested":'$probecount'}],"is_oneoff":true,"bill_to":"'$emailaddr'"}'
    output=$(curl -sS -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST -d "$poststring" https://atlas.ripe.net/api/v2/measurements//?key=$ripekey)
    echo $output
    if [[ "${output:0:15}" == '{"measurements"' ]]; then
        echo "$output," >> $outputfile &
        wait
        return 0
    else
        return 1
    fi
}

for testip in $(cat $inputfile); do
    shouldwait=true &
    wait
    echo "$testip"
    while $shouldwait; do
        if runcurl "$testip" ; then
            shouldwait=false
        else
            sleep 10 &
            wait
        fi
    done &
    wait
    sleep 10 &
    wait
done



# download measurements:
#
# for measurement in $(cat ./measurement_name.txt); do measurementgid=$(echo ${measurement:0:(-1)} | jq .measurements[0]); for result in $(curl -sS https://atlas.ripe.net/api/v2/measurements/$measurementgid/results/?format=json|jq -c '.[]'); do echo "$result," >> ./measurement_name_results.txt ;done; sleep 3; done
