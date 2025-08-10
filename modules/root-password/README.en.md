# Root Password Configuration

## Overview

This module sets the root password for OpenWrt, providing secure administrator access control.

## Features

- Set the root login password
- Support random password generation
- Enhance system security
- Prevent unauthorized access

## Environment variables

### Password
- `ROOT_PASSWORD` — root password
  - `random`: generate a secure random password
  - any other value: use the specified password

## Options

### Auto‑generate (recommended)
```bash
ROOT_PASSWORD=random
```
The system will generate a secure random password.

### Custom password
```bash
ROOT_PASSWORD=your_secure_password
```
Use your own strong password.

## Security advice

### Password policy
- 8+ characters
- Mix of upper/lowercase, digits, symbols
- Avoid common passwords
- Rotate regularly

### Best practices
- Prefer SSH key authentication
- Disable password login (after keys are configured)
- Enable firewall protection
- Restrict SSH source IPs

## Files

- `example.env` — Environment variable example
- `files/etc/uci-defaults/92-system` — System config script

## Scenarios

For secure system access:
- Production deployments
- Remote administration
- Multi‑user environments
- Compliance requirements

## Notes

- Keep the password safe
- Prefer combining with SSH keys
- Avoid sending passwords over insecure networks
- Review security logs regularly
