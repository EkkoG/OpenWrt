# PassWall

## Overview

This module installs and configures the PassWall proxy, providing a powerful solution with intelligent routing.

## Features

- Install PassWall and related components
- Add dedicated feeds and GPG key
- Configure subscription support
- Intelligent routing and split‑tunneling rules

## Environment variables

### Required
- `PASSWALL_SUBSCRIBE_URL` — PassWall subscription URL

Example:
```bash
PASSWALL_SUBSCRIBE_URL=https://passwall.example.com/subscribe
```

## Feeds

### GPG key
- Key file: `0abda65a492b4887`
- Verifies package integrity and security

### Repositories
Added via `post-files.sh`:
- PassWall feed
- Related dependency feeds

## Highlights

### Protocols
- Multiple mainstream proxy protocols
- Flexible node management
- Auto subscription updates
- Node latency tests

### Smart routing
- Domain‑based rules
- GeoIP based routing
- Custom rules
- Ad blocking

### System integration
- Transparent proxy mode
- Anti‑pollution DNS
- IPv6 support
- Autostart on boot

## Files

- `example.env` — Environment example
- `packages` — Package list
- `post-files.sh` — Post processing script
- `files/etc/opkg/keys/0abda65a492b4887` — GPG key
- `files/etc/uci-defaults/90-passwall` — UCI defaults

## Dependencies

- Depends on: `add-feed-base` module
- Integrates with firewall and networking

## Scenarios

For proxy needs:
- Access control bypass
- Network acceleration
- Geo‑restricted content
- Enterprise proxying
- Smart split‑tunneling

## Notes

- Requires a valid subscription
- Follow local laws and regulations
- Tune routing rules as needed
- Keep subscriptions and rules up‑to‑date
