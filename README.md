# Pi5 Open Router (starter firmware project)

A **public, self-hosted, no-telemetry** OpenWrt firmware build project for Raspberry Pi 5 using internal Ethernet as WAN and built-in Wi-Fi as LAN AP. Includes the standard LuCI authenticated router interface and a small branded dashboard linking to all router settings. WireGuard is included for NordVPN manual configurations.

**Project status: build source / prototype, NOT a tested firmware binary.** The image build and Pi 5 radio must be validated on hardware before relying on this as a secure router. The custom dashboard is a navigation page, not a one-click NordVPN uploader or initial setup wizard.

## What is included

- GitHub Actions builds the **official OpenWrt 25.12.6 Raspberry Pi 5** image with packages installed.
- Local-only LuCI admin login and `Pi5 Open Router` dashboard. Admin settings use standard LuCI authenticated screens.
- WireGuard and firewall4 support, no cloud control agent, no project telemetry.
- WAN conversion and VPN/DNS firewall setup scripts that you run **locally over SSH** after prerequisites work.
- No accounts required for router management. **NordVPN subscription and NordVPN server connection are still required to use that provider**.

## Security-first initial installation

**There is no universal Wi-Fi password embedded in public firmware.** This is intentional. On first boot Ethernet remains LAN, and Wi-Fi is disabled until you create a unique password.

1. In GitHub, create a public repository and upload this source code. Actions → **Build Pi 5 firmware** → Run workflow. Download the `pi5-open-router` artifact. Unzip it and select `*rpi-5*squashfs-factory.img.gz`.
2. Flash the factory image to microSD using Raspberry Pi Imager custom image. Raspberry Pi 5 needs adequate power.
3. Connect laptop **directly by Ethernet** to Pi, assign a static laptop IPv4 such as `192.168.50.2/24` if necessary, browse `http://192.168.50.1`. Set your LuCI/SSH root password.
4. LuCI → Network → Wireless: turn on built-in radio, set country CA (or your actual country), create an AP named `Pi5-NordVPN` with a **unique WPA2 AES password**, attach it to `lan`. Ensure LAN DHCP server enabled. Some Pi5 Broadcom Wi-Fi/driver revisions may have AP issues. Validate first.
5. Connect the laptop to this AP, confirm `http://192.168.50.1` works via Wi-Fi, disconnect laptop Ethernet, and SSH over Wi-Fi.
6. To change Ethernet into WAN, transfer `scripts/switch-ethernet-to-wan.sh` to `/tmp/` with `scp`, then over Wi-Fi run:
   ```sh
   touch /tmp/wifi-management-confirmed
   sh /tmp/switch-ethernet-to-wan.sh
   ```
   Attach Pi Ethernet to existing home-router LAN. Verify WAN DHCP and Internet.
7. From Nord Account → NordVPN → Advanced settings → Set up manually → WireGuard, download configuration **onto your own computer**, not into the GitHub repository. The router does not speak to any project backend. Create a `nordvpn` WireGuard interface in LuCI → Network → Interfaces, configure private key, tunnel address, peer public key, endpoint, allowed IPs `0.0.0.0/0`, route allowed IPs, and keepalive. **Use a numerical endpoint IPv4** and a persistent WAN /32 route for it if full-tunnel routing would otherwise capture the peer endpoint. Verify `wg show` handshake first.
8. After the tunnel works, transfer and run `enable-vpn-firewall.sh` over SSH. This removes LAN→WAN forwarding and enables LAN→VPN forwarding; your clients should fail closed when WireGuard is down.
9. Transfer and run `lock-down-dns.sh`. It configures dnsmasq with NordVPN DNS, stops WAN peer DNS, disables LAN IPv6 advertisements and drops router-originated port 53/853 DNS over Ethernet. **This does not block app DoH over HTTPS**. Test leaks from the client.
10. Test VPN public IP and DNS at ipleak.net. Run `ifdown nordvpn` and ensure client browsing fails. Re-enable and reboot to confirm persistence.

## Build locally instead of GitHub

On Ubuntu x86_64:

```sh
sudo apt update && sudo apt install -y wget zstd build-essential python3
BASE=https://downloads.openwrt.org/releases/25.12.6/targets/bcm27xx/bcm2712
NAME=openwrt-imagebuilder-25.12.6-bcm27xx-bcm2712.Linux-x86_64.tar.zst
wget "$BASE/$NAME"
echo "5a379d82bf1e134fc328c01d3de53350c3bca4603be69615581d165bef3867ab  $NAME" | sha256sum -c -
mkdir imagebuilder && tar --zstd -xf "$NAME" -C imagebuilder --strip-components=1
cd imagebuilder
make image PROFILE=rpi-5 FILES=/path/to/pi5-open-router/overlay PACKAGES='luci luci-proto-wireguard wireguard-tools kmod-wireguard wpad-basic-mbedtls'
```

## Threat model and limitations

- No user traffic is deliberately forwarded to project servers. OpenWrt package updates normally contact official OpenWrt package servers when invoked; WireGuard necessarily contacts the NordVPN endpoint; optional services such as NTP may still make network requests. **No third-party connections whatsoever is not compatible with an internet/VPN router.**
- Administrator uses local LuCI sessions. HTTPS for LAN management is recommended; plain HTTP is not encrypted.
- The VPN kill switch protects forwarded LAN client traffic by firewall zone, but the router's own other network traffic is not globally blocked. The DNS guard covers ordinary resolver traffic over eth0 and 853, **not DNS-over-HTTPS**.
- IPv6 is disabled on client LAN for the IPv4 VPN setup. Clients should be retested after network changes.
- Pi 5 AP usability depends on firmware and the built-in radio driver; first verify the radio can function as an AP.
- OpenWrt and bundled packages have their own licenses. This project's original code is MIT-licensed; OpenWrt remains governed by its respective licenses.

## License

MIT for this project's own scripts/UI. OpenWrt and its software retain their original licenses.
