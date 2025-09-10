# Nostr Module

## Purpose
Fetch Nostr long-form posts (kind-30023), author profiles (kind-0), replies (kind-1), and zap receipts (kind-9735) and store them as JSON under `$CACHE_ROOT/nostr-cache`.

## Threat model
- Relays are untrusted; malformed or malicious events are ignored.
- The fetcher runs with network access only to configured relays; compromise could write arbitrary files within the cache directory.

## Configuration
| Variable | Description |
| --- | --- |
| `RELAYS_READ` | Comma-separated relay URLs to query |
| `AUTHOR_NPUBS` | Comma-separated allowed author npubs |
| `FETCH_INTERVAL_MIN` | Minutes between fetch runs |
| `TOR_SOCKS` | Optional SOCKS proxy address (e.g., `127.0.0.1:9050`) |

## Failure modes
- `nostr-cli` missing or returning errors
- Network failures contacting relays
- Unwritable cache directory
- Invalid JSON from relays

## Logs
Writes activity to `${LOG_ROOT}/nostr-fetch.log`.

## Ops
Sample systemd service and timer files are provided under `ops/` to run
`scripts/fetch.sh` on a schedule.

## Test recipe
```bash
shellcheck scripts/fetch.sh
shfmt -i 2 -sr -w scripts/fetch.sh tests/*.bats
bats tests
```
