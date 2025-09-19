const FOCUSABLE_SELECTOR = 'textarea, button';
const REPLY_DIALOG_ID = 'reply-dialog';

function randomSubId() {
  return Math.random().toString(36).slice(2);
}

export function normalizeRelayUrl(entry, win = typeof window !== 'undefined' ? window : undefined) {
  if (typeof entry !== 'string') return null;
  const trimmed = entry.trim();
  if (!trimmed) return null;

  const location = win?.location;
  let baseHref = 'https://localhost/';
  if (location?.href) {
    baseHref = location.href;
  } else if (location?.origin) {
    baseHref = `${location.origin}/`;
  } else if (location?.protocol && location?.host) {
    baseHref = `${location.protocol}//${location.host}/`;
  }

  try {
    const url = new URL(trimmed, baseHref);
    if (url.protocol === 'http:' || url.protocol === 'ws:') {
      url.protocol = 'ws:';
    } else if (url.protocol === 'https:' || url.protocol === 'wss:') {
      url.protocol = 'wss:';
    } else {
      return null;
    }
    return url.toString();
  } catch (err) {
    console.error('Failed to normalize relay URL', err);
    return null;
  }
}

export function buildReqs({ addr, eventId, limit, until }) {
  const reqs = [];
  const subA = randomSubId();
  const filterA = { kinds: [1, 7], '#a': [addr] };
  if (Number.isFinite(limit) && limit > 0) {
    filterA.limit = Math.floor(limit);
  }
  if (Number.isFinite(until) && until > 0) {
    filterA.until = Math.floor(until);
  }
  reqs.push({
    id: subA,
    frame: ['REQ', subA, filterA],
  });
  if (eventId) {
    const subE = randomSubId();
    const filterE = { kinds: [1, 7], '#e': [eventId] };
    if (Number.isFinite(limit) && limit > 0) {
      filterE.limit = Math.floor(limit);
    }
    if (Number.isFinite(until) && until > 0) {
      filterE.until = Math.floor(until);
    }
    reqs.push({
      id: subE,
      frame: ['REQ', subE, filterE],
    });
  }
  return reqs;
}

export function bucketReaction(evt, counts) {
  const map = counts instanceof Map ? counts : new Map();
  const emojiTag = evt?.tags?.find((t) => Array.isArray(t) && t[0] === 'emoji' && t[1]);
  const key = (emojiTag?.[1] || evt?.content || '+').trim() || '+';
  const total = (map.get(key) || 0) + 1;
  map.set(key, total);
  if (!(counts instanceof Map) && counts) {
    counts[key] = total;
  }
  return { key, total, map };
}

export function dedupe(id, seen) {
  if (!id) return false;
  if (seen.has(id)) return false;
  seen.add(id);
  return true;
}

export function formatRelativeTime(timestampMs, nowMs = Date.now()) {
  if (!Number.isFinite(timestampMs) || !Number.isFinite(nowMs)) return '';
  const diff = nowMs - timestampMs;
  const abs = Math.abs(diff);
  const minute = 60 * 1000;
  const hour = 60 * minute;
  const day = 24 * hour;
  const week = 7 * day;

  if (abs < minute) {
    const seconds = Math.max(1, Math.round(abs / 1000));
    return diff >= 0 ? `${seconds}s ago` : `in ${seconds}s`;
  }
  if (abs < hour) {
    const minutes = Math.round(abs / minute);
    return diff >= 0 ? `${minutes}m ago` : `in ${minutes}m`;
  }
  if (abs < day) {
    const hours = Math.round(abs / hour);
    return diff >= 0 ? `${hours}h ago` : `in ${hours}h`;
  }
  if (abs < week) {
    const days = Math.round(abs / day);
    return diff >= 0 ? `${days}d ago` : `in ${days}d`;
  }
  const date = new Date(timestampMs);
  if (Number.isNaN(date.getTime())) return '';
  return date.toISOString().split('T')[0];
}

function abbreviatePubkey(pubkey) {
  if (typeof pubkey !== 'string' || pubkey.length < 8) return pubkey || '';
  return `${pubkey.slice(0, 8)}…${pubkey.slice(-4)}`;
}

