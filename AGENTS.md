# AGENTS.md

This file defines **normative development rules** for this repository.

All RFC 2119 / RFC 8174 keywords (**MUST**, **MUST NOT**, **SHOULD**, etc.) are to be interpreted as described in those RFCs.

---

## 0) Non-negotiables (reality discipline)

- **NEVER USE MEMORY CACHE.**
- **ALWAYS READ CURRENT FILE STATE FROM DISK OR THE ACTIVE CODE EDITOR BUFFER.**
- **AGENT MEMORY IS A FORBIDDEN STATE / REALITY SOURCE.**
- When uncertain about behavior, requirements, or legal meaning, **prefer primary sources** (EUR-Lex / Official Journal, ETSI/CEN publications, W3C/IETF specs, vendor docs) over assumptions.
- Do not invent behavior. Do not “fill in” missing legal requirements. Verify it.
- Do not “upgrade” requirements by vibes. If the repo says **suggestion / aspiration**, treat it as such.

---

## 1) Repository mission (what we are actually doing)

This repository is a **spec-first attempt** to define a **Globally Qualified Signature Creation Device (GQSCD)**.

“GQSCD” is **not claimed** to be a legally recognized term in any jurisdiction. It is a **web-first technical profile** that:

1. Specifies what **hardware, firmware, OS, and application components** can exist on widely available end-user devices (phones, laptops, tablets, security keys) such that the device can act like a signature creation device with **QSCD-aligned security properties**.
2. Defines **verifiable security properties** (what must be provably true to a verifier or auditor) rather than governance narratives (“approved lists”, “trusted clients”, etc.).
3. Maps those properties to EU QSCD security objectives (eIDAS Annex II and the EU’s referenced assessment/standards regime).
4. Makes a **mechanical argument** for why globally deployed web standards should be accepted **in parallel** with EU-specific formats and interfaces, without weakening physical security requirements.
5. Encourages device manufacturers to **get devices certified** (where possible) and to push for **global recognition** of equivalent, evidence-based device properties (instead of region-locked schemas and bottlenecks).

Worldview constraint (do not violate it in text): **trust comes from verifiable cryptographic evidence, not from client claims, UI promises, “approved browser lists”, or governance vibes.**

---

## 2) Terminology discipline (don’t add fog)

This repo operates in a swamp of overloaded words. Requirements:

- **Differentiate eIDAS vs EUDI**:
  - eIDAS is the trust services + eID regulation framework.
  - EUDI Wallet is an ecosystem introduced via the 2024 amendment establishing the European Digital Identity Framework.
  - Do not conflate “wallet requirements” with “qualified signature creation device requirements”.
- **Separate legal recognition from technical assurance**:
  - “Legally qualified” ≠ “cryptographically strong”.
  - The spec MAY claim “technically comparable” or “meets the same security objectives”, but MUST NOT claim “legally equivalent” unless the law/standard text explicitly supports that claim.
- **Be precise about issuer roles**:
  - If you say “PID Provider” or similar roles, ground the term in the relevant implementing regulation and label it as an **EU ecosystem role**, not a universal truth.
- Use descriptive names over political names. If a word is misleading (e.g., “blockchain”), write the **invariant** instead.

---

## 3) Single-document spec rule (NO MODULES)

User requirement: **NO MODULES.**

- The canonical specification MUST live at **repo root**: `./index.html`.
- The spec MUST be authored using **ReSpec**.
- External “module” files (`spec/*`, `modules/*`, `data-include` trees, multi-entry specs, etc.) are **FORBIDDEN** unless an issue explicitly changes this rule.
- If the spec becomes large, structure it using **sections** inside the single `index.html` file. Use appendices within the same file. Do not create parallel specs.

This repository is intentionally forcing clarity via a single artifact: one document, one truth.

---

## 4) ReSpec authoring rules for `./index.html`

When working on `./index.html`:

- Use ReSpec.
- Keep **Abstract** and **SOTD** readable and short. No walls of text.
- Normative terms MUST be defined using `<dfn>` and used consistently.
- Requirements MUST be testable in principle (even if test tooling is added later).
- Use normative keywords only in normative sections.
- AI assistance MUST be disclosed in SOTD in a factual, non-marketing way.

### 4.1 Mandatory section skeleton (in this order)

`index.html` MUST contain these sections, in this order (exact titles may vary, but intent may not):

