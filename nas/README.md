# nas/ — NAS Hardware Utilities

Scripts for inspecting and managing NAS storage hardware.

---

## disk_info.sh

Prints a consolidated inventory of every block device on the host, showing disk type, capacity, serial number, and which MD RAID array (if any) the disk belongs to.

### Sample output

```
NAS Disk Inventory  —  nas01  —  2026-03-24 10:00:00

DEVICE     TYPE  MODEL                               SIZE     SERIAL                 MD ARRAY
---------- ----- ----------------------------------- -------- ---------------------- --------------------
/dev/sda   HDD   WDC WD40EFRX-68N32N0               3.7T     WD-WCC7K3XXXXXX        /dev/md0,/dev/md1
/dev/sdb   HDD   WDC WD40EFRX-68N32N0               3.7T     WD-WCC7K3YYYYYY        /dev/md0
/dev/sdc   SSD   Samsung SSD 870 EVO 500GB           465.8G   S59WNXXXXX             none
/dev/nvme0 SSD   Samsung SSD 980 PRO 1TB             931.5G   S5GXNR0RXXXXXX         /dev/md2

MD RAID status (/proc/mdstat):
...
```

### Requirements

| Package         | Purpose                          |
|-----------------|----------------------------------|
| `smartmontools` | Read serial number and disk model |
| `mdadm`         | Parse MD RAID membership         |
| `util-linux`    | `lsblk` — capacity and device list |

Install on Debian/Ubuntu:

```bash
sudo apt install smartmontools mdadm util-linux
```

### Usage

```bash
# Basic table output
sudo bash disk_info.sh

# JSON (pipe to jq, log files, etc.)
sudo bash disk_info.sh --json

# Table only, no header / mdstat footer (useful in cron)
sudo bash disk_info.sh --quiet

# Help
bash disk_info.sh --help
```

### Options

| Flag | Description |
|------|-------------|
| `-h`, `--help`  | Show help and exit |
| `-j`, `--json`  | Output as a JSON array |
| `-q`, `--quiet` | Suppress header and `/proc/mdstat` footer |

### How it works

1. **Device discovery** — `lsblk -dno NAME` lists all physical block devices (filters `sd*`, `nvme*`, `hd*`).
2. **Disk type** — reads `/sys/block/<dev>/queue/rotational` (`0` = SSD, `1` = HDD).
3. **Serial number & model** — `smartctl -i` via `smartmontools`.
4. **MD membership** — parses `/proc/mdstat` once at startup and builds an in-memory lookup table, so no extra `mdadm` call per disk.

### Exit codes

| Code | Meaning |
|------|---------|
| `0`  | Success |
| `1`  | Not run as root |
| `2`  | Required dependency missing |
