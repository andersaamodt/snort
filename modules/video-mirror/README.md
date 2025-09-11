# video-mirror module

Mirrors remote videos and creates a single 720p H.264/AAC transcode while keeping the original download.

## Purpose
* Fetch remote videos and store the raw file under `$MIRRORS_ROOT/raw`
* Transcode to 720p MP4 under `$MIRRORS_ROOT/mp4`
* Timer or anonymous enqueue can schedule mirrors

## Threat model
* Remote sources may deliver malicious or oversized files; the mirror process should run with minimal privileges
* `yt-dlp` and `ffmpeg` are external tools and could be compromised

## Configuration
| Variable | Default | Meaning |
| --- | --- | --- |
| `MIRROR_TIMER_MIN` | `30` | Minutes between scan/enqueue runs |
| `MIRROR_ALLOW_ANON` | `1` | Allow anonymous enqueue requests |
| `MIRRORS_ROOT` | `$SNORT_ROOT/mirrors` | Root directory for mirrored media |
| `FFMPEG_PRESET` | `veryfast` | ffmpeg x264 preset |
| `FFMPEG_CRF` | `20` | ffmpeg CRF value |
| `MIME_LOG` | `1` | Log MIME types to `$LOG_ROOT/video-mirror.log` |

## Failure modes
* `yt-dlp` or `ffmpeg` missing → mirroring fails
* Source URL invalid or unreadable
* Insufficient disk space under `$MIRRORS_ROOT`

## Logs
Mirror operations append to `$LOG_ROOT/video-mirror.log` when `LOG_ROOT` is set

## Test recipe
```bash
shellcheck scripts/mirror.sh
shfmt -i 2 -sr -w scripts/mirror.sh tests/*.bats
bats tests
```