function renderReply(doc, container, evt, options = {}) {
  if (!container) return;
  const article = doc.createElement('article');
  if (evt.id) {
    article.dataset.eventId = evt.id;
  }

  const header = doc.createElement('header');
  if (evt.pubkey) {
    const who = doc.createElement('span');
    who.className = 'reply-author';
    who.textContent = abbreviatePubkey(evt.pubkey);
    header.append(who);
  }
  let createdAtMs = null;
  if (evt.created_at) {
    const time = doc.createElement('time');
    const timestampMs = Number(evt.created_at) * 1000;
    if (Number.isFinite(timestampMs)) {
      createdAtMs = timestampMs;
      const iso = new Date(timestampMs).toISOString();
      time.setAttribute('datetime', iso);
      time.textContent = formatRelativeTime(timestampMs);
      article.dataset.createdAt = String(timestampMs);
    }
    header.append(time);
  }
  if (header.childNodes.length) {
    article.append(header);
  }

  const body = doc.createElement('div');
  body.className = 'reply-body';
  const text = typeof evt.content === 'string' ? evt.content : '';
  const blocks = text.split(/\n{2,}/);
  if (blocks.length === 0) {
    const paragraph = doc.createElement('p');
    paragraph.append(doc.createTextNode(''));
    body.append(paragraph);
  } else {
    for (const block of blocks) {
      const paragraph = doc.createElement('p');
      const lines = block.split('\n');
      lines.forEach((line, idx) => {
        paragraph.append(doc.createTextNode(line));
        if (idx < lines.length - 1) {
          paragraph.append(doc.createElement('br'));
        }
      });
      body.append(paragraph);
    }
  }
  article.append(body);
  const append = options.append === true;
  const placeAtEnd = () => {
    if (typeof container.append === 'function') {
      container.append(article);
    } else {
      container.insertBefore(article, null);
    }
  };
  if (append) {
    placeAtEnd();
    return;
  }
  if (Number.isFinite(createdAtMs)) {
    const children = Array.isArray(container.children)
      ? container.children
      : Array.from(container.children || container.childNodes || []);
    for (const child of children) {
      if (!child || typeof child !== 'object') continue;
      const value = Number(child.dataset?.createdAt);
      if (!Number.isFinite(value)) continue;
      if (value <= createdAtMs) {
        container.insertBefore(article, child);
        return;
      }
    }
    placeAtEnd();
    return;
  }
  if (typeof container.prepend === 'function') {
    container.prepend(article);
  } else {
    container.insertBefore(article, container.firstChild || null);
  }
}

function updateReactions(doc, container, evt, counts) {
  if (!container) return;
  const { key, total } = bucketReaction(evt, counts);
  let target = null;
  const nodes = container.querySelectorAll('[data-reaction]');
  for (const node of nodes) {
    if (node.dataset?.reaction === key) {
      target = node;
      break;
    }
  }
  if (!target) {
    target = doc.createElement('span');
    target.dataset.reaction = key;
    target.textContent = '0';
    container.append(target);
  }
  target.textContent = String(total);
}

function showUnavailable(doc) {
  if (!doc?.body) return;
  const loadMore = typeof doc.getElementById === 'function' ? doc.getElementById('load-more') : null;
  if (loadMore) {
    loadMore.disabled = true;
  }
  if (doc.getElementById('live-unavailable')) return;
  const banner = doc.createElement('div');
  banner.id = 'live-unavailable';
  banner.setAttribute('role', 'status');
  banner.textContent = 'Live view unavailable.';
  if (typeof doc.body.prepend === 'function') {
    doc.body.prepend(banner);
  } else {
    doc.body.insertBefore(banner, doc.body.firstChild || null);
  }
}

function trapFocus(dlg, doc) {
  const handler = (event) => {
    if (event.key === 'Tab') {
      const focusable = Array.from(dlg.querySelectorAll(FOCUSABLE_SELECTOR)).filter((el) => !el.disabled);
      if (focusable.length === 0) return;
      const active = doc.activeElement;
      let idx = focusable.indexOf(active);
      if (idx === -1) {
        idx = 0;
      }
      event.preventDefault();
      if (event.shiftKey) {
        idx = idx <= 0 ? focusable.length - 1 : idx - 1;
      } else {
        idx = idx === focusable.length - 1 ? 0 : idx + 1;
      }
      focusable[idx].focus();
    } else if (event.key === 'Escape') {
      event.preventDefault();
      dlg.close('cancel');
    }
  };
  dlg.addEventListener('keydown', handler);
  return () => dlg.removeEventListener('keydown', handler);
}

