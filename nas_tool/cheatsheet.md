# NAS Cheatsheet

常用指令參考，依功能分類。`[dev]` 代表需替換成實際裝置名稱。

---

## 硬碟資訊

| 指令 | 說明 |
|------|------|
| `dmesg \| grep -i sata` | 查詢 HDD slot 速度 |
| `synodisk --enum` | 磁碟對應情況 |
| `synodiskport -eunit` | 查詢 Eunit disk port |
| `synoenc --enum` | 查詢 Eunit 數量 |
| `cat /proc/sys/kernel/syno_serial` | 查詢機器 SN |
| `nvme id-ctrl -H /dev/nvme0 \| grep -i 'write unc'` | 確認是否支援 Write Unc |
| `cat /run/synostorage/disks/[dev]/bad_sec_ct` | 查詢硬碟壞軌數 |
| `dd if=/dev/[dev] of=/dev/null bs=512 skip=[offset] count=8 iflag=direct` | 直接讀取硬碟確認壞軌 |

---

## MD RAID 狀態

| 指令 | 說明 |
|------|------|
| `cat /proc/mdstat` | 查看所有 MD 狀態 |
| `cat /sys/block/md0/md/mismatch_cnt` | 查詢 mismatch count |
| `vgs` / `lvs` | 查詢 SSD cache / MD 狀態 |
| `cat /usr/syno/etc/flashcache.conf \| grep Version` | 查詢 cache 版本 |
| `echo 4096 > /sys/block/md2/md/stripe_cache_size` | 調整 stripe cache 大小 |
| `synoraid5stat -c /dev/md2` | 清除 stripe statistics 紀錄 |

## MD RAID 操作

| 指令 | 說明 |
|------|------|
| `mdadm -f /dev/md0 /dev/[dev]` | 將硬碟標為 faulty |
| `mdadm -r /dev/md0 /dev/[dev]` | 從 md0 移除硬碟 |
| `mdadm -a /dev/md0 /dev/[dev]` | 將硬碟加入 md0 |
| `mdadm --stop /dev/md5` | 停止 md5（需先 unmount volume）|

---

## Volume / Pool 管理

| 指令 | 說明 |
|------|------|
| `df -h /` | 確認 root 是否被塞滿 |
| `du -sh /* --exclude=volume1 --exclude=volume2 \| sort -hr` | 查看各目錄大小 |
| `mount \| grep /volume1` | 確認 volume 掛載在 Btrfs |
| `btrfs filesystem show` | 確認 volume 對應 UUID |
| `synostgvolume --unmount -p /volume1` | 踢掉單個 volume |
| `synospace --start-all-spaces` | 掛起所有 space |
| `umount /volume1/ && mdadm --stop /dev/md5` | 先 unmount 再停 MD |

**建立 Pool（一步搞定）**

```bash
synowebapi --exec \
  allocate_size="\"3804160\"" \
  api="SYNO.Storage.CGI.Volume" \
  atime_opt="\"relatime\"" \
  blocking="false" \
  desc="\"\"" \
  device_type="\"basic\"" \
  diskGroups="[{\"isNew\":true,\"raidPath\":\"new_raid\",\"disks\":[\"sata4\"]}]" \
  disk_id="[\"sata4\"]" \
  enable_dedupe="false" \
  force="false" \
  fs_type="\"btrfs\"" \
  is_disk_check="false" \
  is_pool_child="true" \
  limitNum="\"24\"" \
  method="create" \
  pool_path="\"\"" \
  spare_disk_count="\"0\"" \
  version="1" \
  vol_desc="\"\""
```

---

## iSCSI

| 指令 | 說明 |
|------|------|
| `iscsiadm -m discovery -t sendtargets -p [IP]:3260` | 發現 iSCSI 目標 |
| `iscsiadm -m node -T [iqn] -p [IP] --login` | 登入 |
| `iscsiadm -m node -T [iqn] -p [IP] --logout` | 登出 |
| `iscsiadm -m node --logoutall=all` | 清除所有 iSCSI 連線 |
| `synoiscsiwebapi l l` | 查詢 LUN UUID |
| `synoiscsiwebapi l lm $LUN_NAME` | 將 LUN 掛載到自己身上 |

**open-iscsi 讓兩台 NAS 互連 LUN**

```bash
sudo systemctl enable iscsid && sudo systemctl start iscsid
sudo iscsiadm -m discovery -t st -p [IP]
sudo iscsiadm -m node -T [iqn] -p [IP] --login
fdisk /dev/iscsi1          # n -> p -> w
mkdir /mnt/iscsi_lun
mount /dev/iscsi1 /mnt/iscsi_lun
```

---

## 系統與 Log

| 指令 | 說明 |
|------|------|
| `cat /var/log/scemd.log` | HW behavior log |
| `cat /proc/swaps` | 查看 zRAM（Swap = zRAM + md1） |
| `cat /sys/devices/system/node/node*/cpulist` | 查詢 NUMA 配置 |
| `tail QC1_stress_*-auto/volume1/*_eth{0..1}_*/*1.log` | 查 filecopy log |

---

## 網路

| 指令 | 說明 |
|------|------|
| `cat /proc/net/bonding/bond0` | 查看 Bond 狀態 |
| `synonet --dhcp eth0` | 將 eth0 設回 DHCP |
| `sudo ip route del default via [GW] dev eth1` | 刪掉錯誤的 default route |
| `mount [IP]:/share` | 掛載遠端 NFS share |
| `ssh-keygen -R [NAS_IP]` | SSH 舊金鑰失效時清除 |

---

## Synology 特有工具

| 指令 | 說明 |
|------|------|
| `synostgdisk --disk-deactivate /dev/sdk` | 拔出指定硬碟 |
| `rm /run/synostorage/disks/*/deactivated` | 還原所有拔出/停用的硬碟 |
| `syno_scemd_connector --signal 42` | 停止 DSM 蜂鳴器 |
| `synouser --setpw admin "aaaaaa"` | 設定 admin 密碼 |
| `synoha --local-role` | 查詢 HA 哪台是 active/passive |
| `/usr/syno/synodr/sbin/synodrnode -l` | 列出 DR session list |
| `/usr/syno/synodr/sbin/synodrnode -d ${cred_id}` | 刪除指定 DR session |
| `synosetkeyvalue /etc.defaults/synoinfo.conf [key] [value]` | 修改 synoinfo 設定值 |
| `touch /tmp/installable_check_pass` | 開啟後門機制 |

---

## 壞軌測試與修復

```bash
# 查詢 partition 對應的硬碟 offset
synodataverifier -m /dev/sataXp3 -s 100000 -n 1

# 打壞軌
hdparm --make-bad-sector [sector] --yes-i-know-what-i-am-doing /dev/sataX

# 修復壞軌
hdparm --repair-sector [sector] --yes-i-know-what-i-am-doing /dev/sataX
synostoragecore --raid-repair-bad-sector /dev/mdX /dev/sataXp3 [offset]
```
