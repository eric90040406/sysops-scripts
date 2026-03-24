# sysops-scripts

個人用的系統管理 script 集合，依功能分資料夾存放。

---

## 結構

```
sysops-scripts/
└── nas_tool/
    ├── disk_info.sh      # 查詢硬碟容量、序號、所屬 MD RAID
    ├── check_stress.sh   # 掃描系統 log（panic / DENIED / core / segfault）
    ├── raid_replace.sh   # MD RAID 換硬碟流程
    └── cheatsheet.md     # 常用指令參考
```

| 資料夾 | 說明 | 連結 |
|--------|------|------|
| `nas_tool/` | NAS 相關 script | [前往 GitHub](https://github.com/eric90040406/sysops-scripts/tree/main/nas_tool) |

---

## 環境需求

- OS: Linux (Ubuntu)
- Shell: Bash 4.0+
- 大部分 script 需要 `root` 權限
