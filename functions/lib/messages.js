/**
 * Turning each alert source's event into one Discord message.
 *
 * Pure functions: everything here is tested without Firebase. Each source
 * has its own tag so a glance at the channel says where an alert came from.
 */

const PROJECT = "chung-mo";

const TAGS = {
  crashlytics: "CRASHLYTICS",
  budget: "BUDGET",
  remoteConfig: "REMOTE-CONFIG",
  // Cloud Monitoring tags come from each policy's `discord_tag` user label,
  // so a new policy needs no code change; this is the fallback.
  monitoring: "MONITORING",
};

const COLORS = {critical: 0xe53935, warning: 0xfb8c00, info: 0x1e88e5, resolved: 0x43a047};

/** The two registered apps, keyed by Firebase app id (firebase.json). */
const APPS = {
  "1:655915725465:android:d8efeeaaaf1b77f178fe08": {
    platform: "Android",
    console: "android:com.taebbong.chungmo",
  },
  "1:655915725465:ios:dea0d48ec5ee142678fe08": {
    platform: "iOS",
    console: "ios:com.taebbong.chungmoapp",
  },
};

const CONSOLE = `https://console.firebase.google.com/project/${PROJECT}`;

/**
 * Renders [time] (an ISO string, or seconds since the epoch) as a Discord
 * timestamp, which each reader sees in their own time zone.
 * @param {string|number|undefined} time
 * @return {string|undefined}
 */
function discordTime(time) {
  if (time === undefined || time === null || time === "") return undefined;
  const seconds = typeof time === "number" ?
    time :
    Math.floor(new Date(time).getTime() / 1000);
  return Number.isFinite(seconds) ? `<t:${seconds}:f>` : undefined;
}

/**
 * @param {string} appId
 * @param {string} [issueId]
 * @return {string}
 */
function crashlyticsUrl(appId, issueId) {
  const app = APPS[appId];
  if (!app) return `${CONSOLE}/crashlytics`;
  const base = `${CONSOLE}/crashlytics/app/${app.console}`;
  return issueId ? `${base}/issues/${issueId}` : base;
}

/**
 * One Crashlytics alert.
 *
 * @param {"newFatal"|"newNonfatal"|"newAnr"|"regression"|"velocity"|
 *     "stabilityDigest"} kind which trigger fired
 * @param {{appId: string, data: {payload: object}}} event
 * @return {object|null} the alert, or null when there is nothing to say
 */
function crashlytics(kind, event) {
  const platform = APPS[event.appId]?.platform ?? event.appId;
  const payload = event.data.payload;
  const issue = payload.issue ?? {};
  const issueFields = [
    {name: "Issue", value: issue.subtitle ? `${issue.title}\n${issue.subtitle}` : issue.title},
    {name: "Version", value: issue.appVersion, inline: true},
    {name: "Platform", value: platform, inline: true},
  ];
  const base = {
    tag: TAGS.crashlytics,
    url: crashlyticsUrl(event.appId, issue.id),
  };
  switch (kind) {
    case "newFatal":
      return {...base, color: COLORS.critical, fields: issueFields,
        headline: `New fatal issue on ${platform} ${issue.appVersion}: ${issue.title}`};
    case "newAnr":
      return {...base, color: COLORS.critical, fields: issueFields,
        headline: `New ANR on ${platform} ${issue.appVersion}: ${issue.title}`};
    case "newNonfatal":
      return {...base, color: COLORS.warning, fields: issueFields,
        headline: `New non-fatal issue on ${platform} ${issue.appVersion}: ${issue.title}`};
    case "regression":
      return {...base, color: COLORS.critical,
        headline: `Regressed on ${platform} ${issue.appVersion}: ${issue.title}`,
        fields: [...issueFields,
          {name: "Closed at", value: discordTime(payload.resolveTime), inline: true}]};
    case "velocity":
      return {...base, color: COLORS.critical,
        // Velocity is the share of users hit within 30 minutes, per
        // firebase.google.com/docs/crashlytics/alerts-basic-integrations.
        headline: `Crash spike on ${platform}: ${issue.title} hit ` +
          `${payload.crashPercentage}% of users`,
        fields: [...issueFields,
          {name: "Crashes", value: `${payload.crashCount}`, inline: true},
          {name: "First seen in", value: payload.firstVersion, inline: true}]};
    case "stabilityDigest": {
      const trending = payload.trendingIssues ?? [];
      if (trending.length === 0) return null;
      const lines = trending.slice(0, 10).map((t) =>
        `• ${t.issue.title} — ${t.eventCount} events, ${t.userCount} users ` +
        `(${t.issue.appVersion})`);
      return {
        tag: TAGS.crashlytics,
        color: COLORS.info,
        url: crashlyticsUrl(event.appId),
        headline: `${trending.length} trending issue${trending.length === 1 ? "" : "s"} ` +
          `on ${platform} (${payload.digestDate?.slice(0, 10) ?? "today"})`,
        description: lines.join("\n"),
      };
    }
    default:
      throw new Error(`Unknown Crashlytics alert kind: ${kind}`);
  }
}