1. Abstract
2. Status of This Document
3. Introduction
4. Scope
5. Terminology
6. Threat Model
7. GQSCD Core Requirements
8. Component Catalogue (examples + requirements)
9. Evidence Model (what evidence exists, who can check it)
10. Web Profile (primary interoperability)
11. EU Compatibility Notes (mapping, not dominance)
12. Conformance
13. Security Considerations
14. Privacy Considerations
15. Rationale (critique of governance choices, cost, bottlenecks)
16. Appendix: Reference Corpus (raw links preserved)

If you need additional content, append it. Do not reorder the above.

---

## 5) What to specify first: GQSCD-Core (the initial milestone)

The first milestone is **GQSCD-Core**: a profile that states:

> “What must exist on a widely available end-user device to behave like a signature creation device with QSCD-aligned properties.”

GQSCD-Core MUST define:

- Key custody properties (where keys live, when they are usable, what can access them).
- Anti-exfiltration properties (what _cannot_ happen even if apps are malicious).
- User intent properties (what the human actually approved, and how that is enforced).
- Update / provenance properties (what stops downgrade and supply chain attacks).
- Audit / evidence properties (what a third party can verify after the fact).

GQSCD-Core MUST treat the “client” as adversarial by default:

- UI, apps, and networks can lie.
- Only cryptographic proofs and hardware-enforced isolation count as trust inputs.

---

## 6) Component catalogue requirements (the “physical reality” inventory)

The spec MUST include a **component catalogue** covering hardware, firmware, OS, and application layer.

It MUST present components as a matrix:

- **Component**
- **Required property**
- **Evidence / how to test**
- **Threat mitigated**
- **Notes / caveats**

### 6.1 Minimum component set (examples you MUST cover)

Hardware / silicon (examples; do not treat as the only valid options)

- Secure Element (SE) / embedded SE
- TPM (esp. laptops/desktops)
- TEE / secure execution environment (e.g., TrustZone-class isolation)
- Hardware-backed keystore / key isolation
- Cryptographic RNG capability (or platform RNG with evidence constraints)
- Biometric subsystem as **user presence / intent signal only** (NOT a secret)

Firmware / boot chain

- Verified boot or measured boot (explicitly state which, and why)
- Anti-rollback / version pinning for firmware and secure OS components
- Device attestation keys (if present) and the privacy tradeoffs
- Secure time source considerations (and explicit limits)

Operating system security

- Mandatory app sandboxing / process isolation
- Permission model and secure UI primitives (anti-overlay / anti-tapjacking)
- OS keystore API semantics (hardware-backed when available)
- Update mechanism integrity and provenance

Application layer

- Wallet/signature app separation vs integration (model both explicitly)
- User intent ceremony: define **exactly what the user approved**
- Key lifecycle: generation, backup, rotation, recovery, revocation hooks
- Transparency: signed event log / verifiable history for key lifecycle events
- Export/import formats (Web Profile first)

Publication / discovery of verification material (if used)

- DID documents / verification methods (if used, keep it optional and justified)
- Credential containers (if used, constrain scope and define exact semantics)
- Hosting patterns (HTTPS required for the Web Profile; IPFS/IPNS optional)
- Integrity guarantees and replay protections

---

## 7) Threat model requirements (stop pretending)

The spec MUST include an explicit threat model, including:

- Attacker capabilities (device theft, malware, network MITM, server compromise, UI overlay, rollback attempts, etc.).
- Trusted computing base (TCB): what must be trusted, and why.
- What is **NOT** trusted:
  - “Approved client lists” are governance signals, not technical enforcement.
  - The relying party is not assumed honest.
  - The network is not assumed honest.

Do not imply that “unapproved browsers can’t access” anything. Model the actual control plane and the actual cryptographic gate.

---

## 8) Web-first interoperability rule (MANDATORY)

If EN/CEN/ETSI defines schemas, containers, protocols, or interface formats: **acknowledge them**, but DO NOT make them the primary profile.

Instead:

1. Define a **Web Profile** as the **primary** interoperability profile.
2. Define EU-specific constructs as **Compatibility Notes** and **mapping**, not as the baseline.
3. Include a normative aspiration: EU standardization SHOULD recognize Web Profile formats **in parallel**.

The Web Profile MUST prefer globally deployed web/internet standards for:

- cryptographic containers
- credential formats (if used)
- transport protocols
- browser/user-agent mediated UX where applicable

Examples of acceptable building blocks (non-exclusive):

