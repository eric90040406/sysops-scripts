#!/usr/bin/env bash
# =============================================================================
# disk_info.sh — NAS Disk Inventory Tool
#
# Displays a summary table of all block devices including:
#   - Model / type (HDD or SSD)
#   - Capacity
#   - Serial Number (SN)
#   - MD RAID membership
#
# Requirements:
#   - smartmontools  (smartctl)
#   - mdadm
#   - util-linux     (lsblk)
#
# Usage:
#   sudo bash disk_info.sh [OPTIONS]
#
# Options:
#   -h, --help      Show this help message
#   -j, --json      Output in JSON format
#   -q, --quiet     Suppress header / footer, print table only
#
# Exit codes:
#   0   Success
#   1   Must be run as root
#   2   Required dependency missing
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Argument parsing ──────────────────────────────────────────────────────────
OPT_JSON=false
OPT_QUIET=false

usage() {
    grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,2\}//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)  usage ;;
        -j|--json)  OPT_JSON=true  ;;
        -q|--quiet) OPT_QUIET=true ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

# ── Preflight checks ──────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} This script must be run as root (sudo)." >&2
    exit 1
fi

for cmd in smartctl lsblk mdadm; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[ERROR]${RESET} Required command not found: ${BOLD}${cmd}${RESET}" >&2
        echo "        Install with: apt install smartmontools mdadm util-linux" >&2
        exit 2
    fi
done

# ── Helpers ───────────────────────────────────────────────────────────────────

# Build a map of  device -> md array(s)  from /proc/mdstat
declare -A MD_MAP
build_md_map() {
    local current_md=""
    while IFS= read -r line; do
        # Line like:  md0 : active raid5 sda[0] sdb[1] sdc[2]
        if [[ "$line" =~ ^(md[0-9]+)[[:space:]]*: ]]; then
            current_md="${BASH_REMATCH[1]}"
            # Extract member devices (sdX, nvmeXnY, etc.)
            while [[ "$line" =~ ([a-z]+[0-9]*n?[0-9]*)\[[0-9]+\] ]]; do
                local dev="${BASH_REMATCH[1]}"
                MD_MAP["$dev"]="${MD_MAP[$dev]+${MD_MAP[$dev]},}/dev/${current_md}"
                line="${line#*${BASH_REMATCH[0]}}"
            done
        fi
    done < /proc/mdstat
}

# Return HDD or SSD based on rotational flag
disk_type() {
    local dev="$1"
    local rot
    rot=$(cat "/sys/block/${dev}/queue/rotational" 2>/dev/null || echo "?")
    case "$rot" in
        0) echo "SSD" ;;
        1) echo "HDD" ;;
        *) echo "N/A" ;;
    esac
}

# Parse smartctl output for a single field
smartctl_field() {
    local dev="$1" field="$2"
    smartctl -i "/dev/${dev}" 2>/dev/null \
        | awk -F: -v key="$field" '
            $1 ~ key { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }
          '
}

# ── JSON output ───────────────────────────────────────────────────────────────
output_json() {
    local first=true
    echo "["
    while IFS= read -r dev; do
        local size model sn dtype md_member
        size=$(lsblk -dno SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")
        model=$(smartctl_field "$dev" "Device Model|Model Number")
        sn=$(smartctl_field "$dev" "Serial Number|Serial number")
        dtype=$(disk_type "$dev")
        md_member="${MD_MAP[$dev]:-none}"

        [[ "$first" == true ]] && first=false || echo ","
        printf '  { "device": "/dev/%s", "type": "%s", "model": "%s", "size": "%s", "serial": "%s", "md": "%s" }' \
            "$dev" "$dtype" "${model:-N/A}" "$size" "${sn:-N/A}" "$md_member"
    done < <(lsblk -dno NAME | grep -E '^(sd|nvme|hd)')
    echo ""
    echo "]"
}

# ── Table output ──────────────────────────────────────────────────────────────
output_table() {
    local sep
    sep=$(printf '%-10s %-5s %-35s %-8s %-22s %-20s' \
        '----------' '-----' '-----------------------------------' \
        '--------' '----------------------' '--------------------')

    printf "${BOLD}${CYAN}%-10s %-5s %-35s %-8s %-22s %-20s${RESET}\n" \
        "DEVICE" "TYPE" "MODEL" "SIZE" "SERIAL" "MD ARRAY"
    echo "$sep"

    while IFS= read -r dev; do
        local size model sn dtype md_member colour
        size=$(lsblk -dno SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")
        model=$(smartctl_field "$dev" "Device Model|Model Number")
        [[ -z "$model" ]] && model="N/A"
        sn=$(smartctl_field "$dev" "Serial Number|Serial number")
        [[ -z "$sn" ]] && sn="N/A"
        dtype=$(disk_type "$dev")
        md_member="${MD_MAP[$dev]:-none}"

        case "$dtype" in
            SSD) colour="$GREEN"  ;;
            HDD) colour="$YELLOW" ;;
            *)   colour="$RESET"  ;;
        esac

        printf "${colour}%-10s %-5s %-35s %-8s %-22s %-20s${RESET}\n" \
            "/dev/${dev}" "$dtype" "$model" "$size" "$sn" "$md_member"
    done < <(lsblk -dno NAME | grep -E '^(sd|nvme|hd)')
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    build_md_map

    if [[ "$OPT_JSON" == true ]]; then
        output_json
        return
    fi

    if [[ "$OPT_QUIET" == false ]]; then
        echo -e "${BOLD}NAS Disk Inventory${RESET}  —  $(hostname)  —  $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
    fi

    output_table

    if [[ "$OPT_QUIET" == false ]]; then
        echo ""
        echo -e "${CYAN}MD RAID status (/proc/mdstat):${RESET}"
        cat /proc/mdstat
    fi
}

main "$@"
