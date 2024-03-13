#! /bin/sh
echo "Executing '$0'"
[ "$UID" != 0 ] && echo must run as root && exit 1
. libs/net-vars.sh

ip link add name "$bridge" type bridge
ip address add "$bridge_addr/$bridge_mash" dev "$bridge"
ip link set "$bridge" up

dnsmasq_conf=/etc/dnsmasq.conf
dnsmasq_conf_start='# setup-net.sh,'"$bridge"' start' 
dnsmasq_conf_end='# setup-net.sh,'"$bridge"' end' 
if grep -q "$dnsmasq_conf_start" "$dnsmasq_conf" &&\
   grep -q "$dnsmasq_conf_end" "$dnsmasq_conf"
then
  sed "/$dnsmasq_conf_start/,/$dnsmasq_conf_end/d" -i "$dnsmasq_conf"
fi
echo "
$dnsmasq_conf_start
interface=$bridge
dhcp-option=$bridge,3,$bridge_addr
dhcp-option=$bridge,6,$bridge_addr
dhcp-range=$bridge,$bridge_dhcp_range_start,$bridge_dhcp_range_end,12h
$dnsmasq_conf_end" >> "$dnsmasq_conf"
systemctl restart dnsmasq.service

sysctl net/ipv4/ip_forward=1
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
for interface in $default_routes; do
  iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
  iptables -A FORWARD -i $bridge -o $interface -j ACCEPT
done
