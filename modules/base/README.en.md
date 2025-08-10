# Base Packages

## Overview

This module provides the base package set for OpenWrt, including the web UI, utilities, and essential system components.

## Features

- Install core system components and tools
- Configure the LuCI web interface
- Provide Simplified Chinese language support
- Adjust package list based on OpenWrt version

## Packages

### Core
- `zoneinfo-all` — Time zone data
- `luci` — LuCI web interface
- `luci-compat` — LuCI compatibility layer
- `luci-lib-ipkg` — Package management library
- `dnsmasq-full` — Full‑featured DNS/DHCP (replaces minimal dnsmasq)
- `openssl-util` — OpenSSL utilities

### Chinese localization
- `luci-i18n-base-zh-cn` — Base UI translation
- `luci-i18n-firewall-zh-cn` — Firewall UI translation

### Version‑specific
- OpenWrt 24.10 or snapshots: `luci-i18n-package-manager-zh-cn`
- Other versions: `luci-i18n-opkg-zh-cn`

## Version detection

Environment variables:
- `OPENWRT_VERSION` — OpenWrt version
- `IS_SNAPSHOT_BUILD` — Whether this is a snapshot build

## Files

- `packages` — Script to generate package list dynamically

## Usage

Use as the foundational module for OpenWrt systems requiring a full web management interface.
