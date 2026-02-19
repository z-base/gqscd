# Alignment Plan

Self spec: `GQSCD-CORE`  
Self repo: `z-base/gqscd`

## Preconditions
- Read `AGENTS.md` in the SELF repo.
- Read `gidas-alignment.config.json`.
- Verified peer snapshots exist for:
  - `GDIS-CORE` (`../gdis/index.html`, `../gdis/openapi.yaml`)
  - `GQTS-CORE` (`../gqts/index.html`, `../gqts/openapi.yaml`)

## Canonical Term/Anchor Owners
- `proof artifact` -> `GDIS-CORE#evidence-artifact` (wallet-private claim artifact semantics).
- `binding credential` -> `GDIS-CORE#gdis-binding-credential` (wallet-private claim credential semantics).
- `verification material` -> `GQTS-CORE#history-invariants` (public trust-network publication semantics).
  - UNSPECIFIED: current `GQTS-CORE` snapshot does not expose a dedicated `<dfn>` anchor named `verification material`; this plan binds to the normative history/publication section anchor.
- Device/key/custody terms remain `GQSCD-CORE` owned.
- Identity/PID terms remain `GDIS-CORE` owned.
- Log/publication/history terms remain `GQTS-CORE` owned.

## Canonical Clause Mapping (OpenAPI)
- `GET /.well-known/gidas/gqts/scheme/{governanceCode} | getSchemeDescriptor` -> canonical owner `GQTS-CORE` (`REQ-GQTS-01`).
- `GET /.well-known/gidas/gqts/scheme/{governanceCode}/endpoint-kinds | getEndpointKindCatalog` -> canonical owner `GQTS-CORE` (`REQ-GQTS-02`).
- `GET /.well-known/gidas/gqts/type/{serviceId} | getTypeDescriptor` -> canonical owner `GQTS-CORE` (`REQ-GQTS-03`).
- `GET /.well-known/gidas/gqts/event/{logId}/meta | getEventHeadMeta` -> canonical owner `GQTS-CORE` (`REQ-GQTS-04`).
- `GET /.well-known/gidas/gqts/event/{logId} | getEventLogView` -> canonical owner `GQTS-CORE` (`REQ-GQTS-05`).
- `POST /.well-known/gidas/gqts/event/{logId} | postEventIngest` -> canonical owner `GQTS-CORE` (`REQ-GQTS-06`).
- `GET /.well-known/gidas/gqts/event/{logId}/{eventId} | getEventById` -> canonical owner `GQTS-CORE` (`REQ-GQTS-07`).

## Required SELF Changes (Applied)
- `index.html`: encode wallet-private vs trust-public split in evidence/discovery clauses.
  - Updated `REQ-GQSCD-18` to require VC-form proof artifacts while keeping them wallet-private unless explicitly disclosed.
  - Added explicit discovery-scope text: trust-service discovery/event-log retrieval is limited to public verification material.
  - Updated `REQ-GQSCD-22` and `REQ-GQSCD-24` to scope discovery artifacts to public verification material.
  - Updated `REQ-GQSCD-29` to require reject-or-report handling for invalid chain/proof nodes (no silent merge).
- `openapi.yaml`: clarified that this repo defines proof schemas only; trust-service publication endpoints are outside scope and carry public verification material.
- No GQTS-hosted endpoint definitions were added to SELF `openapi.yaml`; canonical operation IDs and `x-gqts-requirement` ownership remain in GQTS/GDIS peers.

## UNSPECIFIED Items (Intentional)
- OPRF/BBS and blinded-data publication mechanics are not defined in this SELF repo.
- GQTS root-key event object shape and credential-link payload details remain governed by GQTS/GDIS profiles, not GQSCD.
