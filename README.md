# Docker container stack: bridged hostap

This image starts a wireless access point (hostap) in a Docker container. It utilizes bridge-utils to create a bridge between the WLAN interface and the LAN (cabled Ethernet) interface, thus dropping the requirement for a separate DHCP server. Because of the intricacies of networking in this scenario, this remix was only tested using host networking in docker.

This repository does not do a very good job of isolating all the necessary interface work inside the container. It is much better suited to be used on a dedicated system. Pull requests, especially with an update to wlanstart.sh with brctl commands, are welcome.

## Requirements

On the host system, make sure your WLAN interface is available (`ip link`), then make sure your Wi-Fi adapter supports AP mode:

```
# iw list
...
        Supported interface modes:
                 * IBSS
                 * managed
                 * AP
                 * AP/VLAN
                 * WDS
                 * monitor
                 * mesh point
...
```

Set country regulations, for example, for Spain set:

```
# iw reg set ES
country ES: DFS-ETSI
        (2400 - 2483 @ 40), (N/A, 20), (N/A)
        (5150 - 5250 @ 80), (N/A, 23), (N/A), NO-OUTDOOR
        (5250 - 5350 @ 80), (N/A, 20), (0 ms), NO-OUTDOOR, DFS
        (5470 - 5725 @ 160), (N/A, 26), (0 ms), DFS
        (57000 - 66000 @ 2160), (N/A, 40), (N/A)
```

## Build / run

* Configure the bridge:

```
# export ETH_IF=enp2s0  # replace the interface identifier here
# export BR_IF=br0  # replace the interface identifier here
# apt-get install bridge-utils
# sed -i "s/br0/${BR_IF}/g" etc-network-interfaces.append
# sed -i "s/enp2s0/${ETH_IF}/g" etc-network-interfaces.append
# cat etc-network-interfaces.append >> /etc/network/interfaces
# reboot
```

* Remove the `br_netfilter` module:

```
# rmmod br_netfilter
```

This is the easiest way to pass IPv4 traffic between wireless clients and the rest of the LAN.

A more permanent solution ([a fake install](https://wiki.debian.org/KernelModuleBlacklisting)):

```
# cp etc-modprobe.d-br-netfilter.conf /etc/modprobe.d/
# reboot
```

* Build the image:

```
# docker build -t docker-ap -f Dockerfile .
```

* Run using host networking:

```
# docker run -it -d --name hostapd -e INTERFACE=wlp1s0 -e BRIDGE=br0 --net host --privileged --restart=unless-stopped docker-ap 
```

The AP will be available for as long as the container is run and started on boot; if you want it to live until shutdown, remove the `--restart` option.

## Environment variables

* **INTERFACE**: name of the interface to use for wifi access point (default: wlp1s0)
* **BRIDGE**: bridge interface created with bridge-utils (default: br0)
* **CHANNEL**: WIFI channel (default: 6)
* **SSID**: Access point SSID (default: docker-ap)
* **WPA_PASSPHRASE**: WPA password (default: passw0rd)
* **HW_MODE**: WIFI mode to use (default: g) 
* **DRIVER**: WIFI driver to use (default: nl80211, likely there's no need to modify it to match the host)
* **HT_CAPAB**: WIFI HT capabilities for 802.11n (default: [HT40-][HT40+])

They are passed to a new /etc/hostapd.conf inside the container. For reference, [check out this example](https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf).

## License

MIT

## Author

Jaka Hudoklin (jakahudoklin at gmail dot com)    
Marcin Dzieżyc (yakcyll at gmail dot com)

Thanks to https://github.com/sdelrio/rpi-hostap for providing the original implementation.
