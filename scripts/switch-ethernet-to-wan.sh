#!/bin/sh
# Use only AFTER Wi-Fi works and you can log in via 192.168.50.1.
set -eu
[ "$(uci -q get network.lan.ipaddr)" = '192.168.50.1' ] || { echo 'LAN address unexpected; aborting'; exit 1; }
[ -f /tmp/wifi-management-confirmed ] || { echo 'Run: touch /tmp/wifi-management-confirmed AFTER confirming Wi-Fi access'; exit 1; }
cp /etc/config/network "/etc/config/network.pre-wan.$(date +%s)"
bridge_section=''
for sec in $(uci show network | sed -n 's/^network\.\([^.=]*\)=device$/\1/p'); do
  if [ "$(uci -q get "network.$sec.name")" = 'br-lan' ]; then bridge_section="$sec"; break; fi
done
[ -n "$bridge_section" ] || { echo 'br-lan device section not found; abort'; exit 1; }
uci -q del_list "network.$bridge_section.ports=eth0" || true
uci set network.wan='interface'
uci set network.wan.device='eth0'
uci set network.wan.proto='dhcp'
uci commit network
/etc/init.d/network restart
echo 'Ethernet set to DHCP WAN. Manage router via Wi-Fi 192.168.50.1.'
