# OpenClash STUN Direct

## Overview

This module configures direct‑connect rules for STUN traffic in OpenClash so that STUN flows bypass the proxy, avoiding P2P connection issues.

## Features

- Direct rule for STUN port 3478
- TCP and UDP supported
- Compatible with nftables and iptables firewalls
- Auto‑detect firewall type and apply rules accordingly

## STUN protocol

STUN (Session Traversal Utilities for NAT) is used for:
- NAT traversal and type detection
- Establishing P2P connections
- WebRTC applications
- Real‑time communication optimization

## How it works

### nftables (fw4)
- Add RETURN rules for TCP/UDP 3478 in the `openclash` table
- Add rules in `openclash_mangle`
- Add output rules in `openclash_output`

### iptables (legacy)
- Add RETURN rules in mangle table `openclash`
- Add rules in nat table `openclash` and `openclash_output`
- Ensure STUN traffic bypasses proxy handling

## Technical traits

- Auto‑detect firewall type (fw4/iptables)
- Dual‑stack (IPv4/IPv6) support
- Highest priority (position 0 or `-I 1`)
- Comprehensive logging support

## Files

- `files/etc/openclash/custom/openclash_custom_firewall_rules.sh` — Custom firewall script

## Scenarios

For P2P‑intensive apps:
- WebRTC video calls
- P2P gaming
- Peer‑to‑peer file transfer
- Real‑time audio/video

## Notes

- Requires OpenClash to be installed and running
- STUN traffic goes direct, not proxied
- Useful when real IP is needed for NAT detection
