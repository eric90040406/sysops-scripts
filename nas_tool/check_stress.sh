#!/usr/bin/env bash
# check_stress.sh - scan system logs for crash/error indicators
#
# Usage: sudo bash check_stress.sh
#
# Checks: panic, AppArmor DENIED, core dumps, segfault, call trace

set -uo pipefail

section() {
    echo ""
    echo "===== $1 ====="
}

section "panic"
grep -h panic /var/log/messages /bin/dmesg /var/log/kern.log 2>/dev/null || echo "(none)"

section "DENIED (AppArmor)"
grep -ih denied /var/log/apparmor.log /var/log/kern.log 2>/dev/null || echo "(none)"

section "core dumps"
ls /volume*/core /var/crash/*core* 2>/dev/null || echo "(none)"

section "segfault"
grep segfault /var/log/messages 2>/dev/null || echo "(none)"

section "call trace"
grep -i "Trace" /var/log/messages 2>/dev/null || echo "(none)"
