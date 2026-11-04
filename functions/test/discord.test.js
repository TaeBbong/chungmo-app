const {test} = require("node:test");
const assert = require("node:assert/strict");

const {LIMITS, post, toPayload} = require("../lib/discord");

const alert = {tag: "BUDGET", headline: "50% spent", color: 1};

test("puts the tag in content, where a push notification shows it", () => {
  assert.equal(toPayload(alert).content, "**[BUDGET]** 50% spent");
});

test("never lets alert text ping anyone", () => {
  // A crash title or config value can contain "@everyone".
  const payload = toPayload({...alert, headline: "@everyone crashed"});
  assert.deepEqual(payload.allowed_mentions, {parse: []});
});

test("drops empty fields, which Discord rejects", () => {
  const payload = toPayload({...alert, fields: [
    {name: "Kept", value: "x"},
    {name: "Undefined", value: undefined},
    {name: "Null", value: null},
    {name: "Empty", value: ""},
  ]});
  assert.deepEqual(payload.embeds[0].fields.map((f) => f.name), ["Kept"]);
});

test("cuts text to Discord's limits", () => {
  const payload = toPayload({...alert,
    headline: "x".repeat(3000),
    description: "y".repeat(5000),
    fields: [{name: "n", value: "z".repeat(2000)}]});
  assert.equal(payload.content.length, LIMITS.content);
  assert.equal(payload.embeds[0].description.length, LIMITS.description);
  assert.equal(payload.embeds[0].fields[0].value.length, LIMITS.fieldValue);
  assert.ok(payload.content.endsWith("…"));
});

test("links the embed only when there is a url", () => {
  assert.equal(toPayload(alert).embeds[0].url, undefined);
  const linked = toPayload({...alert, url: "https://x", linkText: "Go"}).embeds[0];
  assert.equal(linked.url, "https://x");
  assert.equal(linked.title, "Go");
});

test("throws on a refused post, so the caller logs it", async () => {
  const refuse = async () => ({ok: false, status: 400, text: async () => "bad"});
  await assert.rejects(post("https://hook", alert, refuse), /Discord answered 400: bad/);
});

test("throws when the secret is missing rather than posting nowhere", async () => {
  await assert.rejects(post("", alert, async () => assert.fail("posted")), /not set/);
});

test("posts the payload as JSON", async () => {
  let sent;
  const accept = async (url, init) => {
    sent = {url, init};
    return {ok: true};
  };
  await post("https://hook", alert, accept);
  assert.equal(sent.url, "https://hook");
  assert.equal(sent.init.method, "POST");
  assert.equal(JSON.parse(sent.init.body).content, "**[BUDGET]** 50% spent");
});
