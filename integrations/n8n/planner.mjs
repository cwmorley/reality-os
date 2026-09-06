// Read-only reference planner. No dispatch, persistence, file access, or AI calls.
// This self-contained function is also embedded in the synthetic n8n workflow.
export function planReviews(snapshot) {
  const states = new Set(['open', 'possible-answer', 'answered-awaiting-processing', 'withdrawn', 'superseded']);
  const dispositions = new Set(['imported', 'merged', 'rejected', 'deferred', 'already-represented', 'terminal']);
  const statuses = new Set(['queued', 'running', 'uncertain', 'finished', 'cancelled']);
  const require = (ok, message) => { if (!ok) throw new Error(message); };
  const string = value => typeof value === 'string' && value.length > 0;
  const timestamp = value => string(value) && /T.*(?:Z|[+-]\d{2}:\d{2})$/.test(value) && Number.isFinite(Date.parse(value));
  const identity = value => JSON.stringify([value.source, value.id]);
  const version = value => JSON.stringify([value.source, value.id, value.updated, value.contentHash]);
  const jobKey = (value, route) => JSON.stringify([value.source, value.id, value.updated, value.contentHash, route.recipient, 'review']);
  const validVersion = value => value && string(value.source) && string(value.id) && timestamp(value.updated) && /^[a-f0-9]{64}$/.test(value.contentHash);

  require(snapshot && snapshot.schemaVersion === 1, 'Unsupported snapshot schema');
  for (const field of ['routes', 'candidates', 'observations', 'receipts', 'jobs']) {
    require(Array.isArray(snapshot[field]), `Expected ${field} array`);
  }
  require(typeof snapshot.acceptNewWork === 'boolean', 'Explicit work-window decision required');
  const routes = new Map();
  for (const route of snapshot.routes) {
    require(route && string(route.source) && string(route.recipient) && typeof route.enabled === 'boolean', 'Invalid trusted route');
    require(!routes.has(route.source), 'Duplicate source route');
    routes.set(route.source, route);
  }
  const observations = new Map();
  for (const observed of snapshot.observations) {
    require(validVersion(observed), 'Invalid observed version');
    require(!observations.has(identity(observed)), 'Duplicate observation');
    observations.set(identity(observed), observed);
  }
  const receipts = new Map();
  for (const receipt of snapshot.receipts) {
    require(validVersion(receipt) && string(receipt.recipient) && dispositions.has(receipt.disposition), 'Invalid receipt');
    const key = jobKey(receipt, receipt);
    require(!receipts.has(key), 'Duplicate receipt');
    receipts.set(key, receipt);
  }
  const jobs = new Map();
  for (const job of snapshot.jobs) {
    require(validVersion(job) && string(job.recipient) && statuses.has(job.status), 'Invalid job');
    const key = jobKey(job, job);
    require(!jobs.has(key), 'Duplicate job');
    jobs.set(key, job);
  }
  const seen = new Set();
  // Validate the whole batch before returning any actionable output.
  for (const candidate of snapshot.candidates) {
    require(validVersion(candidate) && states.has(candidate.state) && typeof candidate.ready === 'boolean', 'Invalid candidate');
    require(!seen.has(identity(candidate)), 'Duplicate candidate identity');
    seen.add(identity(candidate));
  }

  return snapshot.candidates.map(candidate => {
    const route = routes.get(candidate.source);
    const result = (action, reason, extra = {}) => ({ source: candidate.source, id: candidate.id, action, reason, ...extra });
    if (!route?.enabled) return result('blocked', 'Source has no enabled trusted route');
    const key = jobKey(candidate, route);
    const reply = (action, reason) => result(action, reason, { jobKey: key, recipient: route.recipient });
    const previous = [observations.get(identity(candidate)), ...snapshot.receipts, ...snapshot.jobs]
      .filter(value => value && identity(value) === identity(candidate));
    if (previous.some(value => Date.parse(value.updated) > Date.parse(candidate.updated))) {
      return reply('blocked', 'Source is older than previously observed work');
    }
    if (previous.some(value => Date.parse(value.updated) === Date.parse(candidate.updated) && version(value) !== version(candidate))) {
      return reply('blocked', 'Same update time has conflicting version metadata');
    }
    if (!candidate.ready) return reply('wait', 'Source adapter has not confirmed a complete stable item');
    if (receipts.has(key)) return reply('skip', 'This exact version already has a reconciler receipt');

    const outstanding = snapshot.jobs.filter(job => identity(job) === identity(candidate)
      && job.status !== 'cancelled' && !receipts.has(jobKey(job, job)));
    if (outstanding.some(job => ['uncertain', 'finished'].includes(job.status))) {
      return reply('needs-reconciliation', 'A prior attempt has no authoritative receipt; inspect effects before retry');
    }
    if (outstanding.some(job => job.status === 'running')) return reply('wait', 'An existing review is still running');
    if (!snapshot.acceptNewWork) return reply('wait', 'Outside the configured work window');
    if (outstanding.some(job => job.status === 'queued' && jobKey(job, job) !== key)) {
      return reply('supersede-queued', 'Cancel the older unclaimed job atomically, then rescan');
    }
    if (jobs.get(key)?.status === 'queued') return reply('wait', 'This version is already queued');
    if (jobs.get(key)?.status === 'cancelled') return reply('needs-reconciliation', 'Cancelled version requires an explicit retry decision');
    if (['withdrawn', 'superseded'].includes(candidate.state)) {
      return reply('request-terminal-receipt', 'Reconciler should record source lifecycle without reopening the question');
    }
    return reply('queue-review', 'New ready version needs bounded review; this is not authority to apply changes');
  });
}
