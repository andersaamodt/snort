# ws-fallback module

Provides WebSocket endpoints using `websocketd` for deployments where the Node-based broker is disabled. It bridges Redis pub/sub channels to `/live/<channel>` WebSocket clients by streaming HTML fragments.

## Purpose
* Bridge Redis `PUB/SUB` channels to WebSocket clients without running Node

## Threat model
* Exposes public channels; upstream publishers must ensure payloads are safe HTML
* `websocketd` and helper scripts run with network access and should be minimally privileged

## Configuration
| Variable | Default | Meaning |
| --- | --- | --- |
| `WS_BIND` | `127.0.0.1:9001` | Host and port for websocketd to bind |
| `REDIS_URL` | `redis://127.0.0.1:6379` | Redis instance for pub/sub |

## Failure modes
* `websocketd` missing → broker fails to start
* Redis unavailable → no fragments delivered
* Malformed channel path → subscriber script exits

## Logs
stdout/stderr from `websocketd` and helper scripts; capture via systemd

## Test recipe
```bash
shellcheck scripts/*.sh
shfmt -i 2 -sr -w scripts/broker.sh scripts/redis_sub.sh tests/*.bats
bats tests
```
