# nas_tool/

NAS 相關的所有 script 與指令參考。

```
nas_tool/
├── disk_info.sh      # 查詢硬碟容量、序號、所屬 MD RAID
├── check_stress.sh   # 掃描系統 log（panic / DENIED / core / segfault）
├── raid_replace.sh   # MD RAID 換硬碟流程
└── cheatsheet.md     # 常用指令參考
```

---

## disk_info.sh

列出所有 block device：類型、容量、序號、所屬 MD RAID。

```bash
sudo bash disk_info.sh      # 表格輸出
sudo bash disk_info.sh -j   # JSON 輸出
```

**相依套件**

```bash
sudo apt install smartmontools mdadm util-linux
```

---

## check_stress.sh

一鍵掃描系統 log，檢查 panic、AppArmor DENIED、core dump、segfault、call trace。

```bash
sudo bash check_stress.sh
```

---

## raid_replace.sh

引導完成 MD RAID 換硬碟三步驟：set faulty → remove → add。

```bash
sudo bash raid_replace.sh /dev/md0 /dev/sata5p1 /dev/sata6p1
```

---

## cheatsheet.md

其餘常用一行指令，依類別整理：硬碟資訊、RAID 操作、Volume 管理、iSCSI、系統 log、網路、Synology 特有工具、壞軌測試。

→ [cheatsheet.md](https://github.com/eric90040406/sysops-scripts/blob/main/nas_tool/cheatsheet.md)
