#!/bin/sh
# Route dnsmasq to NordVPN DNS. Best effort DNS-leak guard, not DoH detection.
set -eu
uci set network.wan.peerdns='0'
uci set dhcp.@dnsmasq[0].noresolv='1'
uci -q delete dhcp.@dnsmasq[0].server || true
uci add_list dhcp.@dnsmasq[0].server='103.86.96.100'
uci add_list dhcp.@dnsmasq[0].server='103.86.99.100'
uci -q delete network.lan.ip6assign || true
uci set dhcp.lan.ra='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'
uci -q get network.wan6 >/dev/null && uci set network.wan6.disabled='1'
uci commit network
uci commit dhcp
mkdir -p /etc/nftables.d
cat > /etc/nftables.d/pi5-dns-guard.nft <<'RULES'
chain pi5_dns_output_guard {
    type filter hook output priority -1; policy accept;
    oifname "eth0" meta l4proto { tcp, udp } th dport { 53, 853 } reject
}
RULES
fw4 check
/etc/init.d/firewall restart
/etc/init.d/dnsmasq restart
/etc/init.d/odhcpd restart
echo 'DNS configured. Verify client DNS and IPv6 leaks before relying on it.'
