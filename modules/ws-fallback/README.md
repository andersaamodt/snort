# ws-fallback module

Provides WebSocket endpoints using `websocketd` for environments where the Node-based broker is disabled. It bridges Redis pub/sub channels to `/live/<channel>` WebSocket clients by streaming HTML fragments.

## Scripts
- `scripts/broker.sh` – launches `websocketd` with the Redis bridge
- `scripts/redis_sub.sh` – subscribes to a Redis channel and forwards payloads

## Configuration
- `WS_BIND` – host:port to bind (default `127.0.0.1:9001`)
- `REDIS_URL` – Redis connection string (default `redis://127.0.0.1:6379`)

