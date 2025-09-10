# pwa module

## Purpose
Provides a Progressive Web App layer so browsers can cache the site shell and a small set of recent posts for offline viewing.

## Threat model
Service worker executes in visitors' browsers; compromised files could serve stale or malicious content. Keep distribution trusted and restrict modifications to `$SITE_ROOT/public`.

## Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `PWA_ENABLED` | Enable the module's render hook | `1` |
| `PWA_CACHE_POSTS` | Number of latest posts the service worker caches | `10` |

## Failure modes
* render hook invoked without `PUBLIC_DIR` set – no files are written
* service worker registration fails client‑side – offline support disabled

## Logs
No logs are produced by this module.

## Test recipe
```
shellcheck scripts/render.sh
shfmt -i 2 -sr -w scripts/render.sh tests/*.bats
bats tests
```