async function openReplyDialog({ addr, authorPubkey, eventId, relays, doc, win, trigger }) {
  const dlg = doc.createElement('dialog');
  dlg.id = REPLY_DIALOG_ID;
  dlg.setAttribute('aria-modal', 'true');

  const form = doc.createElement('form');
  form.setAttribute('method', 'dialog');
  const textarea = doc.createElement('textarea');
  textarea.required = true;
  textarea.setAttribute('aria-label', 'Write a reply');

  const actions = doc.createElement('div');
  const send = doc.createElement('button');
  send.type = 'submit';
  send.textContent = 'Send';
  const cancel = doc.createElement('button');
  cancel.type = 'button';
  cancel.textContent = 'Cancel';
  cancel.addEventListener('click', () => dlg.close('cancel'));

  actions.append(send, cancel);
  form.append(textarea, actions);
  dlg.append(form);
  doc.body.append(dlg);

  const releaseFocus = trapFocus(dlg, doc);

  const cleanup = () => {
    if (releaseFocus) releaseFocus();
    dlg.remove();
    if (trigger) {
      trigger.setAttribute('aria-expanded', 'false');
      if (typeof trigger.focus === 'function') {
        trigger.focus();
      }
    }
  };

  dlg.addEventListener('close', cleanup, { once: true });
  dlg.addEventListener('cancel', (event) => {
    event.preventDefault();
    dlg.close('cancel');
  });

  if (trigger) {
    trigger.setAttribute('aria-controls', REPLY_DIALOG_ID);
    trigger.setAttribute('aria-expanded', 'true');
  }

  dlg.showModal();
  textarea.focus();

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    const content = textarea.value.trim();
    if (!content) return;

    const nostr = win.nostr;
    if (!nostr?.signEvent) {
      dlg.close('cancel');
      return;
    }

    const reply = {
      kind: 1,
      content,
      created_at: Math.floor(Date.now() / 1000),
      tags: [["a", addr]],
    };
    if (authorPubkey) {
      reply.tags.push(["p", authorPubkey]);
    }
    if (eventId) {
      reply.tags.push(["e", eventId, "", "root"]);
    }

    try {
      const signed = await nostr.signEvent(reply);
      await Promise.all(
        relays.map(
          (url) =>
            new Promise((resolve) => {
              let socket;
              try {
                socket = new win.WebSocket(url);
              } catch (err) {
                console.error('Failed to open relay', err);
                resolve();
                return;
              }
              const finalize = () => {
                socket.removeEventListener('close', finalize);
                socket.removeEventListener('error', finalize);
                resolve();
              };
              socket.addEventListener('open', () => {
                socket.send(JSON.stringify(["EVENT", signed]));
                socket.close();
              });
              socket.addEventListener('close', finalize);
              socket.addEventListener('error', finalize);
            })
        )
      );
      dlg.close('sent');
    } catch (err) {
      console.error('Failed to publish reply', err);
      showUnavailable(doc);
      dlg.close('error');
    }
  });
}

