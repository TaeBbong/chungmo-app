/**
 * Posting to a Discord webhook.
 *
 * Discord accepts only its own payload (`content` and/or `embeds`), which is
 * why GCP alerts are relayed through these functions at all: Cloud
 * Monitoring's webhook channel sends a fixed schema that Discord rejects.
 * https://discord.com/developers/docs/resources/webhook#execute-webhook
 */

/** Discord's documented field limits. */
const LIMITS = {content: 2000, description: 4096, fieldName: 256, fieldValue: 1024};

const USERNAME = "chungmo alerts";

/**
 * Cuts [text] to [max] characters, marking the cut.
 * @param {string} text
 * @param {number} max
 * @return {string}
 */
function truncate(text, max) {
  const value = String(text ?? "");
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

/**
 * Builds the webhook body for an alert.
 *
 * The tag goes in `content`, not only in the embed, because a phone's push
 * notification shows `content` and drops the embed.
 *
 * @param {{tag: string, headline: string, color: number, description?: string,
 *     url?: string, linkText?: string,
 *     fields?: Array<{name: string, value: string, inline?: boolean}>}} alert
 * @return {object}
 */
function toPayload(alert) {
  const embed = {color: alert.color};
  if (alert.description) {
    embed.description = truncate(alert.description, LIMITS.description);
  }
  if (alert.url) {
    embed.title = alert.linkText ?? "Open in console";
    embed.url = alert.url;
  }
  if (alert.fields?.length) {
    embed.fields = alert.fields
        .filter((f) => f.value !== undefined && f.value !== null && `${f.value}` !== "")
        .map((f) => ({
          name: truncate(f.name, LIMITS.fieldName),
          value: truncate(f.value, LIMITS.fieldValue),
          inline: f.inline ?? false,
        }));
  }
  return {
    username: USERNAME,
    content: truncate(`**[${alert.tag}]** ${alert.headline}`, LIMITS.content),
    embeds: [embed],
    // Alert text quotes crash titles and config values; never let one ping.
    allowed_mentions: {parse: []},
  };
}

/**
 * Posts [alert] to [webhookUrl], throwing on a non-2xx answer so the caller
 * can log it — the email channels stay as the fallback.
 * @param {string} webhookUrl
 * @param {object} alert
 * @param {typeof fetch} [fetchImpl]
 */
async function post(webhookUrl, alert, fetchImpl = fetch) {
  if (!webhookUrl) throw new Error("DISCORD_WEBHOOK_URL is not set");
  const response = await fetchImpl(webhookUrl, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(toPayload(alert)),
  });
  if (!response.ok) {
    throw new Error(`Discord answered ${response.status}: ${await response.text()}`);
  }
}

module.exports = {LIMITS, post, toPayload, truncate};
