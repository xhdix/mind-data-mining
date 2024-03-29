#!/bin/bash

#bash ./domainlist filename.pcap minTTL maxTTL
# or:
#for i in $(find ./ -type f -name '*.pcap'); do ./randomblockedlist.sh $i minTTL maxTTL; done

filename=$1
min=$2
max=$3

echo $filename

if [[ $filename == "" ]] || [[ $min == "" ]] || [[ $max == "" ]] ; then
    echo "usage:"
    echo "bash ./domainlist filename.pcap minTTL maxTTL"
    exit
fi

declare -A domains

declare -A ips

echo "finding injections..."
set -f        # disable globbing
IFS=$'\n'     # set field separator to NL (only)
streams=( $(tshark -nr $filename -Tfields -e tcp.stream -2R "ip.ttl > $min && ip.ttl < $max" -Y "!icmp && tcp.port eq 443 && tcp.flags ne 0x014") )

if [ ${#streams[@]} -eq 0 ]; then
    echo "there is no injected stream."
    echo ""
    exit
fi

tsharkstreams=""
i=0

for stream in "${streams[@]}" ; do
    #echo "for: $stream"
    if [[ "$i" -eq 0 ]] ; then
        tsharkstreams+="(tcp.stream eq $stream"
    else
        tsharkstreams+=" || tcp.stream eq $stream"
    fi
    ((i++))
done

tsharkstreams+=")"

echo ""

echo "streams: "

echo "$tsharkstreams"

echo ""

echo "total injected in streams: $i"

echo "finding server names..."

servernames=( $(tshark -nr $filename -Tfields -e tls.handshake.extensions_server_name -2R "$tsharkstreams && tls.handshake.extension.type eq 0") )

for servername in "${servernames[@]}"; do
    if [[ -v "domains[$servername]" ]] ; then
        ((domains["$servername"]+=1))
    else
        domains["$servername"]=1
    fi
done

echo "total injected in domains: ${#domains[@]}"

echo "random blocked sites are:"
echo ""
echo "Domain name , Frequency of occurrence"
echo ""
i=0

for domain in "${!domains[@]}"; do
    ((i++))
    echo $domain ' , ' ${domains["$domain"]}
done | sort -k3,3rn -k1,1

echo ""

echo ""

echo "finding IPs..."

serverips=( $(tshark -nr $filename -Tfields -e ip.dst -2R "$tsharkstreams && tcp.flags eq 0x002") )

for serverip in "${serverips[@]}"; do
    if [[ -v "ips[$serverip]" ]] ; then
        ((ips["$serverip"]+=1))
    else
        ips["$serverip"]=1
    fi
done

echo "total injected in IPs: ${#ips[@]}"

echo "random blocked ips are:"
echo ""
echo "IP address , Frequency of occurrence"
echo ""
i=0

for ip in "${!ips[@]}"; do
    ((i++))
    echo $ip ' , ' ${ips["$ip"]}
done | sort -k3,3rn -k1,1

echo ""
