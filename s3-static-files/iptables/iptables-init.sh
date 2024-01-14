#!/bin/bash

#!/bin/bash

# iptables single-host firewall script

# Define your command variables
ipt="/sbin/iptables"

# Flush all rules and delete all chains
# for a clean startup
$ipt -F
$ipt -X

# Zero out all counters
$ipt -Z

# Default policies: deny all incoming
# Unrestricted outgoing
$ipt -P INPUT DROP
$ipt -P FORWARD DROP
$ipt -P OUTPUT ACCEPT

# Must allow loopback interface
$ipt -A INPUT -i lo -j ACCEPT

# Reject connection attempts not initiated from the host
# $ipt -A INPUT -p tcp --syn -j DROP

# Allow return connections initiated from the host
$ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Accept all ICMP v6 packets
$ipt -A INPUT -p ipv6-icmp -j ACCEPT

# Optional rules to allow other LAN hosts access
# to services. Delete $ipt -A INPUT -p tcp --syn -j DROP

# Allow DHCPv6 from LAN only
# $ipt -A INPUT -m state --state NEW -m udp -p udp -s fe80::/10 --dport 546 -j ACCEPT

# Allow connections from SSH clients
# $ipt -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT

# Allow HTTP and HTTPS traffic
# $ipt -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
# $ipt -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT

# Allow TCP traffic from whitelisted IPv4s
input="/etc/iptables/whitelisted-ipv4-tcp.txt"
while IFS= read -r line
do
  $ipt -A INPUT -p tcp -s $line -j ACCEPT
done < "$input"

# Allow UDP traffic from whitelisted IPv4s
input="/etc/iptables/whitelisted-ipv4-udp.txt"
while IFS= read -r line
do
  $ipt -A INPUT -p udp -s $line -j ACCEPT
done < "$input"

# Allow TCP traffic from whitelisted MAC addresses
input="/etc/iptables/whitelisted-mac-tcp.txt"
while IFS= read -r line
do
  $ipt -A INPUT -m mac --mac-source $line -j ACCEPT
done < "$input"

# Allow UDP traffic from whitelisted MAC addresses
input="/etc/iptables/whitelisted-mac-udp.txt"
while IFS= read -r line
do
  $ipt -A INPUT -m mac --mac-source $line -j ACCEPT
done < "$input"