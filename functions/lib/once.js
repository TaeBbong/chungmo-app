/**
 * Doing something at most once per key, across invocations.
 *
 * A Cloud Storage object is the claim: creating it with
 * `ifGenerationMatch: 0` succeeds only when it does not exist yet, and the
 * check-and-create is a single request, so two deliveries of the same
 * Pub/Sub message cannot both win. It needs no database — the project has
 * none — and the objects are a few bytes each.
 * https://cloud.google.com/storage/docs/request-preconditions
 */

/** Returned by Cloud Storage when the precondition fails. */
const PRECONDITION_FAILED = 412;

/**
 * Runs [action] unless [key] was claimed before.
 *
 * The claim is released if [action] throws, so a later delivery retries
 * rather than the alert being lost.
 *
 * @param {{file: function(string): object}} bucket a Cloud Storage bucket
 * @param {string} key
 * @param {function(): Promise<void>} action
 * @return {Promise<boolean>} whether [action] ran
 */
async function once(bucket, key, action) {
  const file = bucket.file(key);
  try {
    await file.save("", {preconditionOpts: {ifGenerationMatch: 0}, resumable: false});
  } catch (error) {
    if (error.code === PRECONDITION_FAILED) return false;
    throw error;
  }
  try {
    await action();
  } catch (error) {
    await file.delete({ignoreNotFound: true});
    throw error;
  }
  return true;
}

module.exports = {once};
