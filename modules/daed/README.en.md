# Daed Proxy

## Overview

This module installs and configures the Daed proxy (based on the dae project), providing a high‑performance networking solution.

## Features

- Install Daed core components
- Configure LuCI web UI
- Integrate geolocation databases
- Provide virtual network interface support

## Packages

### Core
- `daed-geoip` — GeoIP database
- `daed-geosite` — GeoSite classifications
- `luci-app-daed` — LuCI web UI for Daed
- `kmod-veth` — Virtual Ethernet kernel module

### Feeds
Added via `add-feed-base`:
- `dae` — Daed feed
- `geodata/MetaCubeX` — MetaCubeX geodata

## Technical highlights

- High performance with eBPF
- Multiple proxy protocols
- Built‑in smart routing rules
- Low latency and high throughput
- Geo and domain‑based split‑tunneling

## Files

- `packages` — Package list
- `post-files.sh` — Configure feeds and geodata

## Dependencies

- Depends on: `add-feed-base` module
- Recommended with other network modules

## Scenarios

For high‑performance proxying:
- Smart routing
- Acceleration
- Access control
- Traffic analysis
