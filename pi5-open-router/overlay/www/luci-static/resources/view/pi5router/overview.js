'use strict';
'require view';

return view.extend({
  render: function() {
    function tile(title, description, url) {
      return E('div', { 'style': 'display:inline-block;vertical-align:top;box-sizing:border-box;min-width:220px;max-width:320px;margin:8px;padding:18px;border:1px solid #cbd5e1;border-radius:12px' }, [
        E('h3', {}, title), E('p', {}, description),
        E('a', { 'class': 'btn cbi-button', 'href': url }, 'Open settings')
      ]);
    }
    return E('div', {}, [
      E('h2', {}, 'Pi5 Open Router'),
      E('p', {}, 'Local-only router administration. Nothing here requires an external control account.'),
      E('p', {}, 'First-time setup: create a secure Wi-Fi access point, verify Wi-Fi login, then convert Ethernet from LAN to WAN. Configure WireGuard using a NordVPN file. Never paste VPN secrets into GitHub.'),
      tile('Wi-Fi & SSID', 'Choose the access-point name, password, channel, and country.', L.url('admin/network/wireless')),
      tile('WAN & LAN', 'Set Ethernet DHCP WAN and Wi-Fi LAN gateway.', L.url('admin/network/network')),
      tile('WireGuard', 'Manage NordVPN WireGuard connection and peers.', L.url('admin/network/network')),
      tile('Firewall / Kill Switch', 'Permit LAN to VPN only. Remove LAN to WAN forwarding.', L.url('admin/network/firewall')),
      tile('Router security', 'Change the local administrator password.', L.url('admin/system/admin')),
      E('p', { 'style': 'margin-top:20px;color:#64748b' }, 'Open-source OpenWrt base. No cloud dashboard or telemetry code is installed by this project.')
    ]);
  },
  handleSave: null,
  handleSaveApply: null,
  handleReset: null
});
