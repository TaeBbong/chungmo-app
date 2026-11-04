const {describe, test} = require("node:test");
const assert = require("node:assert/strict");

const m = require("../lib/messages");

const IOS = "1:655915725465:ios:dea0d48ec5ee142678fe08";
const ANDROID = "1:655915725465:android:d8efeeaaaf1b77f178fe08";

const issue = {id: "abc123", title: "ScheduleRepository.save", subtitle: "StateError",
  appVersion: "2.1.0 (12)"};

/**
 * A Crashlytics CloudEvent, shaped as firebase-functions 7.4.0 types it.
 * @param {object} payload
 * @param {string} [appId]
 * @return {object}
 */
const crash = (payload, appId = IOS) => ({appId, data: {createTime: "", payload}});

describe("crashlytics", () => {
  test("tags every kind and names the platform and version", () => {
    for (const kind of ["newFatal", "newNonfatal", "newAnr", "regression", "velocity"]) {
      const alert = m.crashlytics(kind, crash({issue, crashCount: 3, crashPercentage: 1.5}));
      assert.equal(alert.tag, "CRASHLYTICS", kind);
      assert.match(alert.headline, /ScheduleRepository\.save/, kind);
      assert.match(alert.headline, /iOS/, kind);
    }
  });

  test("links the issue in the right app's console", () => {
    assert.equal(m.crashlytics("newFatal", crash({issue})).url,
        "https://console.firebase.google.com/project/chung-mo/crashlytics/app/" +
        "ios:com.taebbong.chungmoapp/issues/abc123");
    assert.match(m.crashlytics("newFatal", crash({issue}, ANDROID)).url,
        /app\/android:com\.taebbong\.chungmo\/issues\/abc123$/);
  });

  test("still links somewhere for an app it does not know", () => {
    const alert = m.crashlytics("newFatal", crash({issue}, "1:0:ios:unknown"));
    assert.equal(alert.url, "https://console.firebase.google.com/project/chung-mo/crashlytics");
    assert.match(alert.headline, /1:0:ios:unknown/);
  });

  test("ranks fatal above non-fatal by colour", () => {
    assert.equal(m.crashlytics("newFatal", crash({issue})).color, m.COLORS.critical);
    assert.equal(m.crashlytics("newNonfatal", crash({issue})).color, m.COLORS.warning);
  });

  test("says how big a velocity spike is", () => {
    const alert = m.crashlytics("velocity", crash({issue, crashCount: 7,
      crashPercentage: 12.5, firstVersion: "2.0.2", createTime: ""}));
    assert.match(alert.headline, /12\.5% of users/);
    assert.deepEqual(alert.fields.find((f) => f.name === "Crashes").value, "7");
    assert.equal(alert.fields.find((f) => f.name === "First seen in").value, "2.0.2");
  });

  test("lists at most ten trending issues", () => {
    const trendingIssues = Array.from({length: 12}, (_, i) => ({
      type: "fatal", eventCount: i, userCount: 1, issue: {...issue, title: `issue ${i}`}}));
    const alert = m.crashlytics("stabilityDigest",
        crash({digestDate: "2026-11-04T00:00:00Z", trendingIssues}));
    assert.match(alert.headline, /^12 trending issues on iOS \(2026-11-04\)$/);
    assert.equal(alert.description.split("\n").length, 10);
  });

  test("stays silent on an empty digest", () => {
    assert.equal(m.crashlytics("stabilityDigest", crash({trendingIssues: []})), null);
  });

  test("refuses an alert kind it was not written for", () => {
    assert.throws(() => m.crashlytics("newSomething", crash({issue})), /Unknown/);
  });
});

/**
 * A Monitoring notification with the fields of schema 1.2.
 * @param {object} overrides
 * @return {object}
 */
const incident = (overrides = {}) => ({version: "1.2", incident: {
  incident_id: "0.abc",
  url: "https://console.cloud.google.com/monitoring/alerting/incidents/0.abc?project=chung-mo",
  state: "open",
  started_at: 1793799000,
  ended_at: null,
  policy_name: "chungmo AI backend is refusing requests",
  policy_user_labels: {discord_tag: "ai-outage"},
  condition_name: "Non-2xx responses",
  threshold_value: "2",
  observed_value: "8",
  documentation: {content: "402/429: top up. 404: change model_name.", mime_type: "text/markdown"},
  summary: "Request count for consumed_api is above the threshold of 2 with a value of 8.",
  ...overrides,
}});

describe("monitoringIncident", () => {
  test("takes its tag from the policy's discord_tag label", () => {
    assert.equal(m.monitoringIncident(incident()).tag, "AI-OUTAGE");
    assert.equal(m.monitoringIncident(incident({policy_user_labels: {discord_tag: "app-check"}}))
        .tag, "APP-CHECK");
  });

  test("falls back to a generic tag for an unlabelled policy", () => {
    assert.equal(m.monitoringIncident(incident({policy_user_labels: {}})).tag, "MONITORING");
    assert.equal(m.monitoringIncident(incident({policy_user_labels: undefined})).tag,
        "MONITORING");
  });

  test("carries the runbook and the numbers while open", () => {
    const alert = m.monitoringIncident(incident());
    assert.equal(alert.headline, "chungmo AI backend is refusing requests");
    assert.equal(alert.color, m.COLORS.critical);
    assert.match(alert.description, /change model_name/);
    assert.equal(alert.fields.find((f) => f.name === "Observed").value, "8 (threshold 2)");
    assert.equal(alert.fields.find((f) => f.name === "Started").value, "<t:1793799000:f>");
  });

  test("reports the close as resolved, without the runbook", () => {
    const alert = m.monitoringIncident(incident({state: "closed", ended_at: 1793800800}));
    assert.equal(alert.headline, "Resolved: chungmo AI backend is refusing requests");
    assert.equal(alert.color, m.COLORS.resolved);
    assert.equal(alert.description, undefined);
    assert.equal(alert.fields.find((f) => f.name === "Ended").value, "<t:1793800800:f>");
  });
});

