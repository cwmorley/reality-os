// Fictional metadata only. A real adapter must hash actual stable candidate bytes.
export const candidate = {
  source: 'contributor-a', id: 'EXAMPLE-001', updated: '2026-09-06T10:00:00-06:00',
  contentHash: 'a'.repeat(64), state: 'open', ready: true,
};
export function emptySnapshot() {
  return {
    schemaVersion: 1, acceptNewWork: true,
    routes: [{ source: 'contributor-a', recipient: 'canonical-reconciler', enabled: true }],
    candidates: [structuredClone(candidate)], observations: [], receipts: [], jobs: [],
  };
}
export function demoCases() {
  const fresh = emptySnapshot();
  const reviewed = emptySnapshot();
  reviewed.receipts.push({ ...candidate, recipient: 'canonical-reconciler', disposition: 'deferred' });
  const withdrawn = emptySnapshot();
  withdrawn.candidates[0].state = 'withdrawn';
  const uncertain = emptySnapshot();
  uncertain.jobs.push({ ...candidate, recipient: 'canonical-reconciler', status: 'uncertain' });
  return [
    { scenario: 'New item', snapshot: fresh },
    { scenario: 'Already reviewed', snapshot: reviewed },
    { scenario: 'Withdrawn item', snapshot: withdrawn },
    { scenario: 'Timeout with unknown effects', snapshot: uncertain },
  ];
}
