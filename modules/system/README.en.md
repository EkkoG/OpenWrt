# System Configuration

## Overview

This module configures basic OpenWrt system settings, including time zone, language, and log levels.

## Features

- Set system time zone to China Standard Time
- Configure LuCI interface language to Simplified Chinese
- Adjust system log levels
- Optimize localization settings

## System settings

### Time zone
- **Zonename**: `Asia/Shanghai`
- **Offset**: `CST-8` (UTC+8)
- Daylight saving handled automatically

### Language
- **LuCI language**: `zh_cn` (Simplified Chinese)
- Full Chinese UI experience

### Logging
- **Cron log level**: `8` (debug)
- **Console log level**: `7` (info)

## UCI snippets

### Time zone
```bash
set system.@system[0].zonename='Asia/Shanghai'
set system.@system[0].timezone='CST-8'
```

### UI localization
```bash
set luci.main.lang='zh_cn'
```

### Log levels
```bash
set system.@system[0].cronloglevel='8'
set system.@system[0].conloglevel='7'
```

## Log level guide

- **Level 8**: Debug, most verbose
- **Level 7**: Info, important events
- Higher numbers mean more verbosity

## Files

- `files/etc/uci-defaults/91-system` — UCI system config script

## Effects

- System time displayed in Beijing time
- Web admin in Chinese
- Suitable for Mainland China users
- Helpful for maintenance and troubleshooting

## Scenarios

For localized OpenWrt deployments:
- Home routers
- Enterprise devices
- Learning and lab environments
- Custom localized builds

## Notes

- Applied on first boot
- Persistent across reboots
- Adjustable to other time zones
- Verbose logs consume storage
