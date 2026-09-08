import { writeFileSync } from 'node:fs';
import { planReviews } from './planner.mjs';
import { demoCases } from './fixtures.mjs';

const workflow = {
  name: 'Reality OS - synthetic handoff planner (dry run)',
  active: false,
  nodes: [
    { id: 'manual', name: 'Run synthetic cases', type: 'n8n-nodes-base.manualTrigger', typeVersion: 1, position: [0, 0], parameters: {} },
    {
      id: 'planner', name: 'Plan only - no dispatch', type: 'n8n-nodes-base.code', typeVersion: 2, position: [280, 0],
      parameters: { mode: 'runOnceForAllItems', jsCode: `${planReviews.toString()}\nconst cases = ${JSON.stringify(demoCases(), null, 2)};\nreturn cases.map(({ scenario, snapshot }) => ({ json: { scenario, decisions: planReviews(snapshot) } }));` },
    },
  ],
  connections: { 'Run synthetic cases': { main: [[{ node: 'Plan only - no dispatch', type: 'main', index: 0 }]] } },
  settings: { executionOrder: 'v1' },
};
writeFileSync(new URL('./workflow.dry-run.json', import.meta.url), JSON.stringify(workflow, null, 2) + '\n');