describe("budget", () => {
  // The documented schema 1.0 body, with the project's currency.
  const body = (overrides = {}) => ({
    budgetDisplayName: "chungmo monthly",
    costAmount: 1612.4,
    costIntervalStart: "2026-11-01T07:00:00Z",
    budgetAmount: 3000,
    budgetAmountType: "SPECIFIED_AMOUNT",
    alertThresholdExceeded: 0.5,
    currencyCode: "KRW",
    ...overrides,
  });
  const attributes = {billingAccountId: "01328E-B50B71-F94ED5", budgetId: "b-1",
    schemaVersion: "1.0"};

  test("says nothing until a threshold is crossed", () => {
    // Budgets publish several times a day with no threshold key at all.
    const {alertThresholdExceeded: _, ...below} = body();
    assert.equal(m.budget(below, attributes), null);
  });

  test("keys the alert by budget, month and threshold", () => {
    assert.equal(m.budget(body(), attributes).key, "b-1/2026-11-01T07:00:00Z/50");
    // A later notification in the same month at the same threshold, with a
    // higher cost, must be recognised as the same alert.
    assert.equal(m.budget(body({costAmount: 1800}), attributes).key,
        m.budget(body(), attributes).key);
    assert.notEqual(m.budget(body({alertThresholdExceeded: 0.9}), attributes).key,
        m.budget(body(), attributes).key);
    assert.notEqual(m.budget(body({costIntervalStart: "2026-12-01T08:00:00Z"}), attributes).key,
        m.budget(body(), attributes).key);
  });

  test("states spend against the budget in won", () => {
    const {alert} = m.budget(body(), attributes);
    assert.equal(alert.tag, "BUDGET");
    assert.equal(alert.headline, "50% of \"chungmo monthly\" spent: ₩1,612 of ₩3,000");
    assert.equal(alert.color, m.COLORS.warning);
  });

  test("turns red once the budget is spent", () => {
    assert.equal(m.budget(body({alertThresholdExceeded: 1}), attributes).alert.color,
        m.COLORS.critical);
  });
});

describe("remoteConfigChange", () => {
  const template = (model, extra = {}) => ({
    parameters: {model_name: {defaultValue: {value: model}, valueType: "STRING"}, ...extra},
  });
  const update = (overrides = {}) => ({versionNumber: 3, updateTime: "2026-11-04T12:00:00Z",
    updateOrigin: "CONSOLE", updateType: "INCREMENTAL_UPDATE",
    updateUser: {name: "Someone", email: "someone@example.com"}, ...overrides});

  test("puts a single change in the headline", () => {
    const alert = m.remoteConfigChange(update(),
        template("gemini-3.5-flash-lite"), template("gemini-4-flash-lite"));
    assert.equal(alert.tag, "REMOTE-CONFIG");
    assert.equal(alert.headline,
        "v3: model_name \"gemini-3.5-flash-lite\" → \"gemini-4-flash-lite\"");
    assert.equal(alert.fields.find((f) => f.name === "Published from").value, "the console");
  });

  test("never sends the publisher's identity to Discord", () => {
    const alert = m.remoteConfigChange(update(), template("a"), template("b"));
    assert.doesNotMatch(JSON.stringify(alert), /someone@example\.com|Someone/);
  });

  test("lists added, removed and changed parameters, grouped ones included", () => {
    const before = {parameters: {a: {defaultValue: {value: "1"}}, gone: {defaultValue: {value: "x"}}}};
    const after = {
      parameters: {a: {defaultValue: {value: "2"}}},
      parameterGroups: {ai: {parameters: {fresh: {defaultValue: {useInAppDefault: true}}}}},
    };
    assert.deepEqual(m.diffParameters(before, after), [
      {key: "a", change: "changed", from: "\"1\"", to: "\"2\""},
      {key: "fresh", change: "added", to: "(in-app default)"},
      {key: "gone", change: "removed", from: "\"x\""},
    ]);
    const alert = m.remoteConfigChange(update(), before, after);
    assert.equal(alert.headline, "v3: 3 parameters changed");
    assert.match(alert.description, /~ a: "1" → "2"\n\+ fresh = \(in-app default\)\n- gone/);
  });

  test("notices a conditional value changing under the same default", () => {
    const before = template("m");
    const after = template("m");
    after.parameters.model_name.conditionalValues = {ios: {value: "other"}};
    const [change] = m.diffParameters(before, after);
    assert.equal(change.to, "\"m\" (+1 conditional)");
  });

  test("says so when no parameter changed", () => {
    const alert = m.remoteConfigChange(update(), template("m"), template("m"));
    assert.equal(alert.headline, "v3: no parameters changed");
    assert.match(alert.description, /No parameter changed/);
  });

  test("names a rollback by the version it restores", () => {
    const alert = m.remoteConfigChange(update({updateType: "ROLLBACK", rollbackSource: 1}),
        template("b"), template("a"));
    assert.equal(alert.headline, "v3 rolls back to v1");
  });

  test("handles the first version, which has nothing before it", () => {
    const alert = m.remoteConfigChange(update({versionNumber: 1}), undefined, template("m"));
    assert.equal(alert.headline, "v1: model_name added");
  });
});