/**
 * One Cloud Monitoring incident, from its Pub/Sub notification (schema 1.2).
 * https://cloud.google.com/monitoring/support/notification-options#schema-pubsub
 *
 * @param {{incident: object}} notification
 * @return {object}
 */
function monitoringIncident(notification) {
  const incident = notification.incident ?? {};
  const label = incident.policy_user_labels?.discord_tag;
  const tag = label ? label.toUpperCase() : TAGS.monitoring;
  const open = incident.state === "open";
  const observed = incident.observed_value;
  const threshold = incident.threshold_value;
  return {
    tag,
    color: open ? COLORS.critical : COLORS.resolved,
    headline: open ? incident.policy_name : `Resolved: ${incident.policy_name}`,
    url: incident.url,
    linkText: "Open the incident",
    // The policy's documentation is the runbook — what each status means and
    // what to do — so it travels with the alert.
    description: open ? incident.documentation?.content : undefined,
    fields: [
      {name: "Observed", value: observed !== undefined && threshold !== undefined ?
        `${observed} (threshold ${threshold})` : observed, inline: true},
      {name: "Started", value: discordTime(incident.started_at), inline: true},
      {name: "Ended", value: discordTime(incident.ended_at), inline: true},
      {name: "Summary", value: incident.summary},
    ],
  };
}

/**
 * One Cloud Billing budget notification.
 *
 * Budgets publish to Pub/Sub several times a day whether or not anything
 * changed, and `alertThresholdExceeded` stays set once crossed. So the alert
 * carries a [key] — budget, month, threshold — that the caller posts only
 * once.
 * https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications
 *
 * @param {object} data the message body (schema 1.0)
 * @param {{budgetId?: string}} attributes the message attributes
 * @return {{key: string, alert: object}|null} null until a threshold is crossed
 */
function budget(data, attributes) {
  const threshold = data.alertThresholdExceeded;
  if (threshold === undefined || threshold === null) return null;
  const money = new Intl.NumberFormat("ko-KR", {
    style: "currency",
    currency: data.currencyCode || "KRW",
  });
  const percent = Math.round(threshold * 100);
  return {
    key: `${attributes.budgetId ?? data.budgetDisplayName}/` +
      `${data.costIntervalStart}/${percent}`,
    alert: {
      tag: TAGS.budget,
      color: threshold >= 1 ? COLORS.critical : COLORS.warning,
      headline: `${percent}% of "${data.budgetDisplayName}" spent: ` +
        `${money.format(data.costAmount)} of ${money.format(data.budgetAmount)}`,
      url: "https://console.cloud.google.com/billing/budgets",
      linkText: "Open budgets",
      fields: [
        {name: "Period from", value: discordTime(data.costIntervalStart), inline: true},
      ],
    },
  };
}

