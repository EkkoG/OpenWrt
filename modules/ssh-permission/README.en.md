# SSH Permission Configuration

## Overview

This module fixes the permissions of the SSH authorized keys file to ensure the safety and correctness of public key authentication.

## Features

- Correct permissions on the authorized keys file
- Ensure public key authentication functions properly
- Improve system security
- Meet SSH security requirements

## How it works

### Permissions
- Check if `/etc/dropbear/authorized_keys` exists
- Set file mode to 644 (rw-r--r--)
- Ensure the SSH service can read the keys

### Rationale
- 644 grants read/write to owner and read‑only to others
- Meets Dropbear/SSH requirements for authorized keys
- Prevents auth failures from overly lax or strict permissions

## Technical notes

### Dropbear SSH
- OpenWrt uses Dropbear by default
- Authorized keys path: `/etc/dropbear/authorized_keys`
- One SSH public key per line

### Permission detail
- `644` (rw-r--r--)
  - Owner: read/write
  - Group: read‑only
  - Others: read‑only

## Files

- `files/etc/uci-defaults/99-ssh` — SSH permission script

## Scenarios

For environments using SSH keys:
- Passwordless SSH login
- Automated deployments
- Secure remote admin
- CI/CD integration

## Notes

- Runs only if the file exists
- Does not create missing files
- Applied on first boot
- Use with SSH public keys