- W3C Digital Credentials API (browser-mediated credential exchange)
- W3C Verifiable Credentials + Data Integrity (when VC containers are used)
- W3C DID Core (only if you can justify DID as a discovery mechanism)
- W3C WebCrypto (when browser primitives are in scope)
- WebAuthn/FIDO (for attested hardware authenticators and user presence)
- IETF JOSE (JWS/JWK/JWT) and/or COSE/CBOR for compact signing formats
- OpenID4VP as an ecosystem transport option (deployed VP rails)
- SD-JWT VC where selective disclosure JWT profiles are relevant

Hard constraint:

- The spec MUST be “web first”: formats and flows that work in browsers and common developer stacks are the baseline.
- Hardware/security requirements MUST be stated in **physical reality terms** (key custody, tamper resistance, user intent enforcement), not as EU-only paperwork artifacts.

---

## 9) EU alignment and mapping rule (MANDATORY, but scoped)

EU qualification is not “just crypto”; it is also an administrative regime (conformity assessment, supervision, trusted lists).

In this repo:

- EU requirements MUST be represented as:
  - a list of **security objectives**
  - an **evidence model**
  - a mapping table from **GQSCD properties → EU objectives**

Rules:

- Do not copy/paste EU schemas as the primary model.
- If EU mandates a particular container/schema today, treat it as:
  - “EU Compatibility Notes”, plus
  - a normative aspiration: “EU SHOULD recognize Web Profile formats in parallel”.

Legal accuracy rule:

- Critique is allowed. Misstating what the law says is not.
- If you claim “EU requires X”, cite the exact article/annex/decision/standard and quote minimally.

---

## 10) “Strong rationales against EU legislation” (allowed, but must be mechanical)

This repo is allowed to be sharp, but it MUST be correct.

Critique MUST be anchored in:

- measurable cost, bottleneck, lock-in, or attack surface
- falsifiable claims
- a concrete alternative mechanism (preferably already deployed on the web)

Critique MUST NOT:

- conflate eIDAS vs EUDI implementing rules
- claim “illegal” unless you can cite and show the logic chain
- assume “lists” create technical enforcement (they create constitutive legal status)

When arguing “web standards should be accepted”, show the mapping:

- “EU objective: X”
- “Web Profile mechanism: Y”
- “Remaining delta: Z (what still needs certification / evidence)”

---

## 11) Certification posture (manufacturer-facing)

The spec MUST explicitly encourage device manufacturers and platform vendors to:

- expose evidence hooks (attestation, measured boot claims, key isolation guarantees) in privacy-preserving ways
- pursue certification where it is feasible
- publish clear security target statements that map to the GQSCD property set

The spec MUST treat “globally recognized” as an aspiration:

- It MAY propose governance paths.
- It MUST NOT claim global recognition exists today.

---

## 12) Verification / checks (tooling)

Run the smallest set of checks that covers your change.

- If you change runtime logic or public API: `npm run test`.
- If you touch benchmarks or performance-sensitive code: `npm run bench`.
- If you modify TypeScript build config or emit-related logic: `npm run build`.
- If you change formatting or add files: `npm run format`.

If a required command cannot run in the current environment, state that explicitly and explain why.

---

## 13) Architecture rules (apply ONLY when the repo contains `src/` tooling)

The spec comes first. Tools may exist later. When (and only when) there is a `src/` directory, these rules become active.

### 13.1 Minimal surface area

Every directory under `src/` represents a single logical unit.

Each unit:

- MUST contain at most one root-level `.ts` file.
- MUST export at most one top-level class OR one top-level function.
- SHOULD remain under ~100 lines of executable logic (imports and type-only declarations excluded).
- MUST have a single, clear responsibility.

If complexity grows:

- Extract a subdirectory.
- Or prefer an external dependency.

Large files are a design failure, not an achievement.

### 13.2 Package preference rule

Reimplementation of common infrastructure logic is forbidden.

- Prefer mature, audited packages over ad-hoc boilerplate.
- Do not reimplement encoding, parsing, crypto primitives, validation frameworks, etc.
- Local code MUST focus on domain logic, not infrastructure recreation.

Dependency evaluation MUST consider: recent maintenance, license compatibility, known security advisories, API stability, and real-world adoption. Record the decision in change notes or the PR description.

### 13.3 Helpers

If helpers are unavoidable:

- They MUST reside under a `.helpers/` directory.
- They MUST be minimal and narrowly scoped.
- They MUST NOT evolve into a general-purpose utility framework.
- They MUST NOT contain domain logic.

### 13.4 Types

Reusable structural types MUST be isolated.

