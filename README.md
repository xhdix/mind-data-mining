# mind data mining
Everything and nothing


---------------------

## Censorship

#### check SNI blocking 1
``` sh
curl -4v --trace-time -m 31 --connect-to ::www.notblocked.com: https://www.blocked.com/
```
#### check SNI blocking 2
`4.3.2.1` => notblocked.com 
``` sh
curl -v --trace-time -m 31 --resolve 'www.blocked.com:443:4.3.2.1' https://www.blocked.com/
```
#### check IP blocking 1
`1.2.3.4` => blocked.com 
``` sh
curl -v --trace-time -m 31 --resolve 'www.notblocked.com:80:1.2.3.4' http://www.notblocked.com/
```
#### check IP blocking 2
`1.2.3.4` => blocked.com 
``` sh
curl -v --trace-time -m 31 --resolve 'www.notblocked.com:443:1.2.3.4' https://www.notblocked.com/
```
#### DNS over UDP -- system
```sh
dig blocked.com
```
#### DNS trace over UDP -- system
```sh
dig blocked.com +trace
```
#### DNS over TCP -- system
```sh
dig +tcp blocked.com
```
#### DNS over TCP -- specefic 
```sh
dig +tcp blocked.com @1.0.0.1
```
### DNS over HTTPS 1
``` sh
curl -s  "https://dns.google.com/resolve?name=www.blocked.com&type=ANY&random_padding=cvbnmertyuiaskdkadaas128somerandompaddingminusdomainname128dskvbnmghjkluiobmghjkbnmghjkvbnmcvbnghjklsdfxcvqwertghjydKFs"
```
128 byte <= domain + padding
### DNS over HTTPS 2
``` sh
curl -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=www.blocked.com&type=A'"
```
Domain-fronting:
``` sh
curl -H 'Host: dns.cloudflare.com' -H 'accept: application/dns-json' 'https://cloudflare.com/dns-query?name=www.blocked.com&type=A'"
```
Connect with proxy:
``` sh
curl -x socks5://127.0.0.1:9050 -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=www.blocked.com&type=A'"
```
#### check IP blocking
``` sh
sudo traceroute --tcp --queries=1 -O info --port=443 1.2.3.4
```
#### more analysis
``` sh
mtr -n -T 1.2.3.4 -P 443 --report
mtr -n -T 1.2.3.4 -P 80 --report
mtr -n -T 1.2.3.4 -P 1234 --report
mtr -n 1.2.3.4 --report
mtr -n -u 1.2.3.4 -P 53 --report
mtr -n -u 1.2.3.4 -P 22 --report
```

#### domain-fronting
``` sh
curl -vH "Host: www.blocked.com" https://www.notblocked.com/
```

#### capture packets
``` sh
sudo tcpdump -w filename.pcap 'host 1.2.3.4'
```

#### list packets
``` sh
tshark -r filename.pcap -Tfields -e frame.number -e tcp.time_delta -e ip.src -e ip.id -e ip.ttl -e tcp.window_size -e _ws.col.Info -Y 'ip.addr eq 1.2.3.4'
```
With more details:
```sh
tshark -r filename.pcap -T fields -e frame.number -e frame.time_relative -e tcp.time_delta -e tcp.analysis.initial_rtt -e ip.src -e frame.len -e tcp.dstport -e ip.id -e ip.ttl -e tcp.window_size -e tcp.stream -e _ws.col.Info -E header=y -Y 'ip.addr eq 1.2.3.4'
```

### OpenSSL
```sh
openssl s_client -state -nbio -connect www.blocked.com:443 2>&1 | grep "^SSL"
openssl s_client -state -nbio -connect www.blocked.com:443 | grep "^SSL"
openssl s_client -state -nbio -connect www.blocked.com:443
openssl s_client -state -nbio -tlsextdebug -servername www.blocked.com -connect 1.2.3.4:443
```

#### check fingerprint
```sh
openssl s_client -connect example.com:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -sha256 -noout -in /dev/stdin
```

