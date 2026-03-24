# nas/

NAS 相關的所有 script。

```
nas/
├── disk_info.sh    # 查詢硬碟容量、序號、所屬 MD RAID
└── ...
```

---

## disk_info.sh

列出所有 block device 的資訊：類型、容量、序號、所屬 MD RAID。

**用法**

```bash
sudo bash disk_info.sh      # 表格輸出
sudo bash disk_info.sh -j   # JSON 輸出
```

**輸出範例**

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

**相依套件**

```bash
sudo apt install smartmontools mdadm util-linux
```

| 套件 | 用途 |
|------|------|
| `smartmontools` | 讀取序號與型號 |
| `mdadm` | 解析 MD RAID 成員 |
| `util-linux` | `lsblk` 取得容量與裝置清單 |
