#!/usr/bin/env bats

setup_file() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  if ! command -v redis-server > /dev/null; then
    apt-get update > /dev/null && apt-get install -y redis-server > /dev/null
  fi
  if ! command -v lowdown > /dev/null; then
    apt-get update > /dev/null && apt-get install -y lowdown > /dev/null
  fi
  redis-server --save "" --appendonly no --port 6381 > /tmp/redis.log 2>&1 &
  REDIS_PID=$!
  sleep 1
}

teardown_file() {
  kill "$REDIS_PID"
}

@test "publishes reply fragment to redis" {
  cat > /tmp/reply.json << 'JSON'
{"id":"r1","content":"Hello world"}
JSON
  redis-cli -p 6381 SUBSCRIBE replies:test > /tmp/sub.log &
  SUB_PID=$!
  sleep 1
  REDIS_URL=redis://127.0.0.1:6381 ./scripts/publish.sh test /tmp/reply.json
  sleep 1
  kill "$SUB_PID"
  grep '<li class="reply" data-id="nostr:r1">' /tmp/sub.log
}