Structure:

```

.types/
TypeName/
type.ts

```

Rules:

- Each reusable type gets its own folder.
- The file MUST be named `type.ts`.
- No executable logic is allowed in `.types/`.
- Types define contracts, not behavior.

### 13.5 Errors

Errors MUST be explicit, semantic, and typed.

Structure:

```

.errors/
class.ts

```

Pattern:

```ts
export type PackageNameCode = 'SOME_ERROR_CODE' | 'ANOTHER_ERROR_CODE'

export class PackageNameError extends Error {
  readonly code: PackageNameCode

  constructor(code: PackageNameCode, message?: string) {
    const detail = message ?? code
    super(`{@scope/package-name} ${detail}`)
    this.code = code
    this.name = 'PackageNameError'
  }
}
```

Rules:

- Error codes MUST be semantic string literals.
- Error codes MUST be SCREAMING_SNAKE_CASE (use short domain prefixes when needed).
- Throwing raw `Error` is forbidden.
- Every thrown error MUST map to an explicit error code.
- Error messages MUST include package scope.

### 13.6 Forbidden patterns

- No multi-responsibility modules
- No utility dumping grounds
- No silent boilerplate replication
- No implicit global state
- No hidden cross-layer imports

---

## 14) Framework items (MUST keep; add carefully)

- **GQSCD (Globally Qualified Signature Creation Device)**  
  Controller device profile used by GDIS. Defines verifiable technical security properties for signature-capable user devices, including hardware, firmware, OS, and application layers. Focuses on cryptographic evidence, non-exportable key custody, protected signing intent, attestation, rollback resistance, and interoperable verification artifacts. Not a legal certification — a machine-verifiable technical profile.  
  https://z-base.github.io/gqscd/

- **GDIS (Global Digital Identity Scheme)**  
  Identity binding framework describing how physical identity evidence is deterministically transformed into verifiable digital identity material. Specifies MRZ-derived PID hash binding, issuance of a Verifiable Credential to a DID whose controller conforms to the GQSCD profile, governance verification endpoints, and publication of verification material in a decentralized event log. Provides deterministic verification logic but does not itself grant legal status.  
  https://z-base.github.io/gdis/

## 15) Reference corpus (MUST NOT delete; reorganise only)

Raw reference links are preserved below as **data**, not as endorsement of any single governance model.
Keep them intact; add to them carefully.
Verify questionable or future-dated citations before treating them as authoritative.

