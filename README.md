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

## Interactivity

Rendering includes lightweight hooks for live replies and reactions when the
interactivity feature is enabled. Configure the behavior through the core
`.env` file:

* `INTERACT_ENABLE` – set to `0` to omit the browser module entirely.
* `INTERACT_LIMIT` – maximum events fetched per subscription (default `80`).
* `INTERACT_SHOW_REPLY` – reveal the reply button when a NIP-07 provider is
  present.
* `INTERACT_RELAYS` – JSON array of relay URLs or relative WebSocket paths.

With the defaults enabled, post pages stream new replies and reaction counts
from the configured relay and offer a NIP-07 reply dialog as a progressive
enhancement. Set `INTERACT_ENABLE=0` to keep the site fully static and skip the
module tag entirely for environments where WebSockets are unavailable.

Each rendered post exposes predictable hooks so custom themes can restyle the
interactive elements:

```html
<body
  data-event-id="EVENT_ID"
  data-addr="30023:PUBKEY:SLUG"
  data-author-pubkey="PUBKEY"
  data-relays='["wss://yourdomain/nostr"]'
  data-limit="80"
  data-show-reply="1"
>
  <main>…post body…</main>

  <aside id="reactions" aria-label="Reactions">
    <span data-reaction="+">0</span>
    <span data-reaction="❤️">0</span>
  </aside>

  <section id="replies" aria-live="polite"></section>

  <button id="load-more" hidden aria-controls="replies">Load more</button>
  <button
    id="reply-btn"
    hidden
    aria-haspopup="dialog"
    aria-controls="reply-dialog"
    aria-expanded="false"
  >
    Reply
  </button>
</body>
```

When WebSockets or relays fail, the client adds a `Live view unavailable.`
banner near the top of the page but leaves the static content intact.

Expose the relay through your edge proxy so browsers can connect to it. The
sample [`core/ops/nginx.conf`](core/ops/nginx.conf) adds a `/nostr` location
block that upgrades WebSocket connections and forwards them to the local relay
service.

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

Coverage reports are written to `coverage/` and should show complete line
coverage for install and uninstall scripts.

Each module contains its own `install.sh`, `uninstall.sh`, and test suite under
`modules/<name>/tests`.
