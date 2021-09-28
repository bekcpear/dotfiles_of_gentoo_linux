#!/usr/bin/env bash
#

ip tuntap add dev tap0 mode tap group kvm
ip link set dev tap0 up promisc on
ip addr add 0.0.0.0 dev tap0
ip link add br0 type bridge
ip link set br0 up
ip link set tap0 master br0
echo 0 > /sys/class/net/br0/bridge/stp_state
ip addr add 10.0.1.1/24 dev br0

sysctl net.ipv4.conf.tap0.proxy_arp=1
sysctl net.ipv4.conf.wlp3s0.proxy_arp=1
sysctl net.ipv4.conf.enp9s0.proxy_arp=1
sysctl net.ipv4.ip_forward=1

iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o enp9s0 -j MASQUERADE
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i br0 -o wlp3s0 -j ACCEPT
iptables -A FORWARD -i br0 -o enp9s0 -j ACCEPT
