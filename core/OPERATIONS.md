# Operations

Guidelines for maintaining a Snort deployment.

## Backups

* Backup `$CACHE_ROOT` and `$SITE_ROOT` regularly.
* Copy `${LOG_ROOT}` if audit trails are required.

## Log rotation

Logs live under `${LOG_ROOT}` and may be rotated with `logrotate`:

```
/var/log/snort/*.log {
  weekly
  rotate 8
  compress
}
```

## Upgrades

1. Pull new code:
   ```bash
   git fetch --tags && git checkout v0.1.0
   ```
2. Re-run module install scripts if needed.
3. `make -C core render` and `make -C core release`.

## Zero-downtime release

Rendering occurs in `core/public`; `make release` atomically swaps `$SITE_ROOT/current` to the new build using `rsync` and a symlink.

## Failure modes

* Insufficient disk space – renders or logs fail
* Stale `.env` changes – module hooks may misbehave
* Interrupted release – site may serve mixed versions

## Logs

Each module writes to its own log under `${LOG_ROOT}`. Core render and fetch logs are `core-render.log` and `core-fetch.log`.

## Test recipe

```bash
make -C core test
```
