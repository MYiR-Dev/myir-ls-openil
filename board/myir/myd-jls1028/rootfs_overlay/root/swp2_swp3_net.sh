#!/bin/sh


killall gprs

##
ETH0_MAC=80:31:DC:FF:81:32
ETH1_MAC=80:31:DC:FF:81:33

ifconfig swp2 hw ether $ETH0_MAC
ifconfig swp3 hw ether $ETH1_MAC

ifconfig swp2 192.168.2.1 netmask 255.255.255.0
ifconfig swp3 192.168.2.2 netmask 255.255.255.0


#ip route flush table all
route add 192.168.2.11 dev swp2
route add 192.168.2.22 dev swp3


arp -i swp2 -s 192.168.2.11 $ETH1_MAC
arp -i swp3 -s 192.168.2.22 $ETH0_MAC


iptables -t nat -F

iptables -t nat -A POSTROUTING  -s 192.168.2.1  -d 192.168.2.11 -j SNAT --to-source             192.168.2.22
iptables -t nat -A PREROUTING   -s 192.168.2.22 -d 192.168.2.11 -j DNAT --to-destination        192.168.2.2

iptables -t nat -A POSTROUTING  -s 192.168.2.2  -d 192.168.2.22 -j SNAT --to-source             192.168.2.11
iptables -t nat -A PREROUTING   -s 192.168.2.11 -d 192.168.2.22 -j DNAT --to-destination        192.168.2.1
