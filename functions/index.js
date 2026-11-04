/**
 * Operational alerts for chungmo, relayed to one Discord channel.
 *
 * Each source gets its own tag (lib/messages.js). Setup, the GCP resources
 * these depend on and how to test them are in docs/ALERTS.md.
 */

const {setGlobalOptions} = require("firebase-functions/v2");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const crashlytics = require("firebase-functions/v2/alerts/crashlytics");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {onConfigUpdated} = require("firebase-functions/v2/remoteConfig");
const {initializeApp} = require("firebase-admin/app");
const {getRemoteConfig} = require("firebase-admin/remote-config");
const {getStorage} = require("firebase-admin/storage");

const discord = require("./lib/discord");
const messages = require("./lib/messages");
const {once} = require("./lib/once");

initializeApp();

const webhook = defineSecret("DISCORD_WEBHOOK_URL");

/** Pub/Sub topics the Monitoring channel and the budget publish to. */
const MONITORING_TOPIC = "ops-alerts";
const BUDGET_TOPIC = "billing-budget-alerts";

/** Holds the once-per-threshold claims for budget alerts. */
const STATE_BUCKET = "chung-mo-alert-state";

// One instance is plenty for a handful of alerts a month, and caps what a
// flood of events could cost.
setGlobalOptions({region: "us-central1", memory: "256MiB", maxInstances: 1, secrets: [webhook]});

/**
 * Posts [alert], logging instead of throwing: the event is not retried, and
 * the email channels remain the fallback.
 * @param {object|null} alert
 * @param {string} source
 */
async function send(alert, source) {
  if (!alert) return;
  try {
    await discord.post(webhook.value(), alert);
    logger.info(`Posted ${source} alert`, {headline: alert.headline});
  } catch (error) {
    logger.error(`Could not post ${source} alert`, error);
  }
}

/**
 * @param {string} kind
 * @return {function(object): Promise<void>}
 */
const crashlyticsHandler = (kind) => (event) =>
  send(messages.crashlytics(kind, event), `crashlytics ${kind}`);

exports.crashlyticsNewFatal =
  crashlytics.onNewFatalIssuePublished(crashlyticsHandler("newFatal"));
exports.crashlyticsNewNonfatal =
  crashlytics.onNewNonfatalIssuePublished(crashlyticsHandler("newNonfatal"));
exports.crashlyticsNewAnr =
  crashlytics.onNewAnrIssuePublished(crashlyticsHandler("newAnr"));
exports.crashlyticsRegression =
  crashlytics.onRegressionAlertPublished(crashlyticsHandler("regression"));
exports.crashlyticsVelocity =
  crashlytics.onVelocityAlertPublished(crashlyticsHandler("velocity"));
exports.crashlyticsTrending =
  crashlytics.onStabilityDigestPublished(crashlyticsHandler("stabilityDigest"));

exports.monitoringIncident = onMessagePublished(MONITORING_TOPIC, (event) =>
  send(messages.monitoringIncident(event.data.message.json), "monitoring"));

exports.budgetThreshold = onMessagePublished(BUDGET_TOPIC, async (event) => {
  const message = event.data.message;
  const result = messages.budget(message.json, message.attributes ?? {});
  if (!result) return;
  try {
    const posted = await once(getStorage().bucket(STATE_BUCKET), `budget/${result.key}`,
        () => discord.post(webhook.value(), result.alert));
    logger.info(posted ? "Posted budget alert" : "Budget threshold already posted",
        {key: result.key});
  } catch (error) {
    logger.error("Could not post budget alert", error);
  }
});

exports.remoteConfigPublished = onConfigUpdated(async (event) => {
  const update = event.data;
  const rc = getRemoteConfig();
  let alert;
  try {
    const after = await rc.getTemplateAtVersion(update.versionNumber);
    const before = update.versionNumber > 1 ?
      await rc.getTemplateAtVersion(update.versionNumber - 1) :
      undefined;
    alert = messages.remoteConfigChange(update, before, after);
  } catch (error) {
    // Still say that something was published, without the diff.
    logger.error("Could not read the templates to diff", error);
    alert = messages.remoteConfigChange(update, undefined, undefined);
    alert.description = "Could not read the templates to show what changed.";
  }
  await send(alert, "remote config");
});
