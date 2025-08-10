# System Tools

## Overview

This module installs common network diagnostics and system management tools on OpenWrt, providing comprehensive admin and troubleshooting capabilities.

## Features

- Network diagnostics and testing
- System administration and maintenance
- Text editing and processing
- Connection tracking and monitoring

## Included tools

### Networking
- **bind-dig** — DNS query and diagnostics
  - Resolve domain names
  - Query DNS servers
  - Connectivity diagnostics

- **wget** — Command‑line downloader
  - HTTP/HTTPS file downloads
  - Resume support
  - Batch downloads

- **curl** — Multi‑protocol data transfer
  - HTTP/HTTPS/FTP and more
  - API testing
  - Data transfer and debugging

### Network diagnostics
- **nping** — Packet generator
  - Custom packet crafting
  - Latency testing
  - Port reachability checks

- **tcpdump** — Packet analyzer
  - Live packet capture
  - Traffic analysis
  - Protocol debugging

### System utilities
- **vim-full** — Full‑featured text editor
  - Syntax highlighting
  - Multiple editing modes
  - Plugin ecosystem

- **diffutils** — File comparison suite
  - diff — text file differences
  - cmp — binary diff
  - Config comparison

- **conntrack** — Connection tracking
  - Monitor connection states
  - Track NAT connections
  - Manage firewall connections

## Config files

- `packages` — Package list

## Use cases

### Network diagnostics
- Connectivity testing
- DNS troubleshooting
- Performance analysis
- Protocol debugging

### System administration
- Edit configuration files
- Maintenance scripts
- File download and transfer
- Log analysis

### Troubleshooting
- Network issue diagnosis
- Service health checks
- Performance monitoring
- Security auditing

## Examples

```bash
# DNS lookup
dig google.com

# Download a file
wget https://example.com/file.tar.gz

# Port testing
nping -p 80 target.com

# Packet capture
tcpdump -i eth0 host 192.168.1.1

# Connection tracking
conntrack -L
```

## Notes

- This toolset consumes some storage space
- Install only what you need
- Some tools require root privileges
- Learn the basics of each tool for best results