export function start(doc = document, win = window) {
  const body = doc?.body;
  if (!body) return;
  const addr = body.dataset?.addr;
  if (!addr) return;
  const eventId = body.dataset?.eventId;
  const authorPubkey = body.dataset?.authorPubkey || '';
  const limit = Number.parseInt(body.dataset?.limit || '80', 10) || 80;
  const showReply = body.dataset?.showReply === '1';
  const replyButton = doc.getElementById('reply-btn');
  const replies = doc.getElementById('replies');
  const loadMoreButton = doc.getElementById('load-more');
  if (loadMoreButton) {
    loadMoreButton.disabled = true;
    if (!loadMoreButton.hasAttribute('aria-controls')) {
      loadMoreButton.setAttribute('aria-controls', 'replies');
    }
  }
  const markRepliesBusy = (busy) => {
    if (!replies) return;
    if (busy) {
      replies.setAttribute('aria-busy', 'true');
    } else {
      replies.removeAttribute('aria-busy');
    }
  };
  markRepliesBusy(false);
  let replyClickBound = false;

  if (!win || typeof win.WebSocket !== 'function') {
    markRepliesBusy(false);
    showUnavailable(doc);
    return;
  }

  let relays = [];
  try {
    const parsed = JSON.parse(body.dataset?.relays || '[]');
    if (Array.isArray(parsed)) {
      relays = parsed.filter((entry) => typeof entry === 'string' && entry.trim().length > 0);
    }
  } catch (err) {
    console.error('Failed to parse relay list', err);
    markRepliesBusy(false);
    showUnavailable(doc);
    return;
  }
  const normalizedRelays = [];
  for (const entry of relays) {
    const normalized = normalizeRelayUrl(entry, win);
    if (normalized && !normalizedRelays.includes(normalized)) {
      normalizedRelays.push(normalized);
    }
  }
  if (normalizedRelays.length === 0) {
    markRepliesBusy(false);
    showUnavailable(doc);
    return;
  }

  const handleReplyClick = () =>
    openReplyDialog({ addr, authorPubkey, eventId, relays: normalizedRelays, doc, win, trigger: replyButton });

  let replyPollHandle = null;
  let nostrReadyHandler = null;
  let focusHandler = null;

  const cleanupReplyWatchers = () => {
    if (replyPollHandle !== null && typeof win.clearInterval === 'function') {
      win.clearInterval(replyPollHandle);
    }
    replyPollHandle = null;
    if (nostrReadyHandler && typeof win.removeEventListener === 'function') {
      win.removeEventListener('nostr:ready', nostrReadyHandler);
    }
    nostrReadyHandler = null;
    if (focusHandler && typeof win.removeEventListener === 'function') {
      win.removeEventListener('focus', focusHandler);
    }
    focusHandler = null;
  };

  const ensureReplyEnabled = () => {
    if (!showReply || !replyButton) return false;
    if (normalizedRelays.length === 0) return false;
    const nostr = win.nostr;
    if (!nostr || typeof nostr.signEvent !== 'function') return false;
    if (replyButton.hidden) {
      replyButton.hidden = false;
    }
    if (replyButton.getAttribute('aria-haspopup') !== 'dialog') {
      replyButton.setAttribute('aria-haspopup', 'dialog');
    }
    replyButton.setAttribute('aria-controls', REPLY_DIALOG_ID);
    if (!replyButton.hasAttribute('aria-expanded')) {
      replyButton.setAttribute('aria-expanded', 'false');
    }
    if (!replyClickBound) {
      replyButton.addEventListener('click', handleReplyClick);
      replyClickBound = true;
    }
    cleanupReplyWatchers();
    return true;
  };

  const startReplyWatchers = () => {
    if (!showReply || !replyButton) return;
    if (replyPollHandle !== null || nostrReadyHandler || focusHandler) return;
    if (ensureReplyEnabled()) return;
    if (typeof win.addEventListener === 'function') {
      nostrReadyHandler = () => {
        ensureReplyEnabled();
      };
      win.addEventListener('nostr:ready', nostrReadyHandler);
      focusHandler = () => {
        ensureReplyEnabled();
      };
      win.addEventListener('focus', focusHandler);
    }
    if (typeof win.setInterval === 'function' && typeof win.clearInterval === 'function') {
      const pollDelay = 500;
      replyPollHandle = win.setInterval(() => {
        if (ensureReplyEnabled()) {
          cleanupReplyWatchers();
        }
      }, pollDelay);
    } else {
      ensureReplyEnabled();
    }
  };

  startReplyWatchers();

  const CONNECTING_STATE = win.WebSocket?.CONNECTING ?? 0;
  const OPEN_STATE = win.WebSocket?.OPEN ?? 1;
  const CLOSING_STATE = win.WebSocket?.CLOSING ?? 2;
  const CLOSED_STATE = win.WebSocket?.CLOSED ?? 3;

  const seen = new Set();
  const reactionContainer = doc.getElementById('reactions');
  const reactionCounts = new Map();
  if (reactionContainer) {
    const spans = reactionContainer.querySelectorAll('[data-reaction]');
    for (const span of spans) {
      const key = span.dataset?.reaction;
      if (!key) continue;
      const value = parseInt(span.textContent || '0', 10);
      reactionCounts.set(key, Number.isNaN(value) ? 0 : value);
    }
  }
  let replyCount = 0;
  let oldestReplyTimestamp = null;
  const openSubs = new Set();
  let loadMoreSubs = null;
  let loadMoreHadResults = false;
  let loadMoreExhausted = false;
  let complete = true;
  let ws = null;
  let currentRelayIndex = -1;
  let intentionallyClosing = false;
  let reopenOnVisible = false;

  const cleanupSocketHandlers = (socket, handlers) => {
    if (!socket || !handlers) return;
    if (handlers.open) socket.removeEventListener('open', handlers.open);
    if (handlers.message) socket.removeEventListener('message', handlers.message);
    if (handlers.error) socket.removeEventListener('error', handlers.error);
    if (handlers.close) socket.removeEventListener('close', handlers.close);
  };

  const dispatchRequests = (socket, reqs, trackLoad = false) => {
    if (!socket || socket.readyState !== OPEN_STATE) {
      complete = openSubs.size === 0;
      markRepliesBusy(openSubs.size > 0);
      return;
    }
    if (!Array.isArray(reqs) || reqs.length === 0) {
      complete = openSubs.size === 0;
      markRepliesBusy(openSubs.size > 0);
      return;
    }
    const loadSet = trackLoad ? new Set() : null;
    for (const req of reqs) {
      if (!req || typeof req !== 'object' || !req.frame) continue;
      if (req.id) {
        openSubs.add(req.id);
        if (loadSet) {
          loadSet.add(req.id);
        }
        markRepliesBusy(true);
      }
      try {
        socket.send(JSON.stringify(req.frame));
      } catch (err) {
        console.error('Failed to send REQ', err);
      }
    }
    if (loadSet) {
      loadMoreSubs = loadSet;
      loadMoreHadResults = false;
    }
    complete = openSubs.size === 0;
    markRepliesBusy(openSubs.size > 0);
  };

  const connectToRelay = (startIndex = 0) => {
    if (normalizedRelays.length === 0) {
      markRepliesBusy(false);
      showUnavailable(doc);
      return;
    }
    const order = [];
    for (let i = startIndex; i < normalizedRelays.length; i += 1) {
      order.push(i);
    }
    for (let i = 0; i < startIndex; i += 1) {
      order.push(i);
    }
    for (const idx of order) {
      const url = normalizedRelays[idx];
      let socket;
      try {
        socket = new win.WebSocket(url);
      } catch (err) {
        console.error('Failed to open relay', err);
        continue;
      }
      currentRelayIndex = idx;
      intentionallyClosing = false;
      const handlers = {};
      let opened = false;

      handlers.open = () => {
        opened = true;
        reopenOnVisible = false;
        openSubs.clear();
        loadMoreSubs = null;
        complete = true;
        if (loadMoreButton) {
          loadMoreButton.disabled = true;
        }
        dispatchRequests(socket, buildReqs({ addr, eventId, limit }));
      };

      handlers.message = (event) => {
        let payload;
        try {
          payload = JSON.parse(event.data);
        } catch (err) {
          console.error('Ignoring malformed message', err);
          return;
        }
        if (!Array.isArray(payload)) return;
        const type = payload[0];
        const sub = payload[1];
        if (type === 'EVENT') {
          const evt = payload[2];
          if (!evt || typeof evt !== 'object') return;
          if (!dedupe(evt.id, seen)) return;
          if (evt.kind === 1) {
            const fromLoadMore = loadMoreSubs?.has(sub) === true;
            if (fromLoadMore) {
              loadMoreHadResults = true;
            }
            const append = fromLoadMore;
            renderReply(doc, replies, evt, { append });
            replyCount += 1;
            const created = Number(evt.created_at);
            if (Number.isFinite(created)) {
              const timestampMs = created * 1000;
              if (oldestReplyTimestamp === null || timestampMs < oldestReplyTimestamp) {
                oldestReplyTimestamp = timestampMs;
                if (loadMoreExhausted) {
                  loadMoreExhausted = false;
                }
              }
            }
            if (loadMoreButton) {
              if (replyCount >= limit && !loadMoreExhausted) {
                loadMoreButton.hidden = false;
                if (!loadMoreSubs) {
                  loadMoreButton.disabled = false;
                }
              } else if (loadMoreExhausted) {
                loadMoreButton.hidden = true;
                loadMoreButton.disabled = true;
              }
            }
          } else if (evt.kind === 7) {
            updateReactions(doc, reactionContainer, evt, reactionCounts);
          }
        } else if (type === 'EOSE') {
          if (typeof sub === 'string' && openSubs.has(sub)) {
            openSubs.delete(sub);
            complete = openSubs.size === 0;
            if (openSubs.size === 0) {
              markRepliesBusy(false);
            }
            if (socket.readyState === OPEN_STATE) {
              try {
                socket.send(JSON.stringify(['CLOSE', sub]));
              } catch (err) {
                console.error('Failed to close subscription', err);
              }
            }
          }
          if (loadMoreSubs?.has(sub)) {
            loadMoreSubs.delete(sub);
            if (loadMoreSubs.size === 0) {
              loadMoreSubs = null;
              if (loadMoreHadResults) {
                if (loadMoreButton) {
                  loadMoreButton.disabled = false;
                }
              } else {
                loadMoreExhausted = true;
                if (loadMoreButton) {
                  loadMoreButton.hidden = true;
                  loadMoreButton.disabled = true;
                }
              }
              loadMoreHadResults = false;
            }
          }
          markRepliesBusy(openSubs.size > 0);
        }
      };

      handlers.error = () => {
        if (intentionallyClosing) return;
        cleanupSocketHandlers(socket, handlers);
        if (!opened) {
          try {
            if (socket.readyState === OPEN_STATE || socket.readyState === CONNECTING_STATE) {
              socket.close();
            }
          } catch (err) {
            console.error('Failed to close failed relay', err);
          }
          ws = null;
          connectToRelay(idx + 1);
        } else {
          markRepliesBusy(false);
          showUnavailable(doc);
        }
      };

      handlers.close = () => {
        cleanupSocketHandlers(socket, handlers);
        if (ws === socket) {
          ws = null;
        }
        if (intentionallyClosing) {
          intentionallyClosing = false;
          return;
        }
        if (!opened) {
          connectToRelay(idx + 1);
        } else if (!complete) {
          markRepliesBusy(false);
          showUnavailable(doc);
        }
      };

      socket.addEventListener('open', handlers.open);
      socket.addEventListener('message', handlers.message);
      socket.addEventListener('error', handlers.error);
      socket.addEventListener('close', handlers.close);

      ws = socket;
      return;
    }
    markRepliesBusy(false);
    showUnavailable(doc);
  };

  connectToRelay(0);

  const closeSocket = ({ reopen = false, teardownReply = false } = {}) => {
    if (teardownReply) {
      cleanupReplyWatchers();
    }
    reopenOnVisible = reopen;
    markRepliesBusy(false);
    if (!ws) return;
    intentionallyClosing = true;
    try {
      if (ws.readyState === CONNECTING_STATE || ws.readyState === OPEN_STATE || ws.readyState === CLOSING_STATE) {
        ws.close();
      }
    } catch (err) {
      console.error('Failed to close relay', err);
    }
  };

  win.addEventListener('pagehide', () => closeSocket({ teardownReply: true }));
  doc.addEventListener('visibilitychange', () => {
    if (doc.visibilityState === 'hidden') {
      closeSocket({ reopen: true });
    } else if (doc.visibilityState === 'visible' && reopenOnVisible) {
      if (!ws || ws.readyState === CLOSED_STATE) {
        const start = currentRelayIndex >= 0 ? currentRelayIndex : 0;
        connectToRelay(start);
      }
      reopenOnVisible = false;
      if (replyButton && replyButton.hidden) {
        if (!ensureReplyEnabled()) {
          startReplyWatchers();
        }
      }
    }
  });

  if (loadMoreButton) {
    loadMoreButton.addEventListener('click', () => {
      if (loadMoreButton.disabled) return;
      if (loadMoreExhausted) return;
      if (loadMoreSubs && loadMoreSubs.size > 0) return;
      if (oldestReplyTimestamp === null) return;
      const untilSeconds = Math.floor(oldestReplyTimestamp / 1000) - 1;
      if (!Number.isFinite(untilSeconds) || untilSeconds <= 0) return;
      if (!ws || ws.readyState !== OPEN_STATE) return;
      loadMoreButton.disabled = true;
      const moreReqs = buildReqs({ addr, eventId, limit, until: untilSeconds });
      dispatchRequests(ws, moreReqs, true);
    });
  }

  }

if (typeof document !== 'undefined' && typeof window !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => start(document, window), { once: true });
  } else {
    start(document, window);
  }
}

export default { start, buildReqs, bucketReaction, dedupe, formatRelativeTime, normalizeRelayUrl };
