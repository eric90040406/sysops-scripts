# check_stress

Scans system logs for crash and error indicators. Prints a structured report with a PASS/FAIL summary at the end.

Checks covered: `panic`, `AppArmor DENIED`, `core dumps`, `segfault`, `call trace`

## Usage

```bash
sudo bash check_stress.sh               # print to stdout
sudo bash check_stress.sh -o report.txt # also save to file
```

## Output

```
===== panic =====
(none)

===== DENIED =====
Mar 24 10:01:12 kernel: apparmor="DENIED" operation="file" ...

===== core =====
(none)

===== segfault =====
(none)

===== calltrace =====
(none)

===== SUMMARY =====
  panic         pass
  DENIED        FAIL  (1 hit(s))
  core          pass
  segfault      pass
  calltrace     pass

RESULT: FAIL
```

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | PASS — no issues found |
| `1` | FAIL — one or more issues detected |
| `2` | Invalid arguments |

The exit code makes it easy to chain with other scripts:

```bash
sudo bash check_stress.sh && echo "clean, proceed with maintenance"
```
