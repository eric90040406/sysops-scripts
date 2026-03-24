#!/usr/bin/env bash
# pool_lifecycle_test.sh
#
# Creates a pool+volume, writes random data, verifies MD5 readback,
# then tears everything down. Repeats N times to catch intermittent issues.
#
# Usage: sudo bash pool_lifecycle_test.sh -d <disk> [-n <iterations>] [-s <size_mb>]
# Example: sudo bash pool_lifecycle_test.sh -d sata4 -n 5 -s 512

set -uo pipefail

DISK=""
ITERATIONS=1
SIZE_MB=512
PASS=0
FAIL=0

usage() { echo "usage: $0 -d <disk> [-n <iterations>] [-s <size_mb>]" >&2; exit 1; }

while getopts "d:n:s:" opt; do
    case "$opt" in
        d) DISK="$OPTARG" ;;
        n) ITERATIONS="$OPTARG" ;;
        s) SIZE_MB="$OPTARG" ;;
        *) usage ;;
    esac
done

[[ -z "$DISK" ]] && usage
[[ $EUID -ne 0 ]] && { echo "run as root" >&2; exit 1; }

SIZE_KB=$(( SIZE_MB * 1024 ))

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
pass() { log "PASS: $*"; (( PASS++ )); }
fail() { log "FAIL: $*"; (( FAIL++ )); }

# poll until a /volumeN appears in mount output, or timeout
wait_for_volume() {
    local timeout="${1:-120}" elapsed=0
    while (( elapsed < timeout )); do
        mount | grep -qP '/volume\d+' && return 0
        sleep 3; (( elapsed += 3 ))
    done
    return 1
}

# poll until no /volumeN in mount output, or timeout
wait_volume_gone() {
    local vol="$1" timeout="${2:-60}" elapsed=0
    while (( elapsed < timeout )); do
        mount | grep -q "$vol" || return 0
        sleep 3; (( elapsed += 3 ))
    done
    return 1
}

create_pool_and_volume() {
    synowebapi --exec \
        allocate_size="\"${SIZE_KB}\"" \
        api="SYNO.Storage.CGI.Volume" \
        atime_opt="\"relatime\"" \
        blocking="false" \
        desc="\"\"" \
        device_type="\"basic\"" \
        diskGroups="[{\"isNew\":true,\"raidPath\":\"new_raid\",\"disks\":[\"${DISK}\"]}]" \
        disk_id="[\"${DISK}\"]" \
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
        vol_desc="\"\"" > /dev/null
}

delete_volume() {
    local vol="$1"
    synowebapi --exec \
        api="SYNO.Storage.CGI.Volume" \
        method="delete" \
        version="1" \
        vol_path="\"${vol}\"" \
        force="false" > /dev/null
}

delete_pool() {
    local pool="$1"
    synowebapi --exec \
        api="SYNO.Storage.CGI.Pool" \
        method="delete" \
        version="1" \
        pool_path="\"${pool}\"" \
        force="false" > /dev/null
}

get_pool_path() {
    synowebapi --exec api="SYNO.Storage.CGI.Pool" method="list" version="1" 2>/dev/null \
        | grep -oP '"pool_path":"\K[^"]+' | head -1
}

run_iteration() {
    local iter="$1"
    log "--- iteration ${iter}/${ITERATIONS} ---"

    # create
    log "creating pool+volume on ${DISK} (${SIZE_MB}MB)..."
    if ! create_pool_and_volume; then
        fail "iter ${iter}: synowebapi create failed"
        return
    fi

    if ! wait_for_volume 120; then
        fail "iter ${iter}: volume did not mount within 120s"
        return
    fi

    local vol
    vol=$(mount | grep -oP '/volume\d+' | tail -1)
    log "volume mounted at ${vol}"

    # write + verify MD5
    local testfile="${vol}/lifecycle_test_${iter}.dat"
    log "writing ${SIZE_MB}MB of random data..."
    dd if=/dev/urandom of="$testfile" bs=1M count="$SIZE_MB" status=none

    local md5_write md5_read
    md5_write=$(md5sum "$testfile" | awk '{print $1}')
    log "MD5 (write): ${md5_write}"
    md5_read=$(md5sum "$testfile" | awk '{print $1}')
    log "MD5 (read) : ${md5_read}"

    rm -f "$testfile"

    if [[ "$md5_write" == "$md5_read" ]]; then
        pass "iter ${iter}: MD5 match"
    else
        fail "iter ${iter}: MD5 mismatch"
    fi

    # delete volume
    log "deleting volume ${vol}..."
    delete_volume "$vol"

    # delete pool
    local pool
    pool=$(get_pool_path)
    if [[ -n "$pool" ]]; then
        log "deleting pool ${pool}..."
        delete_pool "$pool"
    else
        log "WARN: could not find pool to delete"
    fi

    # verify cleanup
    if wait_volume_gone "$vol" 60; then
        pass "iter ${iter}: cleanup verified"
    else
        fail "iter ${iter}: volume still mounted after deletion"
    fi
}

# ── main ─────────────────────────────────────────────────────────────────────
for (( i=1; i<=ITERATIONS; i++ )); do
    run_iteration "$i"
done

echo ""
echo "===== SUMMARY ====="
printf "  %-12s %s\n" "iterations:" "$ITERATIONS"
printf "  %-12s %s\n" "pass:"       "$PASS"
printf "  %-12s %s\n" "fail:"       "$FAIL"
echo ""
[[ $FAIL -eq 0 ]] && echo "RESULT: PASS" || echo "RESULT: FAIL"
[[ $FAIL -eq 0 ]]
