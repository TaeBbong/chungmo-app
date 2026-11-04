<!-- docs/ALERTS.md -->

# Operational alerts in Discord

Every operational signal chungmo has — crashes, a refusing AI backend,
App Check denials, spend and Remote Config publishes — is posted to one
Discord channel. Each source has its own tag. This document covers why the
relay exists, what fires and when, the GCP resources involved, what it
costs, and how to test or change it.

---

## 1. Why a relay

A Discord webhook accepts only Discord's payload: `content` and/or
`embeds`. Neither GCP nor Firebase can produce it:

- **Cloud Monitoring** offers Email, Mobile App, PagerDuty, SMS, Slack,
  Webhook, Pub/Sub and Google Chat. The Webhook channel always sends the
  fixed schema-1.2 incident, which Discord rejects. The Slack channel signs
  in to a Slack workspace, so a Discord URL cannot be used there. For any
  other destination the documentation recommends a Pub/Sub channel with a
  function in between
  ([notification options](https://cloud.google.com/monitoring/support/notification-options)).
- **Cloud Billing budgets** publish to Pub/Sub or a Monitoring channel,
  which raises the same problem.
- **Remote Config** has no notification at all. A function trigger is the
  only hook.
- **Crashlytics** alone has a no-code route: the console's Slack
  integration, pointed at Discord's Slack-compatible `/slack` endpoint.
  It was not used, because the message format would differ from every
  other source, the tag could only be the sender name, and Discord does not
  document that compatibility.

So the relay is Cloud Functions for Firebase, following Firebase's own
sample
([alerts-to-discord](https://github.com/firebase/functions-samples/tree/main/Node/alerts-to-discord)).
It differs from the sample in two ways:

- The webhook URL is kept in Secret Manager instead of `.env`.
- Formatting is kept in pure functions so it can be tested.

## 2. What fires

| Tag | Source | Fires on | Function |
| --- | --- | --- | --- |
| `CRASHLYTICS` | Firebase Alerts | new fatal, new non-fatal, new ANR, regression, velocity, trending (stability digest) | `crashlytics*` (6) |
| `AI-OUTAGE` | Monitoring policy `10382917754509198714` | > 2 non-2xx on `firebasevertexai` in 10 min ([ANALYTICS.md](./ANALYTICS.md) §12.3) | `monitoringIncident` |
| `APP-CHECK` | Monitoring policy `2009750050305578426` | any App Check `DENY` whose `security` is not `MISSING_OUTDATED_CLIENT`, in 10 min | `monitoringIncident` |
| `BUDGET` | Budget `chungmo monthly`, KRW 3,000 | 50 / 90 / 100 % of actual spend, each once per month | `budgetThreshold` |
| `REMOTE-CONFIG` | Remote Config | every published template, with the parameters that changed | `remoteConfigPublished` |

Each Monitoring incident posts twice, once when it opens and once when it
resolves. The open message carries the policy's documentation, which is
the runbook.

### 2.1 Why these thresholds

- **App Check.** From 2026-09-23 to 2026-11-04 there were five denials,
  all `MISSING_OUTDATED_CLIENT`, with at most three in any 10-minute
  window. They come from app versions built before App Check, and nothing
  server-side can fix them. Run against the same six weeks, the policy's
  condition matches zero windows. Flipping the exclusion to an equality
  matches exactly the five known denials, which shows the filter is the
  one intended. Any other denial is therefore new. If one turns out to be
  routine, raise the threshold from the measured counts.
- **Budget.** Over the 90 days to 2026-11-04 there were 62 successful AI
  calls. At current prices that is a few hundred won a month. KRW 3,000
  was the maintainer's choice: an early warning on runaway use, not a cost
  ceiling. Credits are **excluded** (`EXCLUDE_ALL_CREDITS`), so the budget
  measures gross usage. A spike paid for by prepaid credit still fires.

### 2.2 Budget notifications arrive many times a day

Cloud Billing publishes the budget state several times a day, even with
no usage. Once a threshold has been crossed, `alertThresholdExceeded`
stays set in every later message
([programmatic notifications](https://cloud.google.com/billing/docs/how-to/budgets-programmatic-notifications)).
Posting every message would repeat the same alert all month.

`lib/once.js` therefore claims a key — budget, month and threshold — by
creating an empty object in `gs://chung-mo-alert-state` with
`ifGenerationMatch: 0`. Cloud Storage creates the object only if it does
not already exist, and does so in a single request. Two deliveries of the
same Pub/Sub message therefore cannot both post. If the post to Discord
fails, the claim is released, so a later notification retries. Objects
expire after 400 days.

### 2.3 What is not sent

- **The publisher of a Remote Config change.** The event includes their
  name and email, but these would leave the project for Discord. The
  console's version history already records them.
- **Store review status.** There is no Firebase or GCP event for it.
- **GitHub.** The repository has no workflows.

## 3. Resources

| Resource | Name |
| --- | --- |
| Functions (codebase `alerts`, `us-central1`, Node 22) | `functions/`, declared in `firebase.json` |
| Secret | `DISCORD_WEBHOOK_URL` (Secret Manager) |
| Pub/Sub topics | `ops-alerts` (Monitoring), `billing-budget-alerts` (budget) |
| Topic publishers | `service-655915725465@gcp-sa-monitoring-notification` on `ops-alerts`; `billing-budget-alert@system.gserviceaccount.com` on `billing-budget-alerts` |
| Monitoring channel | `notificationChannels/6044910591919605368` (`chungmo Discord relay (ops-alerts)`) |
| Claim bucket | `gs://chung-mo-alert-state` (uniform access, public access prevented, objects deleted after 400 days) |
| Budget | `billingAccounts/01328E-B50B71-F94ED5/budgets/3b0ab81c-7b80-43e3-8f9f-a135446ee4b2` |

Both Monitoring policies still notify the `chungmo maintainer email`
channel as well. The budget still emails billing admins. A failed Discord
post is logged and does not throw, because the emails remain as a
fallback.

To route a new Monitoring policy to Discord:

1. Add the channel above to the policy.
2. Give the policy a `discord_tag` user label. The label value becomes the
   tag, upper-cased. Labels must be lower case.

No code change is needed.

## 4. Cost

The free allowance of the Blaze plan
([pricing](https://firebase.google.com/pricing)) covers this many times
over:

- 2M invocations/month;
- 400K GB-seconds and 200K CPU-seconds;
- 120 build-minutes/day;
- 500 MB of Artifact Registry storage.

The relay runs a handful of times a month, each under a second, with
`maxInstances: 1` and no minimum instances.

The only line that can exceed its allowance is image storage. The
repository `us-central1/gcf-artifacts` was already at 223 MB from the
legacy Python functions. The deploy set a cleanup policy that deletes
images older than one day. Any overage would be in the tens of won a
month, and the budget above would report it.

## 5. Operating it

```bash
cd functions && npm install && npm test        # formatters, payload, once-claim
npx firebase-tools@latest deploy --only functions:alerts --project chung-mo
npx firebase-tools@latest functions:log --project chung-mo
```

**Rotating the webhook** (for example, if the URL leaked):

1. Create a new webhook in Discord.
2. Run `npx firebase-tools@latest functions:secrets:set DISCORD_WEBHOOK_URL --project chung-mo`.
3. Redeploy. Functions bind a secret version at deploy time.
4. Delete the old webhook in Discord.

**The first deploy** failed for the seven Eventarc-triggered functions with
"Permission denied while using the Eventarc Service Agent", because this
was the project's first use of Eventarc. The agent already held
`roles/eventarc.serviceAgent`; the grant had only not propagated yet. A
redeploy a few minutes later succeeded.

### 5.1 Testing a path

- **Monitoring.** Publish a schema-1.2 incident to `ops-alerts` with
  `policy_user_labels.discord_tag` set.
- **Budget.** Publish a schema-1.0 body to `billing-budget-alerts` with a
  `budgetId` attribute. Then delete its claim object under
  `budget/<budgetId>/` in the bucket.
- **Remote Config.** Publish the template, even unchanged, with a version
  description. This publishes to production, so it is the maintainer's
  step.
- **Crashlytics.** Firebase cannot send a test alert. Render the messages
  through `lib/messages.js` and `lib/discord.js` locally, as described in
  §6.

## 6. How this was verified (2026-11-04)

- 34 unit tests (`node --test`). Each was checked against a broken
  implementation and failed as intended:
  - a budget key without the threshold, or keyed on cost;
  - mentions allowed;
  - a claim never released;
  - any storage error treated as "already claimed";
  - the `discord_tag` label ignored;
  - empty fields kept;
  - grouped parameters ignored;
  - an empty digest posted;
  - the digest left unbounded.
- **Monitoring path through the deployed function.** Three incidents
  published to `ops-alerts` (`AI-OUTAGE` open, `APP-CHECK` open,
  `AI-OUTAGE` resolved) were each logged as posted by the deployed
  function.
- **Monitoring end to end.** A temporary policy that notified only the
  Discord channel fired. Cloud Monitoring published to `ops-alerts` itself,
  and the incident reached Discord, which proves the notification service
  agent's publisher grant. The policy was then deleted.
  - The first version used a metric-absence condition on a series that had
    never existed, and it did not fire in twelve minutes.
  - A threshold condition on API calls that were being made at the time
    fired within two minutes.
- **Budget path through the deployed function.**
  - 50 % was published twice and posted once; the second delivery was
    logged as "already posted".
  - 90 % then posted as a new alert.
  - The claim objects were deleted afterwards.
- **Crashlytics and Remote Config rendering.** All six Crashlytics kinds
  and a Remote Config diff built from the live template were posted from
  a local run of the same modules. Discord accepted every one.
