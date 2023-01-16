# How to access host VPN in `multipass`?
Not sure if this is a workaround or solution, but I was able to make this work by nat-ing the multipass bridge with my vpn interface.
I added `nat on utun1 from bridge100:network to any -> (utun1)` to file `/etc/pf.conf`. Then I reloaded the file: `$ sudo pfctl -f /etc/pf.conf`.

I'll just note that it's important to put the above line in the correct place in the file - after the other nat- line, otherwise it will not be accepted.

For example final `pf.conf` content in my case after addition looks like following:
```
#
# com.apple anchor point
#
scrub-anchor "com.apple/*"
nat-anchor "com.apple/*"                                      <--- this is the existing configuration
nat on utun3 from bridge100:network to any -> (utun3)         <--- this is my addition
rdr-anchor "com.apple/*"
dummynet-anchor "com.apple/*"
anchor "com.apple/*"
load anchor "com.apple" from "/etc/pf.anchors/com.apple"
```


To see which `utun` you have do either one of:
1. `netstat -nr | grep tun`. Here  you should have smth like. (here `utun3` is yours)
```
10.1/16            10.8.0.1           UGSc            utun3
10.2/16            10.8.0.1           UGSc            utun3
10.3/16            10.8.0.1           UGSc            utun3
10.4/16            10.8.0.1           UGSc            utun3
10.6/16            10.8.0.1           UGSc            utun3
10.7.16/20         10.8.0.1           UGSc            utun3
10.8/24            10.8.0.24          UGSc            utun3
10.8.0.1           10.8.0.24          UH              utun3
10.12.64/18        10.8.0.1           UGSc            utun3
10.121/16          10.8.0.1           UGSc            utun3
10.122/16          10.8.0.1           UGSc            utun3
10.123/16          10.8.0.1           UGSc            utun3
10.124/16          10.8.0.1           UGSc            utun3
148.251.181.57/32  10.8.0.1           UGSc            utun3
```
2. `ifconfig`. Here you should have smth like (here `utun3` is yours)
```
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::61e4:b634:9acf:d51d%utun0 prefixlen 64 scopeid 0xe
	nd6 options=201<PERFORMNUD,DAD>
utun1: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 2000
	inet6 fe80::c8d2:f804:22ce:cf47%utun1 prefixlen 64 scopeid 0xf
	nd6 options=201<PERFORMNUD,DAD>
utun2: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1000
	inet6 fe80::ce81:b1c:bd2c:69e%utun2 prefixlen 64 scopeid 0x10
	nd6 options=201<PERFORMNUD,DAD>
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
	inet 10.8.0.24 --> 10.8.0.1 netmask 0xffffff00
```

Source https://github.com/canonical/multipass/issues/495#issuecomment-448461250