```
Initial Mandate
- Directive 1999/93/EC on a Community framework for electronic signatures — https://eur-lex.europa.eu/eli/dir/1999/93/oj
- Regulation (EU) No 910/2014 on electronic identification and trust services (eIDAS) — https://eur-lex.europa.eu/eli/reg/2014/910/oj
- Regulation (EU) 2024/1183 establishing the European Digital Identity Framework (eIDAS amendment) — https://eur-lex.europa.eu/eli/reg/2024/1183/oj

- eIDAS: repeal of Directive 1999/93/EC — https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02014R0910-20241018#d1e1459-1
- European Council Conclusions on Digital Single Market & cross-border digital trust — https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02014R0910-20241018

Supplemental (contextual background)
- eSignature Directive (Directive 1999/93/EC) — Wikipedia entry — https://en.wikipedia.org/wiki/Electronic_Signatures_Directive
- eIDAS Regulation (EU 910/2014) — Wikipedia entry — https://en.wikipedia.org/wiki/EIDAS

Values & Goals
- EU Digital Identity Wallet overview (European Commission) — https://commission.europa.eu/topics/digital-economy-and-society/european-digital-identity_en
- European Digital Identity (EUDI) Regulation policy page — https://digital-strategy.ec.europa.eu/en/policies/eudi-regulation
- EU Digital Identity Wallet (digital-building-blocks site) — https://ec.europa.eu/digital-building-blocks/sites/spaces/EUDIGITALIDENTITYWALLET/pages/694487738/EU%2BDigital%2BIdentity%2BWallet%2BHome
- Regulation (EU) 2024/1183 (Official Journal) — https://eur-lex.europa.eu/eli/reg/2024/1183/oj/eng
- eIDAS Regulation background & goals (Digital Strategy page) — https://digital-strategy.ec.europa.eu/en/policies/eidas-regulation
- EU Digital Identity Wallet (Wikipedia) — https://en.wikipedia.org/wiki/EU_Digital_Identity_Wallet

Hard Requirements (disputable only with explicit reasoning)
- eIDAS Regulation (consolidated) — https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02014R0910-20241018
- eIDAS Amendment Regulation (EU) 2024/1183 — https://eur-lex.europa.eu/eli/reg/2024/1183/oj

- QSCD Security Assessment Standards Decision (EU) 2016/650 — https://eur-lex.europa.eu/eli/dec_impl/2016/650/oj

- Remote QSCD Requirements (EU) 2025/1567 — https://eur-lex.europa.eu/eli/reg_impl/2025/1567/oj
- QTSP Requirements (EU) 2025/2530 — https://eur-lex.europa.eu/eli/reg_impl/2025/2530/oj
- CAB Accreditation (EU) 2025/2162 — https://eur-lex.europa.eu/eli/reg_impl/2025/2162/oj

- Qualified Validation Services (EU) 2025/1942 — https://eur-lex.europa.eu/eli/reg_impl/2025/1942/oj
- Signature Validation Rules (EU) 2025/1945 — https://eur-lex.europa.eu/eli/reg_impl/2025/1945/oj
- Qualified Preservation Services (EU) 2025/1946 — https://eur-lex.europa.eu/eli/reg_impl/2025/1946/oj

- Qualified Certificates Standards (EU) 2025/1943 — https://eur-lex.europa.eu/eli/reg_impl/2025/1943/oj
- Identity Verification Standards (EU) 2025/1566 — https://eur-lex.europa.eu/eli/reg_impl/2025/1566/oj

- QEAA Attestations (EU) 2025/1569 — https://eur-lex.europa.eu/eli/reg_impl/2025/1569/oj
- QERDS Interoperability (EU) 2025/1944 — https://eur-lex.europa.eu/eli/reg_impl/2025/1944/oj

- EUDI Wallet Integrity (EU) 2024/2979 — https://eur-lex.europa.eu/eli/reg_impl/2024/2979/oj
- EUDI Wallet Protocols (EU) 2024/2982 — https://eur-lex.europa.eu/eli/reg_impl/2024/2982/oj

- Wallet Security Breach Rules (EU) 2025/847 — https://eur-lex.europa.eu/eli/reg_impl/2025/847/oj
- Wallet Relying Party Registration (EU) 2025/848 — https://eur-lex.europa.eu/eli/reg_impl/2025/848/oj
- Certified Wallet Notification (EU) 2025/849 — https://eur-lex.europa.eu/eli/reg_impl/2025/849/oj

- ETSI EN 319 401 — https://www.etsi.org/deliver/etsi_en/319400_319499/319401/03.01.01_60/en_319401v030101p.pdf
- ETSI EN 319 411-2 — https://www.etsi.org/deliver/etsi_en/319400_319499/31941102/02.06.00_20/en_31941102v020600a.pdf
- ETSI EN 319 421 — https://www.etsi.org/deliver/etsi_en/319400_319499/319421/01.03.01_60/en_319421v010301p.pdf

- CEN EN 419 241-1 — https://standards.iteh.ai/catalog/standards/cen/0a3d58ed-04b4-4d14-a69e-2647c47e26ba/en-419241-1-2018
- CEN EN 419 221-5 — https://standards.iteh.ai/catalog/standards/cen/3e27cc07-2782-4c65-81b7-474d858a471c/en-419221-5-2018

- EU Trusted Lists — https://digital-strategy.ec.europa.eu/en/policies/eu-trusted-lists
- QSCD Notifications — https://eidas.ec.europa.eu/efda/browse/notification/qscd-sscd

Infra / Language
- ECMA-262 — https://tc39.es/ecma262/
- WHATWG Infra — https://infra.spec.whatwg.org/
- Infra Extension — https://www.w3.org/TR/xmlschema11-2/
- Base64Url — https://base64.guru/standards/base64url
- JSON — https://www.rfc-editor.org/rfc/rfc8259
- URI — https://www.rfc-editor.org/rfc/rfc3986
- RegExp -- https://datatracker.ietf.org/doc/html/rfc9485
- RegExp Api --  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_expressions

Formal Alternatives
- SEDI — https://le.utah.gov/~2026/bills/static/SB0275.html
- UN — https://untp.unece.org/docs/specification/Architecture/
- ICC — https://iccwbo.org/news-publications/policies-reports/the-icc-guide-to-authenticate-certificates-of-origin-for-international-business/

Identifiers / Credentials
- DID Use Cases — https://www.w3.org/TR/did-use-cases/
- DID Core v1.0 — https://www.w3.org/TR/did-core/
- DID Core v1.1 — https://www.w3.org/TR/did-1.1/
- DID Test Suite — https://w3c.github.io/did-test-suite/
- DID Extensions — https://www.w3.org/TR/did-extensions/

- VC Data Model v2.0 — https://www.w3.org/TR/vc-data-model-2.0/
- VC Overview — https://www.w3.org/TR/vc-overview/
- VC Test Suite — https://w3c.github.io/vc-test-suite/
- Distributed Ledger Technologies — https://en.wikipedia.org/wiki/Distributed_ledger

JSON-LD / RDF
- JSON-LD 1.1 — https://www.w3.org/TR/json-ld11/
- JSON-LD API — https://www.w3.org/TR/json-ld11-api/
- RDF Concepts — https://www.w3.org/TR/rdf11-concepts/
- RDF Schema — https://www.w3.org/TR/rdf-schema/
- Schema Org — https://schema.org/docs/schemas.html

WebCrypto
- Web Cryptography Level 2 — https://www.w3.org/TR/webcrypto-2/

JOSE
- JWS — https://www.rfc-editor.org/rfc/rfc7515.html
- JWE — https://www.rfc-editor.org/rfc/rfc7516.html
- JWK — https://www.rfc-editor.org/rfc/rfc7517.html
- JWA — https://www.rfc-editor.org/rfc/rfc7518.html
- JWT — https://www.rfc-editor.org/rfc/rfc7519.html
- JWS Unencoded Payload — https://www.rfc-editor.org/rfc/rfc7797.html
- JWT BCP — https://www.rfc-editor.org/rfc/rfc8725.html
- JWT/JWS Updates — https://www.rfc-editor.org/rfc/rfc9864.html
- JOSE Cookbook — https://www.rfc-editor.org/rfc/rfc7520.html
- JWK Thumbprint — https://www.rfc-editor.org/rfc/rfc7638.html
- EdDSA for JOSE — https://www.rfc-editor.org/rfc/rfc8037.html
- IANA JOSE Registries — https://www.iana.org/assignments/jose/jose.xhtml

Infrastructure
- HTTP — https://datatracker.ietf.org/doc/html/rfc9110
- IPFS & IPNS — https://docs.ipfs.tech/

Ideas
- KERI — https://trustoverip.github.io/kswg-keri-specification/
- ACDA — https://trustoverip.github.io/kswg-acdc-specification/
- CESR — https://trustoverip.github.io/kswg-cesr-specification/
- SELF — https://docs.self.xyz/
```

