# mind data mining
Everything and nothing


---------------------

### Censorship

#### check SNI blocking 
``` sh
curl -v --trace-time -m 31 --connect-to ::www.notblocked.com: https://www.blocked.com/
```
#### check IP blocking 1
``` sh
curl -v --trace-time -m 31 --resolve 'www.blocked.com:443:1.2.3.4' --connect-to ::www.blocked.com: https://www.notblocked.com/
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
### DNS over HTTPS
``` sh
curl -s  "https://dns.google.com/resolve?name=www.blocked.com&type=ANY&random_padding=askdkadaas32somerandompaddingminusdomainname32dskdKFKs"
```
128 byte <= domain + padding

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

#### some other test
``` sh
curl -sv4 --connect-to ::www.blocked.com https://www.notblocked.com
curl -sv4 https://www.blocked.com
curl -sv4 https://www.notblocked.com
curl -sv4 --connect-to ::www.blocked.com: http://www.notblocked.com
curl -sv4 http://www.blocked.com
curl -sv4 http://www.notblocked.com
```

#### domain-fronting
``` sh
curl -vH "Host: www.blocked.com" https://www.notblocked.com/
```

#### capture packets
``` sh
sudo tcpdump -w MITM.pcap 'host 1.2.3.4'
```

#### list packets
``` sh
tshark -r MITM.pcap -Tfields -e frame.number -e tcp.time_delta -e ip.src -e ip.id -e ip.ttl -e tcp.window_size -e _ws.col.Info -Y 'ip.addr eq 1.2.3.4'
```

