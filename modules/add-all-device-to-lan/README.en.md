# Add All Devices to LAN Bridge

## Overview

This module automatically adds all Ethernet devices (except the WAN device) to the LAN bridge.

## Features

- Auto‑detect all Ethernet interfaces
- Exclude the WAN interface to avoid conflicts
- Append remaining devices to LAN bridge ports
- Restart networking to apply changes

## How it works

1. Determine the currently configured WAN device
2. Enumerate system Ethernet devices (eth0, eth1, …)
3. Exclude the WAN device from the list
4. Clear existing bridge port configuration
5. Add each remaining device to the LAN bridge
6. Commit UCI and restart network services

## Files

- `files/etc/uci-defaults/99-add-all-device-to-lan` — Auto‑config script

## Scenarios

Useful when bridging multiple ports into LAN, for example:
- Multi‑port router setups
- Switch mode configuration
- Expanding LAN port count
