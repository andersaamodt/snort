import test from "node:test";
import assert from "node:assert/strict";

class FakeNode extends EventTarget {
  constructor(doc) {
    super();
    this.ownerDocument = doc;
    this.parentNode = null;
    this.childNodes = [];
  }
}

class FakeText extends FakeNode {
  constructor(doc, value) {
    super(doc);
    this.text = value;
  }

  get textContent() {
    return this.text;
  }

  set textContent(value) {
    this.text = String(value);
  }
}

function createDatasetProxy(element) {
  const store = {};
  return new Proxy(store, {
    set(target, prop, value) {
      target[prop] = String(value);
      element._attributes.set(`data-${String(prop)}`, String(value));
      return true;
    },
    get(target, prop) {
      return target[prop];
    },
    deleteProperty(target, prop) {
      delete target[prop];
      element._attributes.delete(`data-${String(prop)}`);
      return true;
    },
  });
}

class FakeElement extends FakeNode {
  constructor(tagName, doc) {
    super(doc);
    this.tagName = tagName.toUpperCase();
    this._attributes = new Map();
    this.dataset = createDatasetProxy(this);
    this._id = "";
    this.className = "";
    if (this.tagName === "TEXTAREA") {
      this.value = "";
    }
  }

  get id() {
    return this._id;
  }

  set id(value) {
    const idStr = String(value);
    if (this._id === idStr) return;
    if (this.ownerDocument) {
      this.ownerDocument._unregisterId(this);
    }
    this._id = idStr;
    if (idStr && this.ownerDocument) {
      this.ownerDocument._registerId(idStr, this);
    }
    if (idStr) {
      this._attributes.set("id", idStr);
    } else {
      this._attributes.delete("id");
    }
  }

  setAttribute(name, value) {
    const val = String(value);
    if (name === "id") {
      this.id = val;
      return;
    }
    if (name === "class") {
      this.className = val;
    }
    this._attributes.set(name, val);
    if (name.startsWith("data-")) {
      const key = name.slice(5);
      this.dataset[key] = val;
    }
  }

  removeAttribute(name) {
    if (name === "id") {
      this.id = "";
      return;
    }
    if (name === "class") {
      this.className = "";
    }
    this._attributes.delete(name);
    if (name.startsWith("data-")) {
      const key = name.slice(5);
      delete this.dataset[key];
    }
  }

  getAttribute(name) {
    return this._attributes.has(name) ? this._attributes.get(name) : null;
  }

  hasAttribute(name) {
    return this._attributes.has(name);
  }

  append(...nodes) {
    for (const node of nodes) {
      this._insertNode(node, this.childNodes.length);
    }
  }

  appendChild(node) {
    this._insertNode(node, this.childNodes.length);
    return node;
  }

  prepend(...nodes) {
    let index = 0;
    for (const node of nodes) {
      this._insertNode(node, index);
      index += 1;
    }
  }

  insertBefore(node, reference) {
    const refIndex = reference ? this.childNodes.indexOf(reference) : -1;
    const index = refIndex >= 0 ? refIndex : this.childNodes.length;
    this._insertNode(node, index);
    return node;
  }

  _insertNode(node, index) {
    const adopted = this._normalizeNode(node);
    if (adopted.parentNode) {
      adopted.parentNode._removeChild(adopted);
    }
    adopted.parentNode = this;
    this.childNodes.splice(index, 0, adopted);
  }

  _normalizeNode(node) {
    if (typeof node === "string") {
      return this.ownerDocument.createTextNode(node);
    }
    return node;
  }

  _removeChild(child) {
    const idx = this.childNodes.indexOf(child);
    if (idx >= 0) {
      this.childNodes.splice(idx, 1);
      child.parentNode = null;
      if (child instanceof FakeElement && child.ownerDocument) {
        child.ownerDocument._unregisterId(child);
      }
    }
  }

  remove() {
    if (this.parentNode) {
      this.parentNode._removeChild(this);
    } else if (this.ownerDocument) {
      this.ownerDocument._unregisterId(this);
    }
  }

  get children() {
    return this.childNodes.filter((child) => child instanceof FakeElement);
  }

