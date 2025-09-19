import test from 'node:test';
import assert from 'node:assert/strict';
import { buildReqs, bucketReaction, dedupe, formatRelativeTime, normalizeRelayUrl } from '../static/js/snort.js';

test('buildReqs constructs subscription frames', () => {
  const reqs = buildReqs({ addr: '30023:pub:slug', eventId: 'evt', limit: 80 });
  assert.equal(reqs.length, 2);
  assert.ok(reqs[0].id);
  assert.ok(reqs[1].id);
  assert.deepEqual(reqs[0].frame, ['REQ', reqs[0].id, { kinds: [1, 7], '#a': ['30023:pub:slug'], limit: 80 }]);
  assert.deepEqual(reqs[1].frame, ['REQ', reqs[1].id, { kinds: [1, 7], '#e': ['evt'], limit: 80 }]);

  const older = buildReqs({ addr: '30023:pub:slug', limit: 10, until: 123 });
  assert.equal(older.length, 1);
  assert.deepEqual(older[0].frame, ['REQ', older[0].id, { kinds: [1, 7], '#a': ['30023:pub:slug'], limit: 10, until: 123 }]);
});

test('bucketReaction counts by emoji or content', () => {
  const counts = new Map();
  const first = bucketReaction({ tags: [['emoji', '❤️']], content: '' }, counts);
  const second = bucketReaction({ tags: [], content: '+' }, counts);
  assert.equal(first.key, '❤️');
  assert.equal(first.total, 1);
  assert.equal(second.key, '+');
  assert.equal(second.total, 1);
  assert.equal(counts.get('❤️'), 1);
  assert.equal(counts.get('+'), 1);
});

test('bucketReaction updates plain objects when provided', () => {
  const counts = {};
  const result = bucketReaction({ content: '🔥' }, counts);
  assert.equal(result.key, '🔥');
  assert.equal(result.total, 1);
  assert.equal(result.map.get('🔥'), 1);
  assert.equal(counts['🔥'], 1);
});

test('dedupe tracks seen ids', () => {
  const seen = new Set();
  assert.equal(dedupe('a', seen), true);
  assert.equal(dedupe('a', seen), false);
  assert.equal(dedupe('', seen), false);
});

test('formatRelativeTime expresses human readable deltas', () => {
  const now = Date.now();
  assert.equal(formatRelativeTime(now - 30_000, now), '30s ago');
  assert.equal(formatRelativeTime(now - 3_600_000, now), '1h ago');
  assert.equal(formatRelativeTime(now + 120_000, now), 'in 2m');
});

test('normalizeRelayUrl upgrades protocols and resolves relative paths', () => {
  const win = {
    location: {
      href: 'https://snort.test/posts/example',
      origin: 'https://snort.test',
      protocol: 'https:',
      host: 'snort.test',
    },
  };

  assert.equal(normalizeRelayUrl('/nostr', win), 'wss://snort.test/nostr');
  assert.equal(normalizeRelayUrl('http://relay.example/path', win), 'ws://relay.example/path');
  assert.equal(normalizeRelayUrl('wss://relay.example/', win), 'wss://relay.example/');
  assert.equal(normalizeRelayUrl('mailto:user@example.com', win), null);
});
