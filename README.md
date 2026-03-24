# sysops-scripts

A personal collection of system administration scripts, organized by category.

```
sysops-scripts/
└── nas_tool/
    ├── disk_info/              # Disk inventory: type, capacity, serial, MD membership
    ├── check_stress/           # Log scanner: panic / DENIED / core / segfault
    ├── pool_lifecycle_test/    # Automated pool+volume create/delete test
    ├── hotswap_test/           # Disk hot-swap simulation and rebuild verification
    └── cheatsheet.md           # Quick reference for common NAS commands
```

## Categories

| Folder | Description | Link |
|--------|-------------|------|
| `nas_tool/` | NAS hardware inspection and storage automation | [View on GitHub](https://github.com/eric90040406/sysops-scripts/tree/main/nas_tool) |

## Requirements

- OS: Linux (Debian / Ubuntu) / Synology DSM
- Shell: Bash 4.0+
- Most scripts require `root`