  querySelectorAll(selector) {
    const selectors = selector.split(",").map((s) => s.trim()).filter(Boolean);
    const results = [];
    const matchers = selectors.map((sel) => createMatcher(sel));
    const visit = (node) => {
      if (!(node instanceof FakeElement)) return;
      if (matchers.some((fn) => fn(node))) {
        results.push(node);
      }
      for (const child of node.childNodes) {
        visit(child);
      }
    };
    for (const child of this.childNodes) {
      visit(child);
    }
    return results;
  }

  querySelector(selector) {
    return this.querySelectorAll(selector)[0] || null;
  }

  get textContent() {
    let out = "";
    for (const child of this.childNodes) {
      if (child instanceof FakeElement) {
        out += child.textContent;
      } else if (child instanceof FakeText) {
        out += child.textContent;
      }
    }
    return out;
  }

  set textContent(value) {
    this.childNodes = [];
    if (value !== undefined && value !== null) {
      this.append(String(value));
    }
  }

  focus() {
    if (this.ownerDocument) {
      this.ownerDocument.activeElement = this;
    }
  }
}

class FakeDialog extends FakeElement {
  constructor(doc) {
    super("dialog", doc);
    this.open = false;
    this.returnValue = "";
  }

  showModal() {
    this.open = true;
    this.ownerDocument.activeElement = this;
  }

  close(value = "") {
    if (!this.open) return;
    this.returnValue = value;
    this.open = false;
    const event = new Event("close");
    this.dispatchEvent(event);
  }
}

class FakeDocument extends EventTarget {
  constructor() {
    super();
    this._ids = new Map();
    this.body = new FakeElement("body", this);
    this.visibilityState = "visible";
    this.readyState = "complete";
    this.activeElement = null;
  }

  createElement(tag) {
    return tag.toLowerCase() === "dialog" ? new FakeDialog(this) : new FakeElement(tag, this);
  }

  createTextNode(value) {
    return new FakeText(this, value);
  }

  getElementById(id) {
    return this._ids.get(id) || null;
  }

  _registerId(id, element) {
    this._ids.set(id, element);
  }

  _unregisterId(element) {
    if (!element || !element._id) return;
    const current = this._ids.get(element._id);
    if (current === element) {
      this._ids.delete(element._id);
    }
  }

  querySelectorAll(selector) {
    return this.body.querySelectorAll(selector);
  }

  querySelector(selector) {
    return this.body.querySelector(selector);
  }
}

class FakeWindow {
  constructor() {
    this._listeners = new Map();
    this.nostr = undefined;
    this._intervals = new Set();
  }

  addEventListener(type, handler) {
    const list = this._listeners.get(type) || [];
    list.push(handler);
    this._listeners.set(type, list);
  }

  removeEventListener(type, handler) {
    const list = this._listeners.get(type) || [];
    const idx = list.indexOf(handler);
    if (idx >= 0) {
      list.splice(idx, 1);
    }
  }

  dispatchEvent(event) {
    const list = this._listeners.get(event.type) || [];
    for (const handler of [...list]) {
      handler.call(this, event);
    }
  }

  setInterval(handler, delay) {
    const id = global.setInterval(handler, delay);
    this._intervals.add(id);
    return id;
  }

  clearInterval(id) {
    global.clearInterval(id);
    this._intervals.delete(id);
  }

  dispose() {
    for (const id of this._intervals) {
      global.clearInterval(id);
    }
    this._intervals.clear();
  }
}

class FakeWebSocket extends EventTarget {
  constructor(url) {
    super();
    this.url = url;
    this.readyState = FakeWebSocket.CONNECTING;
    this.sent = [];
    FakeWebSocket.instances.push(this);
    const behavior = FakeWebSocket.behaviors.get(url);
    if (behavior === "fail") {
      queueMicrotask(() => {
        this.dispatchEvent(new Event("error"));
        this.readyState = FakeWebSocket.CLOSING;
        this.readyState = FakeWebSocket.CLOSED;
        this.dispatchEvent(new Event("close"));
      });
      return;
    }
    queueMicrotask(() => {
      this.readyState = FakeWebSocket.OPEN;
      this.dispatchEvent(new Event("open"));
    });
  }

  send(payload) {
    this.sent.push(payload);
  }

