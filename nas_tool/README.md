# nas_tool

Scripts for NAS hardware inspection, storage management, and automated testing.

```
nas_tool/
├── disk_info/
│   ├── disk_info.sh            # List all disks: type, capacity, serial, MD membership
│   └── README.md
├── check_stress/
│   ├── check_stress.sh         # Scan system logs for crash/error indicators
│   └── README.md
├── pool_lifecycle_test/
│   ├── pool_lifecycle_test.sh  # Create/delete pool+volume N times, verify MD5
│   └── README.md
├── hotswap_test/
│   ├── hotswap_test.sh         # Simulate disk pull, verify RAID rebuild
│   └── README.md
└── cheatsheet.md               # Quick reference for common NAS commands
```

## Scripts

| Script | Description |
|--------|-------------|
| [disk_info](disk_info/) | Display disk inventory: type, capacity, serial number, MD RAID membership |
| [check_stress](check_stress/) | Scan logs for panic, DENIED, core dumps, segfault, call traces — outputs PASS/FAIL |
| [pool_lifecycle_test](pool_lifecycle_test/) | Create pool+volume, write and verify data, tear down — repeat N times |
| [hotswap_test](hotswap_test/) | Deactivate a disk, confirm degraded state, re-activate, verify rebuild and mismatch_cnt |
