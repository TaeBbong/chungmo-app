const {test} = require("node:test");
const assert = require("node:assert/strict");

const {once} = require("../lib/once");

/**
 * A bucket that honours ifGenerationMatch: 0 the way Cloud Storage does.
 * @return {object}
 */
function fakeBucket() {
  const objects = new Set();
  return {
    objects,
    file: (name) => ({
      save: async (_data, options) => {
        assert.equal(options.preconditionOpts.ifGenerationMatch, 0);
        if (objects.has(name)) throw Object.assign(new Error("exists"), {code: 412});
        objects.add(name);
      },
      delete: async () => {
        objects.delete(name);
      },
    }),
  };
}

test("runs the action once per key", async () => {
  const bucket = fakeBucket();
  let runs = 0;
  const action = async () => {
    runs++;
  };
  assert.equal(await once(bucket, "a", action), true);
  assert.equal(await once(bucket, "a", action), false);
  assert.equal(await once(bucket, "b", action), true);
  assert.equal(runs, 2);
});

test("releases the claim when the action fails, so a later delivery retries", async () => {
  const bucket = fakeBucket();
  await assert.rejects(once(bucket, "a", async () => {
    throw new Error("Discord down");
  }), /Discord down/);
  assert.equal(bucket.objects.has("a"), false);
  assert.equal(await once(bucket, "a", async () => {}), true);
});

test("surfaces a storage failure instead of treating it as claimed", async () => {
  const bucket = {file: () => ({save: async () => {
    throw Object.assign(new Error("forbidden"), {code: 403});
  }})};
  await assert.rejects(once(bucket, "a", async () => assert.fail("ran")), /forbidden/);
});
