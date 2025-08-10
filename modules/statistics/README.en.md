# System Statistics

## Overview

This module adds system monitoring to OpenWrt, providing performance data collection and a web UI.

## Features

- Performance data collection
- Temperature monitoring and display
- Web UI charts
- Hardware IRQ statistics
- Sensor data collection

## Packages

### UI components
- `luci-app-temp-status` — Temperature status
- `luci-app-statistics` — Statistics UI

### Data collectors
- `collectd-mod-irq` — IRQ stats
- `collectd-mod-sensors` — Sensor data

## Capabilities

### Temperature
- Real‑time temperature
- Historical records
- Threshold alerts
- Multiple sensors supported

### System stats
- CPU usage
- Memory usage
- Network traffic
- Storage monitoring
- System load

### Hardware
- IRQ frequency
- Sensor metrics
- Voltage/current
- Fan speed

## Web UI

Accessible via LuCI:
- System → Administration → Statistics
- Status → Temperature
- Real‑time charts
- Historical queries

## Files

- `packages` — Package list
- `files/etc/uci-defaults/99-statistics` — Stats config script

## Scenarios

For systems requiring monitoring:
- Performance tuning
- Hardware health
- Fault diagnosis
- Resource accounting
- Device maintenance

## Notes

- Collectors use system resources
- Requires hardware sensors
- Historical data needs storage
- Some features are platform‑dependent
