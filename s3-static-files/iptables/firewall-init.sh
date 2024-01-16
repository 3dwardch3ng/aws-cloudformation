#!/bin/bash

echo "iptables / ip6tables single-host firewall script"

echo "Define your command variables"
ipt="/sbin/iptables"
ipt6="/sbin/ip6tables"

echo "Flush all rules and delete all chains"
echo "because it is best to startup cleanly"
$ipt -F
$ipt -X
$ipt -t nat -F
$ipt -t nat -X
$ipt -t mangle -F
$ipt -t mangle -X
$ipt6 -F
$ipt6 -X

echo "Zero out all counters, again for"
echo "a clean start"
$ipt -Z
$ipt -t nat -Z
$ipt -t mangle -Z
$ipt6 -Z

echo "Default policies: deny all incoming"
echo "Unrestricted outgoing"
$ipt -P INPUT DROP
$ipt -P FORWARD ACCEPT
$ipt -P OUTPUT ACCEPT
$ipt -t nat -P OUTPUT ACCEPT
$ipt -t nat -P PREROUTING ACCEPT
$ipt -t nat -P POSTROUTING ACCEPT
$ipt -t mangle -P PREROUTING ACCEPT
$ipt -t mangle -P POSTROUTING ACCEPT
$ipt6 -P INPUT DROP
$ipt6 -P FORWARD ACCEPT
$ipt6 -P OUTPUT ACCEPT

echo "Must allow loopback interface"
$ipt -A INPUT -i lo -j ACCEPT
$ipt6 -A INPUT -i lo -j ACCEPT

echo "Reject connection attempts not initiated from the host"
# $ipt -A INPUT -p tcp --syn -j DROP
# $ipt6 -A INPUT -p tcp --syn -j DROP

echo "Allow return connections initiated from the host"
$ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$ipt6 -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "Accept important ICMP packets. It is not a good"
echo "idea to completely disable ping; networking"
echo "depends on ping"
$ipt -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT

echo "Accept all ICMP v6 packets"
$ipt6 -A INPUT -p ipv6-icmp -j ACCEPT

echo "The previous lines define a simple firewall"
echo "that does not restrict outgoing traffic, and"
echo "allows incoming traffic only for established sessions"

echo "The following rules are optional to allow external access"
echo "to services. Adjust port numbers as needed for your setup"

echo "Use this rule when you accept incoming connections"
echo "to services, such as SSH and HTTP"
echo "This ensures that only SYN-flagged packets are"
echo "allowed in"
echo "Then delete '$ipt -A INPUT -p tcp --syn -j DROP'"
$ipt -A INPUT p tcp ! --syn -m state --state NEW -j DROP

echo "Optional rules to allow other LAN hosts access"
echo "to services. Delete $ipt6 -A INPUT -p tcp --syn -j DROP"

echo "Allow DHCPv6 from LAN only"
# $ipt6 -A INPUT -m state --state NEW -m udp -p udp -s fe80::/10 --dport 546 -j ACCEPT

echo "Allow connections from SSH clients"
$ipt6 -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT

echo "Allow HTTP and HTTPS traffic"
# $ipt6 -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
# $ipt6 -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT

echo "NAT request forwarding for PiHole instance"

$ipt -P FORWARD ACCEPT
$ipt6 -P FORWARD ACCEPT
$ipt -t nat -A POSTROUTING -o etX0 -j MASQUERADE
$ipt6 -t nat -A POSTROUTING -o etX0 -j MASQUERADE


echo "Allow TCP/UDP traffic from whitelisted IPv4s"
input="/etc/iptables/whitelisted-ipv4.txt"
while IFS= read -r line
do
  $ipt -s $line -F FORWARD
done < "$input"

echo "Allow TCP/UDP traffic from whitelisted IPv6s"
input="/etc/iptables/whitelisted-ipv6.txt"
while IFS= read -r line
do
  $ipt6 -s $line -F FORWARD
done < "$input"

echo "Allow TCP traffic from whitelisted MAC addresses"
input="/etc/iptables/whitelisted-mac.txt"
while IFS= read -r line
do
  $ipt -m mac --mac-source $line -F FORWARD
  $ipt6 -m mac --mac-source $line -F FORWARD
done < "$input"

service $ipt save
service $ipt6 save