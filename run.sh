#!/bin/bash
docker run -it -d --name hostapd -e INTERFACE=wlp1s0 -e BRIDGE=br0 --net host --privileged --restart=unless-stopped docker-ap 

