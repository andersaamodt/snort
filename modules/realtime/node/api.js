#!/usr/bin/env node
const Redis = require('ioredis');
const fastify = require('fastify');

const redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
const apiBind = process.env.API_BIND || '127.0.0.1:9002';
const [host, port] = apiBind.split(':');

const redis = new Redis(redisUrl);
const app = fastify();

app.addContentTypeParser('*', { parseAs: 'string' }, (req, payload, done) => {
  done(null, payload);
});

app.post('/publish/:channel', async (req, reply) => {
  const channel = req.params.channel;
  const message = req.body;
  if (!message || typeof message !== 'string' || !message.trim()) {
    reply.code(400).send({ error: 'empty body' });
    return;
  }
  await redis.publish(channel, message);
  reply.send({ status: 'ok' });
});

app.listen({ host, port: parseInt(port, 10) });