/**
 * Every parameter in a Remote Config template, groups included, by key.
 * @param {object|undefined} template
 * @return {Object<string, object>}
 */
function allParameters(template) {
  const parameters = {...(template?.parameters ?? {})};
  for (const group of Object.values(template?.parameterGroups ?? {})) {
    Object.assign(parameters, group.parameters ?? {});
  }
  return parameters;
}

/**
 * A parameter's value as one line: its default, plus how many conditions
 * override it.
 * @param {object} parameter
 * @return {string}
 */
function describeParameter(parameter) {
  const value = parameter.defaultValue?.useInAppDefault ?
    "(in-app default)" :
    JSON.stringify(parameter.defaultValue?.value ?? "");
  const conditions = Object.keys(parameter.conditionalValues ?? {}).length;
  return conditions ? `${value} (+${conditions} conditional)` : value;
}

/**
 * What a published template changed, parameter by parameter.
 * @param {object|undefined} before
 * @param {object} after
 * @return {Array<{key: string, change: "added"|"removed"|"changed",
 *     from?: string, to?: string}>}
 */
function diffParameters(before, after) {
  const old = allParameters(before);
  const now = allParameters(after);
  const keys = [...new Set([...Object.keys(old), ...Object.keys(now)])].sort();
  const changes = [];
  for (const key of keys) {
    if (!(key in old)) {
      changes.push({key, change: "added", to: describeParameter(now[key])});
    } else if (!(key in now)) {
      changes.push({key, change: "removed", from: describeParameter(old[key])});
    } else if (JSON.stringify(old[key]) !== JSON.stringify(now[key])) {
      changes.push({key, change: "changed",
        from: describeParameter(old[key]), to: describeParameter(now[key])});
    }
  }
  return changes;
}

const ORIGINS = {CONSOLE: "the console", REST_API: "the REST API", ADMIN_SDK_NODE: "the Admin SDK"};

/**
 * One published Remote Config template.
 *
 * The publisher's name and email are left out: they would leave the project
 * for Discord, and the version history in the console has them.
 *
 * @param {object} update the event's ConfigUpdateData
 * @param {object|undefined} before the previous version, if there is one
 * @param {object} after the published version
 * @return {object}
 */
function remoteConfigChange(update, before, after) {
  const changes = diffParameters(before, after);
  const origin = ORIGINS[update.updateOrigin] ?? update.updateOrigin;
  const version = `v${update.versionNumber}`;
  let headline;
  if (update.updateType === "ROLLBACK") {
    headline = `${version} rolls back to v${update.rollbackSource}`;
  } else if (changes.length === 1) {
    const [c] = changes;
    headline = c.change === "changed" ?
      `${version}: ${c.key} ${c.from} → ${c.to}` :
      `${version}: ${c.key} ${c.change}`;
  } else {
    headline = `${version}: ${changes.length || "no"} parameter` +
      `${changes.length === 1 ? "" : "s"} changed`;
  }
  const lines = changes.map((c) => {
    switch (c.change) {
      case "added": return `+ ${c.key} = ${c.to}`;
      case "removed": return `- ${c.key} (was ${c.from})`;
      default: return `~ ${c.key}: ${c.from} → ${c.to}`;
    }
  });
  return {
    tag: TAGS.remoteConfig,
    color: COLORS.info,
    headline,
    url: `${CONSOLE}/config`,
    linkText: "Open Remote Config",
    description: lines.length ?
      "```diff\n" + lines.join("\n") + "\n```" :
      "No parameter changed (conditions or metadata only).",
    fields: [
      {name: "Published from", value: origin, inline: true},
      {name: "At", value: discordTime(update.updateTime), inline: true},
      {name: "Note", value: update.description},
    ],
  };
}

module.exports = {
  APPS,
  COLORS,
  TAGS,
  budget,
  crashlytics,
  crashlyticsUrl,
  diffParameters,
  discordTime,
  monitoringIncident,
  remoteConfigChange,
};