  close() {
    if (this.readyState === FakeWebSocket.CLOSED) return;
    this.readyState = FakeWebSocket.CLOSED;
    this.dispatchEvent(new Event("close"));
  }

  emitMessage(data) {
    this.dispatchEvent(new MessageEvent("message", { data }));
  }

  emitError() {
    this.dispatchEvent(new Event("error"));
  }

  static reset() {
    FakeWebSocket.instances = [];
    FakeWebSocket.behaviors = new Map();
  }

  static setBehavior(url, behavior) {
    if (!behavior) {
      FakeWebSocket.behaviors.delete(url);
    } else {
      FakeWebSocket.behaviors.set(url, behavior);
    }
  }
}

FakeWebSocket.CONNECTING = 0;
FakeWebSocket.OPEN = 1;
FakeWebSocket.CLOSING = 2;
FakeWebSocket.CLOSED = 3;
FakeWebSocket.instances = [];
FakeWebSocket.behaviors = new Map();

function createMatcher(selector) {
  if (selector === "[data-reaction]") {
    return (el) => el.dataset && el.dataset.reaction !== undefined;
  }
  const match = selector.match(/^\[data-reaction="(.+)"\]$/);
  if (match) {
    const [, value] = match;
    return (el) => el.dataset && el.dataset.reaction === value;
  }
  if (selector.startsWith("#")) {
    const id = selector.slice(1);
    return (el) => el.id === id;
  }
  const tag = selector.toUpperCase();
  return (el) => el.tagName === tag;
}

const flush = () => new Promise((resolve) => setImmediate(resolve));

function setupDom() {
  const doc = new FakeDocument();
  const win = new FakeWindow();
  win.WebSocket = FakeWebSocket;
  win.location = {
    href: 'https://snort.test/posts/test-post',
    origin: 'https://snort.test',
    protocol: 'https:',
    host: 'snort.test',
  };
  doc.body.dataset.addr = "30023:pub:test-post";
  doc.body.dataset.eventId = "root-event";
  doc.body.dataset.limit = "5";
  doc.body.dataset.relays = JSON.stringify(["/nostr", "wss://relay.example"]);
  doc.body.dataset.showReply = "1";
  doc.body.dataset.authorPubkey = "authorpub";

  const main = doc.createElement("main");
  doc.body.append(main);
  const reactions = doc.createElement("aside");
  reactions.id = "reactions";
  const plus = doc.createElement("span");
  plus.dataset.reaction = "+";
  plus.textContent = "0";
  const heart = doc.createElement("span");
  heart.dataset.reaction = "❤️";
  heart.textContent = "0";
  reactions.append(plus, heart);
  doc.body.append(reactions);

  const replies = doc.createElement("section");
  replies.id = "replies";
  doc.body.append(replies);

  const loadMore = doc.createElement("button");
  loadMore.id = "load-more";
  loadMore.hidden = true;
  loadMore.disabled = true;
  doc.body.append(loadMore);

  const replyButton = doc.createElement("button");
  replyButton.id = "reply-btn";
  replyButton.hidden = true;
  doc.body.append(replyButton);

  return { doc, win };
}

function getArticles(container) {
  return container.childNodes.filter((node) => node instanceof FakeElement && node.tagName === "ARTICLE");
}

function ensureMessageEvent() {
  if (typeof MessageEvent === "undefined") {
    global.MessageEvent = class MessageEvent extends Event {
      constructor(type, init = {}) {
        super(type);
        this.data = init.data;
      }
    };
  }
}

function restoreMessageEvent(original) {
  if (original) {
    global.MessageEvent = original;
  } else if (typeof MessageEvent !== "undefined") {
    delete global.MessageEvent;
  }
}

