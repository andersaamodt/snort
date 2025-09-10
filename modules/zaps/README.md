# zaps module

Renders cached zap receipts into HTML fragments during the build and can emit
live fragments over Redis.

## Purpose
* Render receipts from `$CACHE_ROOT/nostr-cache/zaps/<slug>/*`
* Publish new zap fragments to `zaps:<slug>` channels via Redis

## Threat model
* Zap receipts may be forged with incorrect amounts or content
* Redis publish path could be abused to spam listeners

## Configuration
| Variable | Default | Meaning |
| --- | --- | --- |
| `ZAPS_ENABLED` | `0` | Enable zap rendering and live emission |
| `ZAPS_MODE` | `webln_first_qr_fallback` | Zap UI mode: WebLN preferred with LNURL-QR fallback |

## Failure modes
* Missing cache files → fragments omitted
* Redis unavailable → live zaps not emitted

## Logs
* Append operational logs to `$LOG_ROOT/zaps.log` (not yet used)

## Test recipe
```bash
shellcheck modules/zaps/scripts/render.sh
shfmt -i 2 -sr -w modules/zaps/scripts/render.sh modules/zaps/tests/render.bats modules/zaps/tests/structure.bats
bats modules/zaps/tests
```
