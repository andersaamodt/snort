# Snort

Snort is a lean, file-centric static site generator that renders Nostr long-form
(kind-30023) events to HTML.  The core stays tiny while optional modules add
features like realtime fragments, comments, zaps, uploads, and more.

## Getting Started

1. Install required tools: Bash, `jq`, `lowdown`, `redis`, and optional module
   dependencies.
2. Run the setup wizard:

```sh
make -C core wizard
```

3. Enable or disable modules interactively with the module wizard, which
   updates `.env` and runs the appropriate install/uninstall scripts:

```sh
./modules/manage/wizard.sh
```

   After selecting modules, fetch content, render HTML, and release it:

```sh
make -C core fetch render release
```

See the [Quickstart](core/QUICKSTART.md) for a detailed walkthrough and the
[module directory](modules/) for individual module documentation.

## Development

Use the root `Makefile` to lint, test, or gather coverage across the project:

```sh
# Format and lint all scripts
make lint

# Run unit tests
make test

# Generate coverage for module install scripts
make coverage
```

Each module contains its own `install.sh`, `uninstall.sh`, and test suite under
`modules/<name>/tests`.
