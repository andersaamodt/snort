# comments module

Renders cached Nostr replies into HTML fragments during the build and enforces
proof-of-work and rate limits for guest submissions.

## Purpose
* Render replies from `$CACHE_ROOT/nostr-cache/replies/<slug>/*`
* Validate guest replies include a NIP-13 proof-of-work before publishing

## Threat model
* Guests may attempt spam; requiring PoW raises their cost
* Rate limits via Redis mitigate abuse from single IP/npub

## Configuration
| Variable | Default | Meaning |
| --- | --- | --- |
| `GUEST_POW_BITS` | `22` | Required NIP-13 difficulty for guest comments |
| `RATE_IP_PER_MIN` | `30` | Max guest publishes per IP per minute |
| `RATE_PUB_PER_MIN` | `20` | Max publishes per npub per minute |
| `THREAD_MAX_DEPTH` | `8` | Maximum reply nesting depth |

## Failure modes
* PoW verification fails → comment rejected
* Rate limit exceeded → comment rejected
* Missing cache files → fragments omitted

## Logs
* Append operational logs to `$LOG_ROOT/comments.log` (not yet used)

## Test recipe
```bash
shellcheck modules/comments/scripts/verify_pow.sh modules/comments/scripts/rate_limit.sh
shfmt -i 2 -sr -w modules/comments/scripts/verify_pow.sh modules/comments/scripts/rate_limit.sh modules/comments/tests/*.bats
bats modules/comments/tests
```
