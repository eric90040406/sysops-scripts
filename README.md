# sysops-scripts

A personal collection of system administration scripts for NAS hardware inspection, storage management, and automated testing.

## NAS Tool

Scripts for Synology DSM / Linux MD RAID environments. Most require `root`.

| Script | What it does | Usage |
|--------|-------------|-------|
| [disk_info](https://github.com/eric90040406/nas-toolkit/tree/main/nas_tool/disk_info) | List all disks: type, capacity, serial number, MD RAID membership | `sudo bash disk_info.sh [-j]` |
| [check_stress](https://github.com/eric90040406/nas-toolkit/tree/main/nas_tool/check_stress) | Scan system logs for panic, DENIED, core dumps, segfault — outputs PASS/FAIL | `sudo bash check_stress.sh [-o file]` |
| [pool_lifecycle_test](https://github.com/eric90040406/nas-toolkit/tree/main/nas_tool/pool_lifecycle_test) | Create pool+volume, write and verify data (MD5), tear down — repeat N times | `sudo bash pool_lifecycle_test.sh -d <disk> [-n <iter>] [-s <mb>]` |
| [hotswap_test](https://github.com/eric90040406/nas-toolkit/tree/main/nas_tool/hotswap_test) | Deactivate a disk, confirm degraded state, re-activate, verify rebuild and mismatch_cnt | `sudo bash hotswap_test.sh -m <md> -d <disk> [-t <sec>]` |

[Cheatsheet — common NAS commands](https://github.com/eric90040406/nas-toolkit/blob/main/nas_tool/cheatsheet.md)

## Requirements

- OS: Linux (Debian / Ubuntu) / Synology DSM
- Shell: Bash 4.0+
- Dependencies: `smartctl`, `lsblk`, `mdadm`, `synowebapi`, `synostgdisk`
