# Reject Netflix IPv6

## Overview

This module prevents IPv6 resolution for Netflix‑related domains, forcing IPv4 connections to avoid issues on IPv6 networks.

## Features

- Block IPv6 DNS responses for Netflix domains
- Force IPv4 connections to Netflix services
- Fix geolocation checks in IPv6 environments
- Improve Netflix access stability

## Domains

- `netflix.com` — main domain
- `netflix.net` — network domain
- `nflxext.com` — extension services
- `nflximg.net` — images
- `nflxvideo.net` — video delivery

## How it works

### DNS (dnsmasq)
- Use dnsmasq configuration to block IPv6 answers
- `server=/domain/#` — disable upstream for the domain
- `address=/domain/::` — return empty IPv6 address

### Details
- IPv4 resolution unaffected
- Applies only to listed domains
- Other services keep IPv6 functionality
- Changes are applied automatically to the system

## Files

- `files/etc/dnsmasq.d/netflix.conf` — dnsmasq rules
- `files/etc/uci-defaults/99-reject-netflix-ipv6` — UCI defaults

## Scenarios

Use when:
- Netflix fails on IPv6 networks
- Wrong geolocation detected
- Dual‑stack optimization is needed
- IPv4‑only access is required

## Notes

- Affects all Netflix domains listed
- Only blocks IPv6, IPv4 still works
- You may need to clear DNS cache in browsers
- For scenarios requiring stable IPv4 access
