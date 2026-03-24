#!/usr/bin/env bash
# check_stress.sh - scan system logs for crash/error indicators
#
# Usage: sudo bash check_stress.sh [-o output_file]
#
# Options:
#   -o <file>   write report to file in addition to stdout
#
# Exit codes:
#   0   no issues found (PASS)
#   1   one or more issues found (FAIL)

set -uo pipefail

OUTPUT_FILE=""
while getopts "o:" opt; do
    case "$opt" in
        o) OUTPUT_FILE="$OPTARG" ;;
        *) echo "usage: $0 [-o output_file]" >&2; exit 2 ;;
    esac
done

# tee to file if -o given, otherwise just stdout
exec_tee() {
    [[ -n "$OUTPUT_FILE" ]] && tee -a "$OUTPUT_FILE" || cat
}

# initialise output file
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "stress check — $(hostname) — $(date '+%Y-%m-%d %H:%M:%S')" > "$OUTPUT_FILE"
fi

declare -A COUNTS   # section -> hit count
FAIL=0

# scan one section, store count, print matches
check() {
    local name="$1"; shift   # remaining args: grep command

    echo "" | exec_tee
    echo "===== ${name} =====" | exec_tee

    local hits
    hits=$("$@" 2>/dev/null) || true

    if [[ -z "$hits" ]]; then
        echo "(none)" | exec_tee
        COUNTS["$name"]=0
    else
        echo "$hits" | exec_tee
        COUNTS["$name"]=$(echo "$hits" | wc -l)
        FAIL=1
    fi
}

check "panic"     grep -h  panic    /var/log/messages /var/log/kern.log
check "DENIED"    grep -ih denied   /var/log/apparmor.log /var/log/kern.log
check "core"      find /volume1 /var/crash -maxdepth 2 -name "*core*" 2>/dev/null
check "segfault"  grep -h  segfault /var/log/messages
check "calltrace" grep -h  "Trace"  /var/log/messages

# summary
echo "" | exec_tee
echo "===== SUMMARY =====" | exec_tee
for section in panic DENIED core segfault calltrace; do
    count="${COUNTS[$section]:-0}"
    if [[ "$count" -gt 0 ]]; then
        printf "  %-12s  FAIL  (%d hit(s))\n" "$section" "$count" | exec_tee
    else
        printf "  %-12s  pass\n" "$section" | exec_tee
    fi
done

echo "" | exec_tee
if [[ $FAIL -eq 0 ]]; then
    echo "RESULT: PASS" | exec_tee
else
    echo "RESULT: FAIL" | exec_tee
fi

[[ -n "$OUTPUT_FILE" ]] && echo "" && echo "report saved: $OUTPUT_FILE"

exit $FAIL
