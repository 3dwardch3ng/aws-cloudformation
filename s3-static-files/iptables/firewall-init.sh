#!/bin/bash

#!/bin/bash

# iptables / ip6tables single-host firewall script

# Define your command variables
ipt="/sbin/ip6tables"
ipt6="/sbin/ip6tables"

# Flush all rules and delete all chains
# because it is best to startup cleanly
$ipt -F
$ipt -X
$ipt -t nat -F
$ipt -t nat -X
$ipt -t mangle -F
$ipt -t mangle -X
$ipt6 -F
$ipt6 -X

# Zero out all counters, again for
# a clean start
$ipt -Z
$ipt -t nat -Z
$ipt -t mangle -Z
$ipt6 -Z

# Default policies: deny all incoming
# Unrestricted outgoing
$ipt -P INPUT DROP
$ipt -P FORWARD DROP
$ipt -P OUTPUT ACCEPT
$ipt -t nat -P OUTPUT ACCEPT
$ipt -t nat -P PREROUTING ACCEPT
$ipt -t nat -P POSTROUTING ACCEPT
$ipt -t mangle -P PREROUTING ACCEPT
$ipt -t mangle -P POSTROUTING ACCEPT
$ipt6 -P INPUT DROP
$ipt6 -P FORWARD DROP
$ipt6 -P OUTPUT ACCEPT

# Must allow loopback interface
$ipt -A INPUT -i lo -j ACCEPT
$ipt6 -A INPUT -i lo -j ACCEPT

# Reject connection attempts not initiated from the host
# $ipt -A INPUT -p tcp --syn -j DROP
# $ipt6 -A INPUT -p tcp --syn -j DROP

# Allow return connections initiated from the host
$ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$ipt6 -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Accept important ICMP packets. It is not a good
# idea to completely disable ping; networking
# depends on ping
$ipt -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT

# Accept all ICMP v6 packets
$ipt6 -A INPUT -p ipv6-icmp -j ACCEPT

# The previous lines define a simple firewall
# that does not restrict outgoing traffic, and
# allows incoming traffic only for established sessions

# The following rules are optional to allow external access
# to services. Adjust port numbers as needed for your setup

# Use this rule when you accept incoming connections
# to services, such as SSH and HTTP
# This ensures that only SYN-flagged packets are
# allowed in
# Then delete '$ipt -A INPUT -p tcp --syn -j DROP'
$ipt -A INPUT p tcp ! --syn -m state --state NEW -j DROP

# Optional rules to allow other LAN hosts access
# to services. Delete $ipt6 -A INPUT -p tcp --syn -j DROP

# Allow DHCPv6 from LAN only
# $ipt6 -A INPUT -m state --state NEW -m udp -p udp -s fe80::/10 --dport 546 -j ACCEPT

# Allow connections from SSH clients
$ipt6 -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT

# Allow HTTP and HTTPS traffic
# $ipt6 -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
# $ipt6 -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT

# NAT request forwarding for PiHole instance

# Allow TCP/UDP traffic from whitelisted IPv4s
input="/etc/iptables/whitelisted-ipv4.txt"
while IFS= read -r line
do
  $ipt -A INPUT -p tcp -s $line -j ACCEPT
  $ipt -A INPUT -p udp -s $line -j ACCEPT
done < "$input"

# Allow TCP/UDP traffic from whitelisted IPv6s
input="/etc/iptables/whitelisted-ipv6.txt"
while IFS= read -r line
do
  $ipt6 -A INPUT -p tcp -s $line -j ACCEPT
  $ipt6 -A INPUT -p tudpcp -s $line -j ACCEPT
done < "$input"


# Allow TCP traffic from whitelisted MAC addresses
input="/etc/iptables/whitelisted-mac.txt"
while IFS= read -r line
do
  $ipt6 -A INPUT -m mac --mac-source $line -j ACCEPT
done < "$input"
