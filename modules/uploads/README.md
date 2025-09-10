# uploads module

Copies files into `$UPLOADS_ROOT` for later use in posts.

## Purpose
Enable trusted users to stage media under `$UPLOADS_ROOT` before linking them in posts. Files are stored locally and are not published to relays until referenced by an author.

## Threat model
Unauthorised or oversized uploads could exhaust disk or leak data. POSIX permissions and role checks gate access. Files are trusted only after an author links them in a post.

## Configuration
| Variable | Default | Description |
| -------- | ------- | ----------- |
| `UPLOAD_ROLES` | `admins,authors` | Comma-separated roles permitted to upload |
| `UPLOAD_MAX_MB` | `2048` | Maximum file size allowed |
| `UPLOAD_AUTOPUBLISH_NIP94` | `0` | Whether to auto-publish NIP-94 metadata on upload (unused in v0.1.0) |

## Failure modes
- Upload role not permitted
- File exceeds `UPLOAD_MAX_MB`
- Source file missing or unreadable

## Logs
Writes MIME and size information to `$LOG_ROOT/uploads.log` when `LOG_ROOT` is set.

## Test recipe
```bash
shellcheck modules/uploads/scripts/upload.sh
shfmt -i 2 -sr -w modules/uploads/scripts/upload.sh modules/uploads/tests/*.bats
bats modules/uploads/tests
```
