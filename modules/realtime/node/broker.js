#!/usr/bin/env node
const WebSocket = require('ws');
const Redis = require('ioredis');

const redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
const wsBind = process.env.WS_BIND || '127.0.0.1:9001';
const [host, port] = wsBind.split(':');

const redis = new Redis(redisUrl);
const server = new WebSocket.Server({ host, port: parseInt(port, 10) });

redis.psubscribe('*');

server.on('connection', (ws, req) => {
  const channel = req.url.replace(/^\/live\//, '');
  ws.channel = channel;
});

redis.on('pmessage', (_pattern, channel, message) => {
  server.clients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN && ws.channel === channel) {
      ws.send(message);
    }
  });
});

