#!/usr/bin/env bash
# raid_replace.sh - replace a faulty disk in an MD RAID array
#
# Usage: sudo bash raid_replace.sh <md_device> <old_disk> <new_disk>
# Example: sudo bash raid_replace.sh /dev/md0 /dev/sata5p1 /dev/sata6p1

set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "run as root" >&2; exit 1; }
[[ $# -ne 3 ]]    && { echo "usage: $0 <md> <old_disk> <new_disk>" >&2; exit 1; }

MD="$1"
OLD="$2"
NEW="$3"

echo "[1/3] set $OLD as faulty in $MD"
mdadm -f "$MD" "$OLD"

echo "[2/3] remove $OLD from $MD"
mdadm -r "$MD" "$OLD"

echo "[3/3] add $NEW to $MD"
mdadm -a "$MD" "$NEW"

echo ""
echo "done. check rebuild progress:"
echo "  watch cat /proc/mdstat"
