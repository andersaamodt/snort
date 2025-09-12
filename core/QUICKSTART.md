# Quickstart

This guide brings a new Snort instance online in roughly ten minutes.

## 1. Prepare environment

```bash
sudo apt-get install -y git curl jq lowdown
git clone https://example.com/snort.git && cd snort
```

## 2. Configure core

```bash
cp core/.env.example core/.env
$EDITOR core/.env
```

Set paths and enable desired modules in the `MODULES` variable.

## 3. Fetch and render

```bash
make -C core fetch
make -C core render
```

Static HTML appears under `core/public`.

## 4. Release to site root

```bash
sudo make -C core release
```

This rsyncs the build to `$SITE_ROOT/current` for serving.

## Configuration

| Variable | Description |
|----------|-------------|
| `DOMAIN` | Public domain name |
| `SNORT_ROOT` | Base path for all Snort data |
| `SITE_ROOT` | Public site directory |
| `CACHE_ROOT` | Nostr and fragment cache |
| `UPLOADS_ROOT` | User-uploaded files |
| `MIRRORS_ROOT` | Video mirror storage |
| `LOG_ROOT` | Log files |
| `RUNTIME_ROOT` | PID files, sockets, temporary data |
| `MODULES` | Comma-separated modules to enable |

## Failure modes

* Missing dependencies (`jq`, `lowdown`) – rendering fails
* Incorrect paths – files written to unexpected locations
* Enabled modules without install scripts run – hooks no-op

## Logs

Core write logs under `${LOG_ROOT}` for fetch and render operations.

## Test recipe

```bash
make -C core test
```
