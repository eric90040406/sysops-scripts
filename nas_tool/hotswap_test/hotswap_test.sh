#!/usr/bin/env bash
# hotswap_test.sh
#
# Simulates disk hot-swap by deactivating a disk from an MD RAID array,
# then re-activating it and waiting for rebuild to complete.
# Verifies that the array returns to a healthy state with mismatch_cnt = 0.
#
# Usage: sudo bash hotswap_test.sh -m <md_device> -d <disk_device> [-t <timeout_sec>]
# Example: sudo bash hotswap_test.sh -m /dev/md0 -d /dev/sdk -t 3600

set -uo pipefail

MD=""
DISK=""
TIMEOUT=3600
FAIL=0

usage() { echo "usage: $0 -m <md_device> -d <disk_device> [-t <timeout_sec>]" >&2; exit 1; }

while getopts "m:d:t:" opt; do
    case "$opt" in
        m) MD="$OPTARG" ;;
        d) DISK="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        *) usage ;;
    esac
done

[[ -z "$MD" || -z "$DISK" ]] && usage
[[ $EUID -ne 0 ]] && { echo "run as root" >&2; exit 1; }

MD_NAME=$(basename "$MD")
DISK_NAME=$(basename "$DISK")

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { log "PASS: $*"; }
fail() { log "FAIL: $*"; (( FAIL++ )); }

md_disk_state() {
    # returns the [UU_] style bitmap for this MD array
    grep -A2 "^${MD_NAME}" /proc/mdstat | grep -oP '\[\K[U_]+(?=\])' || echo "?"
}

mismatch_cnt() {
    cat "/sys/block/${MD_NAME}/md/mismatch_cnt" 2>/dev/null || echo "N/A"
}

is_rebuilding() {
    grep -A4 "^${MD_NAME}" /proc/mdstat | grep -qE 'recovery|resync'
}

rebuild_progress() {
    local pct eta
    pct=$(grep -A4 "^${MD_NAME}" /proc/mdstat | grep -oP '\d+\.\d+%' | head -1)
    eta=$(grep -A4 "^${MD_NAME}" /proc/mdstat | grep -oP 'finish=\K\S+')
    echo "${pct:-?} — ETA ${eta:-?}"
}

wait_for_rebuild() {
    local elapsed=0
    while (( elapsed < TIMEOUT )); do
        if ! is_rebuilding; then
            return 0
        fi
        log "  rebuilding: $(rebuild_progress)"
        sleep 30; (( elapsed += 30 ))
    done
    return 1
}

# ── main ─────────────────────────────────────────────────────────────────────
log "=== hotswap test — ${DISK} in ${MD} ==="
log "initial state    : $(md_disk_state)"
log "initial mismatch : $(mismatch_cnt)"
echo ""

# step 1: deactivate disk
log "[1/4] deactivating ${DISK}..."
synostgdisk --disk-deactivate "$DISK"
sleep 5

state=$(md_disk_state)
log "MD state after deactivate: ${state}"
if [[ "$state" == *"_"* ]]; then
    pass "MD entered degraded state"
else
    fail "MD did not go degraded (state=${state})"
fi
echo ""

# step 2: re-activate disk
log "[2/4] re-activating ${DISK}..."
rm -f "/run/synostorage/disks/${DISK_NAME}/deactivated"
sleep 10
log "disk re-activated"
echo ""

# step 3: wait for rebuild
log "[3/4] waiting for rebuild (timeout: ${TIMEOUT}s)..."
if wait_for_rebuild; then
    pass "rebuild completed"
else
    fail "rebuild timed out after ${TIMEOUT}s"
fi
echo ""

# step 4: verify final state
log "[4/4] verifying final state..."
final_state=$(md_disk_state)
final_mismatch=$(mismatch_cnt)
log "final MD state   : ${final_state}"
log "final mismatch   : ${final_mismatch}"

if [[ "$final_state" != *"_"* ]]; then
    pass "all disks active in ${MD}"
else
    fail "MD still degraded after rebuild (state=${final_state})"
fi

if [[ "$final_mismatch" == "0" ]]; then
    pass "mismatch_cnt = 0"
else
    fail "mismatch_cnt = ${final_mismatch}"
fi

echo ""
[[ $FAIL -eq 0 ]] && echo "RESULT: PASS" || echo "RESULT: FAIL (${FAIL} issue(s))"
[[ $FAIL -eq 0 ]]
