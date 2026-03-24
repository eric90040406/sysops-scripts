# nas/ — NAS Hardware Utilities

Scripts for inspecting and managing NAS storage hardware.

---

## disk_info.sh

Prints a table of every block device on the host: disk type, capacity, serial number, and which MD RAID array it belongs to.

### Sample output

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

### Requirements

| Package         | Purpose                            |
|-----------------|------------------------------------|
| `smartmontools` | Read serial number and disk model  |
| `mdadm`         | Parse MD RAID membership           |
| `util-linux`    | `lsblk` — capacity and device list |

```bash
sudo apt install smartmontools mdadm util-linux
```

### Usage

```bash
sudo bash disk_info.sh        # plain table + /proc/mdstat
sudo bash disk_info.sh -j     # JSON output
```
