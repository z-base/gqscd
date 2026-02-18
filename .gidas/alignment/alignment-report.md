# Alignment Report

Self spec: GQSCD-CORE  
Self repo: z-base/gqscd  
Peers loaded: GDIS-CORE, GQTS-CORE

## Extraction Summary
- Self terms: 26
- Self clauses: 55
- Self OpenAPI operations: 0
- Peer terms: 36
- Peer clauses: 23
- Peer OpenAPI operations: 15 (GDIS: 8, GQTS: 7)

## Key conflicts found
- term-definition-conflict: `web profile` differs between `GQSCD-CORE` and `GDIS-CORE`.
- term-definition-conflict: `eu compatibility profile` differs between `GQSCD-CORE` and `GDIS-CORE`.

## Changes applied to SELF
- Added `respecConfig.localBiblio` entries for `GDIS-CORE`, `GQSCD-CORE`, `GQTS-CORE` in `index.html`.
- Added explicit stable term anchors:
  - `web profile` -> `id="term-web-profile"`
  - `eu compatibility profile` -> `id="term-eu-compatibility-profile"`

## Duplicates removed
- None in `GQSCD-CORE` for this run.
- Rationale: canonical-owner heuristic selected `GQSCD-CORE` as owner for the duplicated cross-cutting terms above, so this repo keeps the canonical definitions; deduplication is expected in peer repos.

## Cross-references added
- Added peer bibliographic entries through `localBiblio` to enable stable ReSpec cross-citation/import mechanics from this repo.

## Remaining conflicts and gaps
- Conflict (TODO): term-definition divergence for `web profile` and `eu compatibility profile` between `GQSCD-CORE` and `GDIS-CORE`.
- Gap (TODO): `ANNEXII-1d` is used as a term-like token in `GQSCD-CORE` but is not extracted as a formal `<dfn>` term.
- OpenAPI requirement-namespace conflict: UNSPECIFIED in currently loaded snapshots (no `REQ-R*` mapping detected in `../gdis/openapi.yaml`; GQTS endpoint requirements were `REQ-GQTS-*` in both peer OpenAPI files at run time).

## Changed files
- `index.html`
- `.gidas/alignment/spec-index.self.json`
- `.gidas/alignment/spec-index.peers.json`
- `.gidas/alignment/cross-spec-map.json`
- `.gidas/alignment/alignment-report.md`
- `.gidas/alignment/build-alignment.ps1`
- `.gidas/alignment/proposed-changes.patch`
