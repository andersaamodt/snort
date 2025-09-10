# unix-auth module

## Purpose
Provide SSH key–based authentication for limited Unix file access tied to Snort uploads.

## Threat model
Assumes untrusted remote users. Only public key challenges are accepted; no passwords.

## Configuration
| Variable | Description |
| --- | --- |
| `UNIX_AUTH_ENABLED` | Set to `1` to enable the module. |
| `UNIX_PROVISION_ALLOWED` | Allow self-service Unix user provisioning when `1`. |
| `UNIX_DEFAULT_GROUP` | POSIX group assigned to new users. |
| `UNIX_HOME_BASE` | Directory under which user homes are created. |

Usernames must be lowercase letters only (`[a-z]`) and 1–32 characters long.

### Public key challenge

The script `scripts/issue_challenge.sh` emits a random challenge and returns the
path to the challenge file under `$RUNTIME_ROOT/unix-auth/`.

The script `scripts/verify_challenge.sh` validates a signature against that
challenge using a supplied public key. It relies on `ssh-keygen -Y verify` with
the namespace set to `snort`.

### User provisioning

The script `scripts/provision_user.sh` creates a Unix account for a validated
username when `UNIX_PROVISION_ALLOWED=1`. It assigns the new user to
`UNIX_DEFAULT_GROUP`, creates a home under `UNIX_HOME_BASE`, and installs the
provided public key as `authorized_keys`.

## Failure modes
* Username contains invalid characters or exceeds 32 characters.
* Username already exists on the system.
* Signature does not verify against the provided public key.
* Challenge cannot be issued under `$RUNTIME_ROOT`.
* Group specified in `UNIX_DEFAULT_GROUP` is missing.
* Provisioning attempted when `UNIX_PROVISION_ALLOWED` is not `1`.

## Logs
Scripts log to stdout/stderr; direct systemd units capture output in journal.

## Ops
Sample systemd and nginx snippets are provided under `ops/` to expose the
helper scripts via FastCGI.

## Test recipe
```
bats tests
```
