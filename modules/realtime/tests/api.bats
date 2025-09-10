#!/usr/bin/env bats

setup_file() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  if ! command -v redis-server > /dev/null; then
    apt-get update > /dev/null && apt-get install -y redis-server > /dev/null
  fi
  npm --prefix node install > /dev/null 2>&1
  redis-server --save "" --appendonly no --port 6380 > /tmp/redis.log 2>&1 &
  REDIS_PID=$!
  sleep 1
}

teardown_file() {
  kill "$REDIS_PID"
}

@test "api publishes to websocket clients" {
  REDIS_URL=redis://127.0.0.1:6380 WS_BIND=127.0.0.1:9001 node node/broker.js > /tmp/broker.log 2>&1 &
  BROKER_PID=$!
  API_BIND=127.0.0.1:9002 REDIS_URL=redis://127.0.0.1:6380 node node/api.js > /tmp/api.log 2>&1 &
  API_PID=$!
  sleep 1

  (cd node && node -e "const WebSocket=require('ws');const ws=new WebSocket('ws://127.0.0.1:9001/live/test');ws.on('message',m=>{console.log(m.toString());process.exit(0);});setTimeout(()=>process.exit(1),3000);") > /tmp/client.log 2>&1 &
  CLIENT_PID=$!
  sleep 1

  curl -sS -X POST -H 'Content-Type: text/plain' --data '<p>hi</p>' http://127.0.0.1:9002/publish/test > /tmp/api_resp.json

  wait "$CLIENT_PID"
  grep '<p>hi</p>' /tmp/client.log

  kill "$BROKER_PID" "$API_PID"
}
