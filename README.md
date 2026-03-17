# UxPlay-Web

A lightweight **AirPlay Mirroring server** in Docker using [UxPlay](https://github.com/FDH2/UxPlay) + Selkies.

## Important limitation (why your domain did not show up in AirPlay)

AirPlay screen mirroring discovery uses **mDNS/Bonjour (link-local multicast)**. iPhone/iPad will not discover an AirPlay target by public DNS domain alone.

- ✅ Works on same LAN/VLAN
- ❌ Does **not** work directly over the public internet/domain without additional network plumbing

So: a reverse proxy/domain helps the **browser viewer**, but does not make iOS AirPlay discovery internet-native.

---

## What works for off-LAN AirPlay

To mirror while away from home, your phone must effectively join your home network path (typically VPN), and mDNS must be reachable across that path.

### Practical approach

1. Keep this container on host networking.
2. Connect phone + home network with VPN/subnet routing.
3. Enable mDNS reflection in this container (new in this repo):
   - `ENABLE_MDNS_REFLECTOR=true`
   - `MDNS_ALLOW_INTERFACES=eth0,tailscale0` (example)

> This does not guarantee every VPN/provider will pass AirPlay perfectly, but it is the correct direction for discovery across subnets.

---

## Quick Start

```bash
docker build -t uxplay-web .
docker compose up -d
```

Example `.env`:

```dotenv
AIRPLAY_NAME=UxPlay-Web
ENABLE_MDNS_REFLECTOR=true
MDNS_ALLOW_INTERFACES=eth0,tailscale0
```

### If you insist on proxying to `3001` (self-signed HTTPS upstream)

## docker-compose.yaml

This repo now focuses only on `uxplay-web` service (no bundled Caddy). You can continue using your own external Caddy server separately.

> Note: `tls_insecure_skip_verify` weakens security and should be avoided when possible. Port `3000` behind trusted LAN/VPN is usually cleaner.

## ⚙️ Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `DOMAIN` | _required_ | Public domain served by Caddy (e.g., `yourname.duckdns.org`). |
| `DUCKDNS_TOKEN` | _required_ | DuckDNS API token used by Caddy DNS-01 challenge. |
| `AIRPLAY_NAME` | `UxPlay-Web` | Name shown in iOS/macOS Screen Mirroring list. |
| `CUSTOM_PORT` | `3000` | Selkies HTTP port used by reverse proxy. |
| `CUSTOM_HTTPS_PORT` | `3001` | Selkies self-signed HTTPS port for direct LAN fallback. |
| `HARDEN_OPENBOX` | `true` | Selkies security setting. |
| `HARDEN_DESKTOP` | `true` | Selkies security setting. |

---

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `AIRPLAY_NAME` | `UxPlay-Web` | Name shown in iOS Screen Mirroring list. |
| `CUSTOM_PORT` | `3000` | Selkies HTTP port (good for reverse proxy/browser access). |
| `CUSTOM_HTTPS_PORT` | `3001` | Selkies self-signed HTTPS port. |
| `ENABLE_MDNS_REFLECTOR` | `false` | Enables Avahi reflector for cross-interface mDNS relay. |
| `MDNS_ALLOW_INTERFACES` | _(empty)_ | Optional comma-separated interface allow-list, e.g. `eth0,tailscale0`. |

---

## Network Ports (host network mode)

- UDP `5353` mDNS (discovery)
- TCP `7000`, `7001`, `7100` AirPlay control/media
- UDP `5000-5005` media streams
- TCP `3000`/`3001` browser viewing endpoints

---

## Troubleshooting

- **AirPlay works on LAN but not off-LAN:** expected unless VPN + mDNS relay/reflector are in place.
- **Domain works in browser but not in iOS Screen Mirroring list:** expected; AirPlay discovery is not domain-based.
- **High CPU/stutter:** map `/dev/dri` for GPU acceleration.
