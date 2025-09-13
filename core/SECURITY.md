# Security

Guidelines for safe operation of Snort and its modules.

## Authentication

Snort relies on NIP‑07 browser signing. The server never stores private keys.

## Guest comments

* Guests receive pseudo-key pairs stored in `localStorage`.
* Publishing requires 22‑bit NIP‑13 proof of work.
* Redis rate limits enforce per-IP and per-public-key quotas.

## Moderation

* Local allow/deny lists follow NIP‑51.
* Reports are emitted using NIP‑56.

## Filesystem boundaries

Each module writes only within its configured root under `$SNORT_ROOT` to limit blast radius.

## Failure modes

* Compromised module scripts may write outside allowed directories if run with excessive privileges.
* Misconfigured Redis allows bypassing rate limits.

## Logs

Security-relevant logs live under `${LOG_ROOT}`; review regularly for anomalies.

## Test recipe

```bash
make -C core test
```
