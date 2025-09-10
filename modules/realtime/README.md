# realtime module

## Purpose
Relay server-rendered HTML fragments to browsers over WebSockets and accept
publish requests over a small REST API.

## Threat model
Assumes the WebSocket endpoint is public but the REST API is restricted to
trusted callers (e.g., core renderer). Messages are not authenticated.

## Configuration
| Variable | Description |
| --- | --- |
| `REDIS_URL` | Redis instance for pub/sub. |
| `WS_BIND` | Host:port for the WebSocket broker. |
| `API_BIND` | Host:port for the REST API. |

## Failure modes
* Redis unavailable.
* Ports already in use.
* Publish request with empty body.

## Logs
Node processes log to stdout; systemd units should capture output in the
journal.

## Test recipe
```
bats tests
```
