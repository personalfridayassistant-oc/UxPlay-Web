# UxPlay-Web

A lightweight **AirPlay Mirroring server** running inside Docker. This project uses [UxPlay](https://github.com/FDH2/UxPlay) for AirPlay 1/2 and the [Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies) for low-latency browser viewing.

> AirPlay discovery/casting still happens on your **local LAN** (mDNS). This repo now includes a Caddy reverse-proxy setup so the browser viewer can be reached securely from outside your network via a domain.

## 🚀 Features

- **AirPlay Mirroring:** Stream iPhone/iPad/Mac to UxPlay.
- **Browser Viewing (LAN + WAN):**
  - Local direct access: `https://<host-ip>:3001` (self-signed)
  - Public access via Caddy + domain: `https://<your-domain>`
- **Reverse-Proxy Ready:** Caddy config included with WebSocket-safe proxying to Selkies on port `3000`.
- **Auto-Discovery:** Avahi/mDNS for seamless AirPlay device discovery.

---

## 🛠️ Prerequisites

- Docker + Docker Compose plugin
- A DNS record for your domain pointing to your public IP
- DuckDNS domain (or compatible setup) and DuckDNS token for DNS-01 ACME validation
- Router/NAT forwarding of port `443` to the Docker host (port `80` is optional with DNS challenge)
- Host networking for UxPlay container (`network_mode: host`) so mDNS works reliably

---

## ⚡ Quick Start (with Caddy)

1. Create `.env` in project root:

```dotenv
DOMAIN=airplaytesla.duckdns.org
DUCKDNS_TOKEN=your-duckdns-token
AIRPLAY_NAME=UxPlay-Web
```

2. Start stack:

```bash
docker compose up -d
```

3. Access:
   - External: `https://${DOMAIN}`
   - Internal fallback: `https://<host-ip>:3001`

4. Start mirroring from iPhone/iPad on the same LAN as the host:
   - Control Center → **Screen Mirroring** → select your `AIRPLAY_NAME`

---

## 📁 Files Added for Reverse Proxy

- `docker-compose.yaml` now includes a `caddy` service.
- `Caddyfile` proxies domain traffic to `http://host.docker.internal:3000` and uses DuckDNS DNS-01 for TLS certificates.
- `Caddy.Dockerfile` builds Caddy with the `duckdns` DNS provider module.

---

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

## 🌐 Network Notes

### AirPlay (LAN-only control/data plane)

These ports must be reachable on your local network:

- UDP `5353` (mDNS)
- TCP `7000`, `7001`, `7100`
- UDP `5000-5005`

### Remote browser viewing (WAN)

- Public `443` → Caddy container (`80` optional)
- Caddy obtains certs via DNS-01 (DuckDNS), avoiding HTTP-01 timeout issues
- Caddy proxies to local Selkies HTTP endpoint (`3000`)

---

## 🔧 Troubleshooting

- **Caddy exits on startup with `unsupported HTTP version: h1`:** remove custom transport version overrides and use the provided `Caddyfile` (Caddy expects `1.1`, `2`, `h2c`, or `3`).
- **`ERR_SSL_PROTOCOL_ERROR` with ACME `Timeout during connect`:** this is usually HTTP-01 validation failing because inbound port `80` is blocked. Use DNS-01 with `DUCKDNS_TOKEN` (configured by default in this repo) and ensure your domain resolves to your public IP.
- **Can open domain but no stream appears:** verify Caddy can reach host gateway (`host.docker.internal`) and that `uxplay-web` is running.
- **AirPlay device not found on iPhone:** iPhone and host must be on same broadcast domain/VLAN; mDNS does not traverse internet.
- **High CPU / stuttering:** pass `/dev/dri` for GPU acceleration.

---

## 📜 Credits

- [UxPlay](https://github.com/FDH2/UxPlay)
- [LinuxServer Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies)
- [GStreamer](https://gstreamer.freedesktop.org/)
- [Avahi](https://www.avahi.org/)
