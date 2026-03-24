# sysops-scripts

A personal collection of operational shell scripts for system administration tasks — NAS management, automation helpers, and infrastructure utilities.

> Scripts are written for Linux (Debian/Ubuntu target) and designed to be run directly on the host or via SSH without any external framework dependency.

---

## Repository structure

```
sysops-scripts/
├── nas/                    # NAS hardware & storage scripts
│   ├── disk_info.sh        # Disk inventory: capacity, SN, MD RAID membership
│   └── README.md
└── auto_script/            # Scheduled / automation helpers (WIP)
```

---

## Scripts at a glance

### `nas/disk_info.sh` — NAS Disk Inventory

Prints a formatted table (or JSON) of every block device on the machine:

| Column | Source |
|--------|--------|
| Device path | `lsblk` |
| Type (HDD / SSD) | `/sys/block/*/queue/rotational` |
| Model | `smartctl -i` |
| Capacity | `lsblk` |
| Serial Number | `smartctl -i` |
| MD RAID array | `/proc/mdstat` |

```bash
sudo bash nas/disk_info.sh          # human-readable table
sudo bash nas/disk_info.sh --json   # machine-readable JSON
```

See [nas/README.md](nas/README.md) for full documentation.

---

## General requirements

- **OS**: Linux (tested on Debian 11/12, Ubuntu 22.04)
- **Shell**: Bash 4.0+
- **Privileges**: Most scripts require `root` / `sudo`
- **Dependencies**: listed per-script in the respective README

---

## Contributing / extending

1. Create a subdirectory for the relevant category (e.g. `network/`, `backup/`).
2. Add the script with a header block documenting usage, options, and exit codes.
3. Add a `README.md` in that subdirectory.
4. Update the table above.

---

## License

MIT — free to use and adapt. Attribution appreciated but not required.
