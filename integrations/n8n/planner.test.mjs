import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { planReviews } from './planner.mjs';
import { candidate, emptySnapshot, demoCases } from './fixtures.mjs';

const receipt = (extra = {}) => ({ ...candidate, recipient: 'canonical-reconciler', disposition: 'deferred', ...extra });
const job = (status, extra = {}) => ({ ...candidate, recipient: 'canonical-reconciler', status, ...extra });
const action = snapshot => planReviews(snapshot)[0].action;

test('new ready work is proposed without mutating the supplied snapshot', () => {
  const snapshot = emptySnapshot();
  const before = structuredClone(snapshot);
  assert.equal(action(snapshot), 'queue-review');
  assert.deepEqual(snapshot, before);
});
test('repeated polling suppresses every existing disposition, including deferral', () => {
  for (const disposition of ['imported', 'merged', 'rejected', 'deferred', 'already-represented', 'terminal']) {
    const snapshot = emptySnapshot();
    snapshot.receipts.push(receipt({ disposition }));
    assert.equal(action(snapshot), 'skip');
    assert.equal(action(snapshot), 'skip');
  }
});
test('a materially newer version remains reviewable despite an old receipt', () => {
  const snapshot = emptySnapshot();
  snapshot.receipts.push(receipt());
  snapshot.candidates[0].updated = '2026-09-06T11:00:00-06:00';
  snapshot.candidates[0].contentHash = 'b'.repeat(64);
  assert.equal(action(snapshot), 'queue-review');
});
test('unchanged timestamp with altered content fails closed even without observations', () => {
  const snapshot = emptySnapshot();
  snapshot.receipts.push(receipt());
  snapshot.candidates[0].contentHash = 'b'.repeat(64);
  assert.equal(action(snapshot), 'blocked');
});
test('a stale mirror cannot rewind the previously observed source version', () => {
  const snapshot = emptySnapshot();
  snapshot.observations.push({ ...candidate, updated: '2026-09-06T11:00:00-06:00' });
  assert.equal(action(snapshot), 'blocked');
});
test('withdrawal and supersession request receipts without reopening a question', () => {
  for (const state of ['withdrawn', 'superseded']) {
    const snapshot = emptySnapshot();
    snapshot.candidates[0].state = state;
    assert.equal(action(snapshot), 'request-terminal-receipt');
  }
});
test('inferred and explicitly answered candidates still require actual reconciliation', () => {
  for (const state of ['possible-answer', 'answered-awaiting-processing']) {
    const snapshot = emptySnapshot();
    snapshot.candidates[0].state = state;
    assert.equal(action(snapshot), 'queue-review');
  }
});
test('queued and running work cannot be dispatched again', () => {
  for (const status of ['queued', 'running']) {
    const snapshot = emptySnapshot();
    snapshot.jobs.push(job(status));
    assert.equal(action(snapshot), 'wait');
  }
});
test('successful process exit and uncertain timeout both require a real receipt before retry', () => {
  for (const status of ['finished', 'uncertain', 'cancelled']) {
    const snapshot = emptySnapshot();
    snapshot.jobs.push(job(status));
    assert.equal(action(snapshot), 'needs-reconciliation');
  }
});
test('a newer source cannot bypass an uncertain older attempt', () => {
  const snapshot = emptySnapshot();
  snapshot.jobs.push(job('uncertain'));
  snapshot.candidates[0].updated = '2026-09-06T11:00:00-06:00';
  assert.equal(action(snapshot), 'needs-reconciliation');
});
test('older queued work must be superseded before the new version is queued', () => {
  const snapshot = emptySnapshot();
  snapshot.jobs.push(job('queued'));
  snapshot.candidates[0].updated = '2026-09-06T11:00:00-06:00';
  assert.equal(action(snapshot), 'supersede-queued');
  snapshot.jobs[0].status = 'cancelled';
  assert.equal(action(snapshot), 'queue-review');
});
test('source content cannot choose its own recipient or authorize a new route', () => {
  const snapshot = emptySnapshot();
  snapshot.candidates[0].recipient = 'unexpected-agent';
  assert.equal(planReviews(snapshot)[0].recipient, 'canonical-reconciler');
  snapshot.candidates[0].source = 'unregistered-source';
  assert.equal(action(snapshot), 'blocked');
});
test('changing the configured recipient cannot bypass a running or uncertain earlier review', () => {
  for (const [status, expected] of [['running', 'wait'], ['uncertain', 'needs-reconciliation'], ['queued', 'supersede-queued']]) {
    const snapshot = emptySnapshot();
    snapshot.jobs.push(job(status));
    snapshot.routes[0].recipient = 'replacement-reconciler';
    assert.equal(action(snapshot), expected);
  }
});
test('disabled sources, partial items, and off-hours cannot start new work', () => {
  const disabled = emptySnapshot();
  disabled.routes[0].enabled = false;
  assert.equal(action(disabled), 'blocked');
  const partial = emptySnapshot();
  partial.candidates[0].ready = false;
  assert.equal(action(partial), 'wait');
  const offHours = emptySnapshot();
  offHours.acceptNewWork = false;
  assert.equal(action(offHours), 'wait');
});
test('malformed or duplicate inputs abort the whole batch before output', () => {
  for (const alter of [
    snapshot => { snapshot.candidates.push({ ...candidate }); },
    snapshot => { snapshot.candidates[0].updated = 'yesterday'; },
    snapshot => { snapshot.candidates[0].state = 'approved'; },
    snapshot => { snapshot.candidates[0].contentHash = 'not-a-digest'; },
    snapshot => { snapshot.routes.push({ ...snapshot.routes[0] }); },
    snapshot => { snapshot.receipts.push(receipt({ disposition: 'model-said-done' })); },
  ]) {
    const snapshot = emptySnapshot();
    alter(snapshot);
    assert.throws(() => planReviews(snapshot));
  }
});
test('generated n8n workflow executes the same synthetic planner with no other node types', () => {
  const workflow = JSON.parse(readFileSync(new URL('./workflow.dry-run.json', import.meta.url), 'utf8'));
  assert.equal(workflow.active, false);
  assert.deepEqual(workflow.nodes.map(node => node.type), ['n8n-nodes-base.manualTrigger', 'n8n-nodes-base.code']);
  const code = workflow.nodes[1].parameters.jsCode;
  assert.ok(code.startsWith(planReviews.toString()));
  const output = runInNewContext(`(function () { ${code}\n})()`, {}, { timeout: 1000 });
  assert.deepEqual(JSON.parse(JSON.stringify(output)), demoCases().map(({ scenario, snapshot }) => ({ json: { scenario, decisions: planReviews(snapshot) } })));
  assert.deepEqual(JSON.parse(JSON.stringify(output)).map(item => item.json.decisions[0].action),
    ['queue-review', 'skip', 'request-terminal-receipt', 'needs-reconciliation']);
});
