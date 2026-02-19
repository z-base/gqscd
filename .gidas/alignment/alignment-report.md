# Alignment Report

Self spec: `GQSCD-CORE`  
Self repo: `z-base/gqscd`  
Peers loaded: `GDIS-CORE`, `GQTS-CORE`

## Preconditions
- `AGENTS.md` read from SELF working tree.
- `gidas-alignment.config.json` present and loaded.
- Peer snapshots present for all required peer indexes/OpenAPI files.

## Extraction Summary
- Self terms: 21
- Self clauses: 56
- Self OpenAPI operations: 0
- Peer terms: 39
- Peer clauses: 25
- Peer OpenAPI operations: 15 (GDIS: 8, GQTS: 7)

## Changes Applied to SELF
- Updated `index.html` evidence/discovery clauses to encode:
  - wallet-private proof artifacts (credentials/proofs stay outside trust-service publication by default),
  - trust-public verification material for discovery/event-log retrieval,
  - deterministic reject-or-report handling for invalid log nodes in `REQ-GQSCD-29`.
- Updated `openapi.yaml` descriptions to keep proof schema bindings separate from trust-service publication semantics.
- Added alignment workflow inputs:
  - `gidas-alignment.config.json`
  - `scripts/cross-spec-align.mjs`
- Added cross-spec alignment plan output:
  - `.gidas/alignment/alignment-plan.md`

## Duplicates Removed
- None in SELF in this run.
- Canonical ownership and anchors were recorded in `cross-spec-map.json` and `alignment-plan.md` for:
  - `proof artifact` -> `GDIS-CORE#evidence-artifact`
  - `binding credential` -> `GDIS-CORE#gdis-binding-credential`
  - `verification material` -> `GQTS-CORE#history-invariants`

## Cross-References Added
- `index.html` now includes explicit cross-spec links to:
  - `GDIS binding credential` (`GDIS-CORE`)
  - `GQTS history invariants` (`GQTS-CORE`)

## Conflicts and Remaining Items
- `operation-contract-conflict`: none detected.
- `requirement-id-namespace-conflict`: none detected.
- Remaining gap from extractor: `requirement-reference-without-anchor` for `REQ-GQTS-05` in SELF.
  - Status: UNSPECIFIED by current extractor heuristic; external requirement IDs are referenced via peer links rather than local anchors.

## Files Changed
- `index.html`
- `openapi.yaml`
- `gidas-alignment.config.json`
- `scripts/cross-spec-align.mjs`
- `.gidas/alignment/build-alignment.ps1`
- `.gidas/alignment/spec-index.self.json`
- `.gidas/alignment/spec-index.peers.json`
- `.gidas/alignment/cross-spec-map.json`
- `.gidas/alignment/alignment-plan.md`
- `.gidas/alignment/alignment-report.md`