test("start hydrates replies and reactions", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();
  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();
    const ws = FakeWebSocket.instances.at(-1);
    await flush();
    assert.ok(ws);
    assert.equal(ws.url, "wss://snort.test/nostr");

    const loadMore = doc.getElementById("load-more");
    assert.equal(loadMore.getAttribute("aria-controls"), "replies");

    const sentFrames = ws.sent.map((raw) => JSON.parse(raw));
    assert.equal(sentFrames.length, 2);
    const subIds = sentFrames.map((frame) => frame[1]);
    const subA = subIds[0];
    assert.ok(subA);
    const subE = subIds[1];

    const replies = doc.getElementById("replies");
    assert.equal(replies.getAttribute("aria-busy"), "true");
    assert.equal(getArticles(replies).length, 0);

    ws.emitMessage(JSON.stringify(["EVENT", subA, { id: "react1", kind: 7, content: "🔥", tags: [], created_at: Math.floor(Date.now() / 1000) }]));
    const reactionSpans = doc.getElementById("reactions").querySelectorAll("[data-reaction]");
    const flame = reactionSpans.find((el) => el.dataset.reaction === "🔥");
    assert.ok(flame);
    assert.equal(flame.textContent, "1");

    const replyEvent = {
      id: "reply1",
      kind: 1,
      content: "<b>Hi</b>\nSecond",
      pubkey: "abcdef1234567890abcdef1234567890abcdef12",
      created_at: Math.floor((Date.now() - 90_000) / 1000),
    };
    ws.emitMessage(JSON.stringify(["EVENT", subA, replyEvent]));
    const articles = getArticles(replies);
    assert.equal(articles.length, 1);
    const article = articles[0];
    assert.equal(article.querySelectorAll("script").length, 0);
    assert.ok(article.textContent.includes("<b>Hi</b>"));
    const timeEl = article.querySelector("time");
    assert.ok(timeEl);
    assert.ok(timeEl.getAttribute("datetime"));
    assert.ok(timeEl.textContent.length > 0);

    ws.emitMessage(JSON.stringify(["EVENT", subA, replyEvent]));
    assert.equal(getArticles(replies).length, 1);

    ws.emitMessage(JSON.stringify(["EOSE", subA]));
    const closeFrame = ws.sent.map((raw) => JSON.parse(raw)).find((frame) => frame[0] === "CLOSE" && frame[1] === subA);
    assert.ok(closeFrame);

    if (subE) {
      ws.emitMessage(JSON.stringify(["EOSE", subE]));
    }
    await flush();
    assert.equal(replies.getAttribute("aria-busy"), null);

    ws.emitError();
    const banner = doc.getElementById("live-unavailable");
    assert.ok(banner);
    assert.equal(banner.textContent, "Live view unavailable.");

    const button = doc.getElementById("reply-btn");
    assert.equal(button.hidden, true);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("replies stay sorted when events arrive out of order", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();
  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();
    const ws = FakeWebSocket.instances.at(-1);
    await flush();
    assert.ok(ws);

    const sentFrames = ws.sent.map((raw) => JSON.parse(raw));
    const reqFrames = sentFrames.filter((frame) => frame[0] === "REQ");
    const subA = reqFrames[0][1];
    assert.ok(subA);

    const replies = doc.getElementById("replies");
    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-new", kind: 1, content: "New", created_at: 200, pubkey: "npub-new" },
      ])
    );
    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-old", kind: 1, content: "Old", created_at: 100, pubkey: "npub-old" },
      ])
    );
    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-newest", kind: 1, content: "Newest", created_at: 300, pubkey: "npub-newest" },
      ])
    );

    const order = getArticles(replies).map((article) => article.dataset.eventId);
    assert.deepEqual(order, ["reply-newest", "reply-new", "reply-old"]);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("load more fetches older replies", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();
  doc.body.dataset.limit = "2";
  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();
    const ws = FakeWebSocket.instances.at(-1);
    await flush();
    assert.ok(ws);

    const sentFrames = ws.sent.map((raw) => JSON.parse(raw));
    const reqFrames = sentFrames.filter((frame) => frame[0] === "REQ");
    assert.equal(reqFrames.length, 2);
    const subA = reqFrames[0][1];
    assert.ok(subA);
    const subE = reqFrames[1][1];

    const loadMore = doc.getElementById("load-more");
    assert.ok(loadMore);
    assert.equal(loadMore.hidden, true);
    assert.equal(loadMore.disabled, true);

    const replies = doc.getElementById("replies");
    assert.equal(replies.getAttribute("aria-busy"), "true");
    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-old", kind: 1, content: "Old", created_at: 100, pubkey: "oldpub" },
      ])
    );
    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-new", kind: 1, content: "New", created_at: 200, pubkey: "newpub" },
      ])
    );

    const initialOrder = getArticles(replies).map((article) => article.dataset.eventId);
    assert.deepEqual(initialOrder, ["reply-new", "reply-old"]);
    assert.equal(loadMore.hidden, false);
    assert.equal(loadMore.disabled, false);

    ws.emitMessage(JSON.stringify(["EOSE", subA]));
    if (subE) {
      ws.emitMessage(JSON.stringify(["EOSE", subE]));
    }
    await flush();
    assert.equal(replies.getAttribute("aria-busy"), null);

    loadMore.dispatchEvent(new Event("click"));
    assert.equal(loadMore.disabled, true);
    assert.equal(replies.getAttribute("aria-busy"), "true");

    const loadFrames = ws.sent.slice(-2).map((raw) => JSON.parse(raw));
    const loadReq = loadFrames.find((frame) => frame[2] && frame[2]["#a"]);
    assert.ok(loadReq);
    assert.equal(loadReq[2].until, 99);
    const loadSub = loadReq[1];
    assert.ok(loadSub);

    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        loadSub,
        { id: "reply-oldest", kind: 1, content: "Older", created_at: 50, pubkey: "older" },
      ])
    );

    const afterLoadOrder = getArticles(replies).map((article) => article.dataset.eventId);
    assert.deepEqual(afterLoadOrder, ["reply-new", "reply-old", "reply-oldest"]);

    for (const frame of loadFrames) {
      ws.emitMessage(JSON.stringify(["EOSE", frame[1]]));
    }
    await flush();
    assert.equal(replies.getAttribute("aria-busy"), null);
    assert.equal(loadMore.disabled, false);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("load more hides when no older replies remain", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();
  doc.body.dataset.limit = "2";
  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();
    const ws = FakeWebSocket.instances.at(-1);
    await flush();
    assert.ok(ws);

    const sentFrames = ws.sent.map((raw) => JSON.parse(raw));
    const reqFrames = sentFrames.filter((frame) => frame[0] === "REQ");
    assert.equal(reqFrames.length, 2);
    const subA = reqFrames[0][1];
    assert.ok(subA);
    const subE = reqFrames[1][1];

    const replies = doc.getElementById("replies");
    assert.equal(replies.getAttribute("aria-busy"), "true");
    const loadMore = doc.getElementById("load-more");
    assert.ok(loadMore);

    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-old", kind: 1, content: "Old", created_at: 100, pubkey: "oldpub" },
      ])
    );
    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-new", kind: 1, content: "New", created_at: 200, pubkey: "newpub" },
      ])
    );

    assert.equal(loadMore.hidden, false);
    assert.equal(loadMore.disabled, false);

    ws.emitMessage(JSON.stringify(["EOSE", subA]));
    if (subE) {
      ws.emitMessage(JSON.stringify(["EOSE", subE]));
    }
    await flush();
    assert.equal(replies.getAttribute("aria-busy"), null);

    const beforeLoad = ws.sent.length;
    loadMore.dispatchEvent(new Event("click"));
    assert.equal(loadMore.disabled, true);
    assert.equal(replies.getAttribute("aria-busy"), "true");

    const newFrames = ws.sent
      .slice(beforeLoad)
      .map((raw) => JSON.parse(raw))
      .filter((frame) => frame[0] === "REQ");
    assert.ok(newFrames.length > 0);

    for (const frame of newFrames) {
      ws.emitMessage(JSON.stringify(["EOSE", frame[1]]));
    }
    await flush();
    assert.equal(replies.getAttribute("aria-busy"), null);

    assert.equal(loadMore.hidden, true);
    assert.equal(loadMore.disabled, true);

    const afterHideCount = ws.sent.length;
    loadMore.dispatchEvent(new Event("click"));
    assert.equal(ws.sent.length, afterHideCount);

    ws.emitMessage(
      JSON.stringify([
        "EVENT",
        subA,
        { id: "reply-older", kind: 1, content: "Older", created_at: 50, pubkey: "older" },
      ])
    );

    const order = getArticles(replies).map((article) => article.dataset.eventId);
    assert.deepEqual(order, ["reply-new", "reply-old", "reply-older"]);
    assert.equal(loadMore.hidden, false);
    assert.equal(loadMore.disabled, false);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("reply dialog publishes signed events to configured relays", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();
  const signedEvents = [];
  win.nostr = {
    async signEvent(event) {
      signedEvents.push(event);
      return { ...event, id: "signed", sig: "signature", pubkey: "npub" };
    },
  };

  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();

    const button = doc.getElementById("reply-btn");
    assert.equal(button.hidden, false);
    assert.equal(button.getAttribute("aria-haspopup"), "dialog");
    assert.equal(button.getAttribute("aria-controls"), "reply-dialog");
    assert.equal(button.getAttribute("aria-expanded"), "false");

    button.dispatchEvent(new Event("click"));

    assert.equal(button.getAttribute("aria-expanded"), "true");

    const dialog = doc.querySelector("#reply-dialog");
    assert.ok(dialog);
    const textarea = dialog.querySelector("textarea");
    assert.equal(doc.activeElement, textarea);
    textarea.value = "Hello there";

    const form = dialog.querySelector("form");
    const submitEvent = new Event("submit", { cancelable: true });
    form.dispatchEvent(submitEvent);

    await flush();
    await flush();

    assert.equal(signedEvents.length, 1);
    assert.equal(signedEvents[0].kind, 1);
    assert.deepEqual(signedEvents[0].tags, [
      ["a", "30023:pub:test-post"],
      ["p", "authorpub"],
      ["e", "root-event", "", "root"],
    ]);

    const sockets = FakeWebSocket.instances;
    assert.equal(sockets.length, 3);
    const publishSockets = sockets.slice(1);
    const urls = publishSockets.map((socket) => socket.url).sort();
    assert.deepEqual(urls, ["wss://relay.example/", "wss://snort.test/nostr"]);

    for (const socket of publishSockets) {
      const frames = socket.sent.map((raw) => JSON.parse(raw));
      assert.equal(frames.length, 1);
      assert.equal(frames[0][0], "EVENT");
      assert.equal(frames[0][1].id, "signed");
    }

    await flush();
    assert.equal(button.getAttribute("aria-expanded"), "false");
    assert.equal(doc.activeElement, button);
    assert.equal(doc.querySelector("#reply-dialog"), null);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("reply button stays hidden when configuration disables it", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();
  doc.body.dataset.showReply = "0";
  win.nostr = {
    async signEvent(event) {
      return event;
    },
  };

  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();

    const button = doc.getElementById("reply-btn");
    assert.equal(button.hidden, true);
    assert.equal(button.hasAttribute("aria-haspopup"), false);
    assert.equal(button.hasAttribute("aria-controls"), false);
    assert.equal(button.hasAttribute("aria-expanded"), false);
    assert.equal(win._listeners.has("nostr:ready"), false);
    assert.equal(win._listeners.has("focus"), false);
    assert.equal(win._intervals.size, 0);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("reply button appears when nostr becomes available later", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();

  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();

    const button = doc.getElementById("reply-btn");
    assert.equal(button.hidden, true);

    win.nostr = {
      async signEvent(event) {
        return event;
      },
    };

    win.dispatchEvent(new Event("nostr:ready"));

    await flush();

    assert.equal(button.hidden, false);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("reply button polling detects nostr without events", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;
  const originalSetInterval = global.setInterval;
  const originalClearInterval = global.clearInterval;

  const handlers = new Map();
  const cleared = new Set();
  let nextId = 1;

  global.setInterval = (fn) => {
    const id = nextId;
    nextId += 1;
    handlers.set(id, fn);
    return id;
  };

  global.clearInterval = (id) => {
    cleared.add(id);
    handlers.delete(id);
  };

  const { doc, win } = setupDom();

  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();

    const button = doc.getElementById("reply-btn");
    assert.equal(button.hidden, true);
    const entries = [...handlers.entries()];
    assert.equal(entries.length, 1);
    const [intervalId, tick] = entries[0];

    win.nostr = {
      async signEvent(event) {
        return event;
      },
    };

    tick();

    await flush();

    assert.equal(button.hidden, false);
    assert.ok(cleared.has(intervalId));
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
    global.setInterval = originalSetInterval;
    global.clearInterval = originalClearInterval;
  }
});

test("start falls back to next relay when primary fails", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();

  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    FakeWebSocket.setBehavior("wss://snort.test/nostr", "fail");
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();
    await flush();

    const sockets = FakeWebSocket.instances;
    assert.ok(sockets.length >= 2);
    const primary = sockets[0];
    const fallback = sockets.at(-1);
    assert.notEqual(primary, fallback);
    assert.equal(fallback.url, "wss://relay.example/");

    const reqFrames = fallback.sent.map((raw) => JSON.parse(raw)).filter((frame) => frame[0] === "REQ");
    assert.equal(reqFrames.length, 2);
    const subId = reqFrames[0][1];
    assert.ok(subId);

    fallback.emitMessage(
      JSON.stringify([
        "EVENT",
        subId,
        { id: "fallback-reply", kind: 1, content: "Hi", created_at: Math.floor(Date.now() / 1000), pubkey: "fallback" },
      ])
    );

    const replies = doc.getElementById("replies");
    assert.equal(getArticles(replies).length, 1);
    assert.equal(doc.getElementById("live-unavailable"), null);
  } finally {
    FakeWebSocket.setBehavior("wss://snort.test/nostr", null);
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("start reconnects when page becomes visible again", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;
  const originalMessageEvent = typeof MessageEvent === "undefined" ? null : MessageEvent;

  const { doc, win } = setupDom();

  global.document = doc;
  global.window = win;
  ensureMessageEvent();

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();
    const first = FakeWebSocket.instances.at(-1);
    await flush();
    assert.ok(first);

    const initialReqs = first.sent.map((raw) => JSON.parse(raw)).filter((frame) => frame[0] === "REQ");
    assert.ok(initialReqs.length >= 1);
    const initialSub = initialReqs[0][1];
    first.emitMessage(
      JSON.stringify([
        "EVENT",
        initialSub,
        { id: "initial", kind: 1, content: "One", created_at: Math.floor(Date.now() / 1000), pubkey: "first" },
      ])
    );

    doc.visibilityState = "hidden";
    doc.dispatchEvent(new Event("visibilitychange"));
    await flush();
    assert.equal(first.readyState, FakeWebSocket.CLOSED);

    doc.visibilityState = "visible";
    doc.dispatchEvent(new Event("visibilitychange"));
    await flush();

    const sockets = FakeWebSocket.instances;
    assert.ok(sockets.length >= 2);
    const reopened = sockets.at(-1);
    assert.notEqual(reopened, first);
    assert.equal(reopened.url, first.url);

    const newReqs = reopened.sent.map((raw) => JSON.parse(raw)).filter((frame) => frame[0] === "REQ");
    assert.ok(newReqs.length >= 1);
    const newSub = newReqs[0][1];
    reopened.emitMessage(
      JSON.stringify([
        "EVENT",
        newSub,
        { id: "resumed", kind: 1, content: "Two", created_at: Math.floor(Date.now() / 1000), pubkey: "second" },
      ])
    );

    const replies = doc.getElementById("replies");
    const ids = getArticles(replies).map((article) => article.dataset.eventId);
    assert.deepEqual(ids, ["resumed", "initial"]);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
    restoreMessageEvent(originalMessageEvent);
  }
});

test("start shows banner when WebSocket unsupported", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;

  const { doc, win } = setupDom();
  win.WebSocket = undefined;

  global.document = doc;
  global.window = win;

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();

    const banner = doc.getElementById("live-unavailable");
    assert.ok(banner);
    assert.equal(banner.textContent, "Live view unavailable.");
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
  }
});

test("start handles invalid relay config", async () => {
  FakeWebSocket.reset();
  const originalDocument = global.document;
  const originalWindow = global.window;

  const { doc, win } = setupDom();
  doc.body.dataset.relays = "not-json";

  global.document = doc;
  global.window = win;

  try {
    const module = await import("../static/js/snort.js");
    module.start(doc, win);

    await flush();

    const banner = doc.getElementById("live-unavailable");
    assert.ok(banner);
  } finally {
    win.dispose?.();
    global.document = originalDocument;
    global.window = originalWindow;
  }
});
