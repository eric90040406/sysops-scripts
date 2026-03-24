# hotswap_test

Simulates a disk hot-swap on an MD RAID array and verifies the array recovers cleanly.

Steps:
1. Records the initial MD state and `mismatch_cnt`
2. Deactivates the disk with `synostgdisk --disk-deactivate` (simulates physical pull)
3. Confirms MD enters degraded state
4. Re-activates the disk
5. Waits for rebuild to complete, reporting progress every 30s
6. Verifies: all disks active + `mismatch_cnt = 0`

## Usage

```bash
sudo bash hotswap_test.sh -m <md_device> -d <disk_device> [-t <timeout_sec>]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-m` | required | MD RAID device (e.g. `/dev/md0`) |
| `-d` | required | Disk to simulate pulling (e.g. `/dev/sdk`) |
| `-t` | `3600` | Rebuild timeout in seconds |

## Example

```bash
sudo bash hotswap_test.sh -m /dev/md0 -d /dev/sdk -t 7200
```

## Output

```
[10:00:00] === hotswap test — /dev/sdk in /dev/md0 ===
[10:00:00] initial state    : UUU
[10:00:00] initial mismatch : 0

[10:00:00] [1/4] deactivating /dev/sdk...
[10:00:05] MD state after deactivate: UU_
[10:00:05] PASS: MD entered degraded state

[10:00:05] [2/4] re-activating /dev/sdk...
[10:00:15] disk re-activated

[10:00:15] [3/4] waiting for rebuild (timeout: 3600s)...
[10:00:45] rebuilding: 1.2% — ETA 48.3min
[10:01:15] rebuilding: 3.8% — ETA 41.1min
...
[10:49:02] PASS: rebuild completed

[10:49:02] [4/4] verifying final state...
[10:49:02] final MD state   : UUU
[10:49:02] final mismatch   : 0
[10:49:02] PASS: all disks active in /dev/md0
[10:49:02] PASS: mismatch_cnt = 0

RESULT: PASS
```

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | PASS — array fully recovered |
| `1` | FAIL — degraded state not confirmed, rebuild timeout, or mismatch_cnt non-zero |
