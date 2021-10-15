#!/bin/sh


killall gprs

##
ETH0_MAC=80:31:DC:FF:81:30
ETH1_MAC=80:31:DC:FF:81:31

ifconfig swp0 hw ether $ETH0_MAC
ifconfig swp1 hw ether $ETH1_MAC

ifconfig swp0 192.168.1.1 netmask 255.255.255.0
ifconfig swp1 192.168.1.2 netmask 255.255.255.0


#ip route flush table all
route add 192.168.1.11 dev swp0
route add 192.168.1.22 dev swp1


arp -i swp0 -s 192.168.1.11 $ETH1_MAC
arp -i swp1 -s 192.168.1.22 $ETH0_MAC


iptables -t nat -F

iptables -t nat -A POSTROUTING  -s 192.168.1.1  -d 192.168.1.11 -j SNAT --to-source             192.168.1.22
iptables -t nat -A PREROUTING   -s 192.168.1.22 -d 192.168.1.11 -j DNAT --to-destination        192.168.1.2

iptables -t nat -A POSTROUTING  -s 192.168.1.2  -d 192.168.1.22 -j SNAT --to-source             192.168.1.11
iptables -t nat -A PREROUTING   -s 192.168.1.11 -d 192.168.1.22 -j DNAT --to-destination        192.168.1.1
