# Server Health Check

A Bash script that checks disk, memory, systemd services and listening ports
on a Linux machine. Each run is logged, old logs are cleaned up automatically,
and output can be plain text or JSON.

## Usage

```bash
./healthcheck.sh                    # plain-text report
./healthcheck.sh --threshold 70     # warn on disks above 70% (default: 80)
./healthcheck.sh --json             # machine-readable output
```

```text
=== Disk Usage ===
/ 69%  WARNING: above 50% threshold
/boot/efi 14%

=== Service Status ===
NetworkManager: RUNNING
firewalld: RUNNING

=== Port Status ===
port 22: NOT LISTENING
port 8000: NOT LISTENING
```

## Configuration

Edit the variables at the top of `healthcheck.sh`:

```bash
SERVICES=("NetworkManager" "firewalld")   # systemd services to check
PORTS=(22 8000)                           # ports to check
LOG_RETENTION_DAYS=7                      # delete logs older than this
```

Run it every 15 minutes with cron:

```text
*/15 * * * * cd /path/to/server-healthcheck && ./healthcheck.sh >/dev/null
```

## Project structure

```text
server-healthcheck/
├── healthcheck.sh              # the script
├── README.md
├── .gitignore                  # ignores logs/
└── .github/workflows/ci.yml    # shellcheck + smoke tests
```

## Possible extensions

- Send a Slack or email notification when a threshold is exceeded
- Exit with a non-zero code on warnings, so cron or monitoring tools can react
- CPU load and top-process checks

