# LAN Configuration

## Overview

This module configures the LAN interface IP address on OpenWrt and supports custom subnets.

## Features

- Custom LAN IP address
- Flexible via environment variables
- Apply network config automatically
- Support different subnets

## Parameters

### Environment
- `LAN_IP` — LAN interface IP (default: 192.168.2.1)

## Example

Set in `example.env`:
```
LAN_IP=192.168.2.1
```

## How it works

1. Read `LAN_IP` from environment
2. Update network config using UCI
3. Set `network.lan.ipaddr`
4. Commit changes

## Files

- `example.env` — Example config
- `files/etc/uci-defaults/89-lan` — UCI script

## Scenarios

When changing the default LAN subnet:
- Avoid IP conflicts
- Fit specific environments
- Enterprise integration
- Multi‑router deployments

## Notes

- Ensure the IP does not conflict with other devices
- Update the DHCP pool accordingly
- Use private address ranges
