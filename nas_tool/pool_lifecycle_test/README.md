# pool_lifecycle_test

Automated lifecycle test for Synology storage pools and volumes.

Each iteration:
1. Creates a pool + volume on the specified disk via `synowebapi`
2. Writes random data and records the MD5 checksum
3. Reads back and verifies MD5
4. Deletes the volume and pool
5. Confirms everything is cleaned up

Running multiple iterations helps catch intermittent creation/deletion failures.

## Usage

```bash
sudo bash pool_lifecycle_test.sh -d <disk> [-n <iterations>] [-s <size_mb>]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-d` | required | Disk to use (e.g. `sata4`) |
| `-n` | `1` | Number of iterations |
| `-s` | `512` | Write size per iteration in MB |

## Examples

```bash
# single run with 512MB write on sata4
sudo bash pool_lifecycle_test.sh -d sata4

# 10 iterations with 1GB write on sata6
sudo bash pool_lifecycle_test.sh -d sata6 -n 10 -s 1024
```

## Output

```
[10:00:01] --- iteration 1/3 ---
[10:00:01] creating pool+volume on sata4 (512MB)...
[10:00:18] volume mounted at /volume2
[10:00:18] writing 512MB of random data...
[10:00:35] MD5 (write): a3f1c8e2...
[10:00:36] MD5 (read) : a3f1c8e2...
[10:00:36] PASS: iter 1: MD5 match
[10:00:36] deleting volume /volume2...
[10:00:42] deleting pool reuse_2...
[10:00:48] PASS: iter 1: cleanup verified

===== SUMMARY =====
  iterations:  3
  pass:        6
  fail:        0

RESULT: PASS
```

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | All iterations passed |
| `1` | One or more failures |
