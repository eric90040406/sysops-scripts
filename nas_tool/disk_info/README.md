# disk_info

Displays a summary table of all block devices on the host, including disk type, capacity, serial number, and MD RAID membership.

## Usage

```bash
sudo bash disk_info.sh          # plain table output
sudo bash disk_info.sh -j       # JSON output
```

## Output

```
DEVICE      TYPE  MODEL                               SIZE      SERIAL                MD
----------  ----  ----------------------------------  --------  --------------------  --------
/dev/sda    HDD   WDC WD40EFRX-68N32N0               3.7T      WD-WCC7K3XXXXXX       /dev/md0,/dev/md1
/dev/sdb    HDD   WDC WD40EFRX-68N32N0               3.7T      WD-WCC7K3YYYYYY       /dev/md0
/dev/sdc    SSD   Samsung SSD 870 EVO 500GB           465.8G    S59WNXXXXX            none
/dev/nvme0  SSD   Samsung SSD 980 PRO 1TB             931.5G    S5GXNR0RXXXXXX        /dev/md2

Personalities : [raid5]
md0 : active raid5 sda[0] sdb[1]
...
```

## How it works

| Step | Source |
|------|--------|
| Device discovery | `lsblk -dno NAME` |
| Disk type (HDD/SSD) | `/sys/block/<dev>/queue/rotational` |
| Model & serial number | `smartctl -i` |
| MD RAID membership | `/proc/mdstat` (parsed once at startup) |

## Requirements

```bash
sudo apt install smartmontools mdadm util-linux
```

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Not run as root |
| `2` | Required dependency missing |
