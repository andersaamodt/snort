#!/usr/bin/env bats

setup_file() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  if ! command -v redis-server > /dev/null; then
    apt-get update > /dev/null && apt-get install -y redis-server > /dev/null
  fi
  if ! command -v lowdown > /dev/null; then
    apt-get update > /dev/null && apt-get install -y lowdown > /dev/null
  fi
  redis-server --save "" --appendonly no --port 6382 > /tmp/redis.log 2>&1 &
  REDIS_PID=$!
  sleep 1
}

teardown_file() {
  kill "$REDIS_PID"
}

@test "publishes zap fragment to redis" {
  cat > /tmp/zap.json << 'JSON'
{"id":"z1","amount":1000,"content":"Nice"}
JSON
  redis-cli -p 6382 SUBSCRIBE zaps:test > /tmp/zlog &
  SUB_PID=$!
  sleep 1
  REDIS_URL=redis://127.0.0.1:6382 ./scripts/publish.sh test /tmp/zap.json
  sleep 1
  kill "$SUB_PID"
  grep '<li class="zap" data-id="zap:z1">1 sats - <p>Nice</p>' /tmp/zlog
}
