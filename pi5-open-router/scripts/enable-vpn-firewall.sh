#!/bin/sh
# Run after NordVPN WireGuard interface named 'nordvpn' is configured and connected.
set -eu
uci -q get network.nordvpn.proto | grep -qx wireguard || { echo 'Missing WireGuard interface nordvpn'; exit 1; }
cp /etc/config/firewall "/etc/config/firewall.pre-vpn.$(date +%s)"
# Remove LAN-to-WAN forwardings regardless of anonymous/named section IDs.
for sec in $(uci show firewall | sed -n 's/^firewall\.\([^.=]*\)=forwarding$/\1/p'); do
  src=$(uci -q get "firewall.$sec.src" || true)
  dst=$(uci -q get "firewall.$sec.dest" || true)
  if [ "$src" = lan ] && [ "$dst" = wan ]; then uci delete "firewall.$sec"; fi
done
uci set firewall.vpn='zone'
uci set firewall.vpn.name='vpn'
uci -q delete firewall.vpn.network || true
uci add_list firewall.vpn.network='nordvpn'
uci set firewall.vpn.input='REJECT'
uci set firewall.vpn.output='ACCEPT'
uci set firewall.vpn.forward='REJECT'
uci set firewall.vpn.masq='1'
uci set firewall.vpn.mtu_fix='1'
uci set firewall.lan_to_vpn='forwarding'
uci set firewall.lan_to_vpn.src='lan'
uci set firewall.lan_to_vpn.dest='vpn'
uci commit firewall
fw4 check
/etc/init.d/firewall restart
echo 'LAN to WAN removed; LAN to VPN allowed. Test by disabling nordvpn.'
