# OPKG Mirror Configuration

## Overview

This module configures OpenWrt's package manager (opkg) to use Mainland China mirrors for better download speed and stability.

## Features

- Replace default feeds with domestic mirrors
- Speed up package downloads
- Improve connectivity stability
- Support ImmortalWrt project

## Mirror rules

### Replacements
- `https://downloads.immortalwrt.org` → `https://mirror.nju.edu.cn/immortalwrt`
- `https://mirrors.vsean.net/openwrt` → `https://mirror.nju.edu.cn/immortalwrt`

### Mirror highlights
- **Nanjing University mirror** — reliable education network mirror
- High bandwidth
- Regular sync
- Good nationwide access

## How it works

1. Use `sed` to replace URLs in the config
2. Backup the original file (suffix .bak)
3. Modify `/etc/opkg/distfeeds.conf`
4. Apply on first boot automatically

## Files

- `files/etc/uci-defaults/99-opkg` — Mirror replacement script

## Effects

- Significant download speed boost
- Fewer timeouts and failures
- Better `opkg update` experience
- Suitable for Mainland China networks

## Notes

- Only for ImmortalWrt
- The original file is backed up automatically
- Minor delay due to mirror sync
- You can switch to other mirrors as needed