---

## 16) Philosophy

Small modules (for future tooling only, not the spec).
Explicit contracts.
Typed errors.
Spec-first reasoning.
Dependency over reinvention.
No hidden state.

Architecture is a constraint system, not a suggestion.

[1]: https://chatgpt.com/c/6992ee9d-4018-838a-80c8-15a29f9a0793 'Evaluating SEDI Legislation'
[2]: https://chatgpt.com/c/6991dc4a-72a0-8394-844f-af750f7fb6f5 'EUDI vs SEDI Debate'
[3]: https://chatgpt.com/c/69907277-9adc-838a-93d2-b05f1d4c4112 'EUDI vs SEDI Debate'

```

Source notes (not part of AGENTS.md): the key “web-first” building blocks and EU framework references in the rules above are grounded in ReSpec documentation :contentReference[oaicite:0]{index=0}, the EUDI/eIDAS amendment regulation text :contentReference[oaicite:1]{index=1}, VC Data Integrity as a W3C Recommendation :contentReference[oaicite:2]{index=2}, WebAuthn Level 3 as current W3C work :contentReference[oaicite:3]{index=3}, WebCrypto Level 2 as current W3C work :contentReference[oaicite:4]{index=4}, OpenID4VP as deployed protocol rails (including DC API integration) :contentReference[oaicite:5]{index=5}, and SD-JWT VC as the active IETF profile for selective disclosure JWT credentials :contentReference[oaicite:6]{index=6}.

::contentReference[oaicite:7]{index=7}
```

[1]: https://chatgpt.com/c/69907277-9adc-838a-93d2-b05f1d4c4112 'EUDI vs SEDI Debate'
[2]: https://chatgpt.com/c/6992ee9d-4018-838a-80c8-15a29f9a0793 'Evaluating SEDI Legislation'
[3]: https://chatgpt.com/c/6993fc27-158c-8396-831c-118e4c3df4b9 'Disk encryption on devices'
