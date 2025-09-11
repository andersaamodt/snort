# Extensions

Modules extend Snort by following explicit contracts.

## Directory layout

```
modules/<name>/
  README.md
  .env.sample
  scripts/
  tests/
  ops/
```

## Contracts

* **Filesystem** – read/write under `$SNORT_ROOT` only within module-specific roots.
* **Redis** – publish HTML fragments to well-defined channels.
* **HTTP** – optional `/api` endpoints; prefer JSON payloads.
* **Fragments** – outputs must include stable `data-id` attributes for DOM swaps.

## Building a module

1. Create module directory structure.
2. Provide `install.sh` and `uninstall.sh` that manage `.env` and systemd/nginx snippets.
3. Add Bats tests and ensure `shellcheck`/`shfmt` pass.
4. Document purpose, config table, failure modes, logs, and test recipe in `README.md`.

## Test recipe

```bash
shfmt -i 2 -sr -d <module>/install.sh <module>/uninstall.sh <module>/scripts
shellcheck <module>/install.sh <module>/uninstall.sh <module>/scripts/*.sh
bats <module>/tests
```
