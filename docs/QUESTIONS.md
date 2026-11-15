# Open questions

Format: one entry per question. The agent applies the safest default, records it here, and continues.
The owner answers by editing the entry (change **Status** to `answered`) and the agent follows up.

## Template

### Q-000 — Short title
- **Phase / task**: e.g. Phase 2, Elbow
- **Question**: …
- **Default applied**: …
- **Why this default is safe**: …
- **Status**: open | answered
- **Answer**: …

## Pre-filled decisions for the owner (please confirm or change)

### Q-001 — Where will the gem be distributed?
- **Phase / task**: Phase 8, release
- **Question**: Private only (git remote / `path:`), or public on RubyGems after the legal checklist?
- **Default applied**: private only; no publication step is executed by the agent.
- **Status**: answered
- **Answer**: private only (confirmed by the owner).

### Q-002 — Is the author's existing Rails ViewComponent draft to be reused?
- **Phase / task**: Phase 1–3
- **Question**: The earlier style guide (§14) contains Rails component drafts. Port ideas only, or port code?
- **Default applied**: ideas only; components are rewritten test-first under the new naming (`Deckplate::`, `dp-`).
- **Status**: answered
- **Answer**: ideas only (confirmed by the owner).

### Q-003 — Default success colour
- **Phase / task**: Phase 1, themes
- **Question**: In `classic`, success is pale yellow (per the author's guide). Should `classic` map success to a
  green instead?
- **Default applied**: pale-canary (yellow) with mandatory text/icon; `daylight` maps success to a green.
- **Status**: answered
- **Answer**: pale-canary in `classic` (confirmed by the owner).
