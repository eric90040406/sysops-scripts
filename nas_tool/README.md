# nas_tool

Scripts for NAS hardware inspection, storage management, and system diagnostics.

```
nas_tool/
├── disk_info/
│   ├── disk_info.sh      # List all disks: type, capacity, serial, MD membership
│   └── README.md
├── check_stress/
│   ├── check_stress.sh   # Scan system logs for crash/error indicators
│   └── README.md
└── cheatsheet.md         # Quick reference for common NAS commands
```

## Scripts

| Script | Description |
|--------|-------------|
| [disk_info](disk_info/) | Display disk inventory with type, capacity, serial number, and MD RAID membership |
| [check_stress](check_stress/) | Scan logs for panic, DENIED, core dumps, segfault, and call traces — outputs PASS/FAIL |
