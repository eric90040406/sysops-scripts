#!/usr/bin/env bash
# disk_info.sh - show NAS disk capacity, serial number, and MD membership
#
# Usage: sudo bash disk_info.sh [-j]
#   -j   output JSON instead of plain text
#
# Requirements: smartmontools, mdadm, util-linux

set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "run as root" >&2; exit 1; }

for cmd in smartctl lsblk mdadm; do
    command -v "$cmd" &>/dev/null || { echo "missing: $cmd" >&2; exit 2; }
done

OPT_JSON=false
[[ "${1:-}" == "-j" ]] && OPT_JSON=true

# build device -> md array map from /proc/mdstat
declare -A MD_MAP
while IFS= read -r line; do
    if [[ "$line" =~ ^(md[0-9]+)[[:space:]]*: ]]; then
        md="${BASH_REMATCH[1]}"
        tmp="$line"
        while [[ "$tmp" =~ ([a-z]+[0-9]*n?[0-9]*)\[[0-9]+\] ]]; do
            dev="${BASH_REMATCH[1]}"
            MD_MAP["$dev"]="${MD_MAP[$dev]+${MD_MAP[$dev]},}/dev/${md}"
            tmp="${tmp#*${BASH_REMATCH[0]}}"
        done
    fi
done < /proc/mdstat

smartctl_field() {
    local dev="$1" field="$2"
    smartctl -i "/dev/${dev}" 2>/dev/null \
        | awk -F: -v key="$field" '$1 ~ key { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }'
}

disk_type() {
    local rot
    rot=$(cat "/sys/block/$1/queue/rotational" 2>/dev/null || echo "?")
    [[ "$rot" == "0" ]] && echo "SSD" || echo "HDD"
}

if $OPT_JSON; then
    first=true
    echo "["
    while IFS= read -r dev; do
        size=$(lsblk -dno SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")
        model=$(smartctl_field "$dev" "Device Model|Model Number"); model=${model:-N/A}
        sn=$(smartctl_field "$dev" "Serial Number|Serial number"); sn=${sn:-N/A}
        type=$(disk_type "$dev")
        md="${MD_MAP[$dev]:-none}"
        $first && first=false || echo ","
        printf '  {"device":"/dev/%s","type":"%s","model":"%s","size":"%s","serial":"%s","md":"%s"}' \
            "$dev" "$type" "$model" "$size" "$sn" "$md"
    done < <(lsblk -dno NAME | grep -E '^(sd|nvme|hd)')
    echo -e "\n]"
    exit 0
fi

printf '%-10s  %-4s  %-34s  %-8s  %-20s  %s\n' DEVICE TYPE MODEL SIZE SERIAL MD
printf '%-10s  %-4s  %-34s  %-8s  %-20s  %s\n' '----------' '----' '----------------------------------' '--------' '--------------------' '--------'
while IFS= read -r dev; do
    size=$(lsblk -dno SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")
    model=$(smartctl_field "$dev" "Device Model|Model Number"); model=${model:-N/A}
    sn=$(smartctl_field "$dev" "Serial Number|Serial number"); sn=${sn:-N/A}
    type=$(disk_type "$dev")
    md="${MD_MAP[$dev]:-none}"
    printf '%-10s  %-4s  %-34s  %-8s  %-20s  %s\n' "/dev/${dev}" "$type" "$model" "$size" "$sn" "$md"
done < <(lsblk -dno NAME | grep -E '^(sd|nvme|hd)')

echo ""
cat /proc/mdstat
