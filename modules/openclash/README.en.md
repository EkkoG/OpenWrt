# OpenClash

## Overview

This module installs and configures OpenClash, providing a full Clash‑based proxy solution with a web UI.

## Features

- Install OpenClash and components
- Configure subscription and DNS servers
- Enable IPv6 and Meta core
- Auto‑update geolocation databases
- Custom fallback filter rules

## Packages

Added via `post-files.sh` feeds:
- OpenClash core components
- Dependencies
- Web management UI

## Environment variables

### Required
- `CLASH_CONFIG_URL` — Clash configuration subscription URL
- `DASHBOARD_PASSWORD` — Admin panel password (optional; auto‑generated if not set)

## Key settings

### DNS
- Primary: 119.29.29.29 (UDP)
- Secondary: 8.8.8.8 (TCP)
- IPv6 DNS supported
- Disable default DNS appending

### Core
- Use Clash Meta core
- Mode: redir-host
- Enable IPv6 and proxying
- China route optimization

### Automation
- GeoIP database: daily at 04:00
- GeoSite database: daily at 00:00
- China routes: daily at 03:00
- Config: auto‑update supported
- System reboot: daily at 03:00

### Advanced
- Respect rules
- Custom fallback filter
- Disable UDP QUIC
- Disable process‑finder mode

## Files

- `example.env` — Environment example
- `packages` — Package list
- `post-files.sh` — Post processing
- `files/etc/uci-defaults/90-openclash` — UCI defaults
- `files/etc/openclash/custom/openclash_custom_fallback_filter.yaml` — Custom filter rules

## Dependencies

- Depends on: `add-feed-base` module
- Recommended with other networking modules

## Scenarios

For flexible proxy setups:
- Smart split‑tunneling
- Global acceleration
- Access control
- Multi‑protocol support
