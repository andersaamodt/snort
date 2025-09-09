#!/usr/bin/env bats

@test "ops files provide sample configs" {
  [ -f ops/nginx.conf ]
  grep -q 'server {' ops/nginx.conf

  [ -f ops/snort-render.service ]
  grep -q 'render release' ops/snort-render.service

  [ -f ops/snort-fetch.service ]
  grep -q 'make -C "\$SNORT_ROOT/core" fetch' ops/snort-fetch.service

  [ -f ops/snort-fetch.timer ]
  grep -q 'snort-fetch.service' ops/snort-fetch.timer
}
