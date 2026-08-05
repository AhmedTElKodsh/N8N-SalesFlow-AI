---
title: 'SP1-T1 Structured Business Information'
type: 'feature'
created: '2026-08-05'
status: 'done'
review_loop_iteration: 0
baseline_commit: '2c32ab7085b1719d4fc2f6767ddfddbc4e1f7a16'
context:
  - '{project-root}/docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The five business-information contracts are versioned and partly validated, but valid-looking documents can still contain undocumented top-level or nested fields. Their field meanings, limits, references, and ownership boundaries are not documented clearly enough for a non-technical reviewer.

**Approach:** Keep the existing PostgreSQL validation boundary and five JSON fixtures. Make validation closed to undocumented fields, prove valid and invalid cases for every business contract, and expand the existing component documentation rather than adding a schema framework or new dependency.

## Boundaries & Constraints

**Always:** Treat Product Knowledge, Sales Policy, Qualification, Consent and Template References, and Handoff Dispatch Settings as five separate business contracts; keep Consent and Templates combined as `consent_templates`; retain `accountRef`, `kind`, and `version` as the business-information version; reject undocumented fields, invalid types, invalid ranges, and invalid relationships at the contract root and inside Product Knowledge sources, Sales Policy quiet hours, and template objects; accept publication only when validation returns literal SQL `true`; preserve immutable versions, account scope, manifest integrity, and `livePromotionAllowed: false`. Document that template wording remains provider-owned and that Handoff triggers remain owned by Qualification, human signals, and Sales Policy.

**Ask First:** Adding or renaming business fields, splitting Consent from Templates, changing operational contracts, changing publication lifecycle, or widening production authority.

**Never:** Add a custom administration UI, schema service, validation dependency, speculative abstraction, semantic-content heuristic, or production approval claim. Do not store provider-owned template wording, duplicate Handoff triggers, or mix model, retry, retention, release-set, or account settings into the five business contracts.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Valid fixture | Existing sample for any of the five kinds | Validation returns `true` and publication remains allowed | N/A |
| Missing field | Required root or nested field removed | Validation returns `false` | Publication returns `invalid_config` |
| Invalid value | Wrong type, out-of-range value, conflicting signals, or invalid relationship | Validation returns `false` | Publication returns `invalid_config` |
| Undocumented root field | Otherwise-valid document contains an extra key | Validation returns `false` | Active version remains unchanged |
| Undocumented nested field | Source, quiet-hours, or template-reference object contains an extra key | Validation returns `false` | Active version remains unchanged |
| Indeterminate validation | Malformed values cause a SQL `NULL` result | Publication rejects the document | Return `invalid_config`; never publish |

</frozen-after-approval>

## Code Map

- `database/001-initial.sql` — shared `validate_config` and `publish_config` trust boundary used by every configuration publication.
- `config/product-knowledge.json`, `config/sales-policy.json`, `config/qualification.json`, `config/consent-and-templates.json`, `config/handoff.json` — current valid business fixtures and documentation examples; templates are references and Handoff contains dispatch settings.
- `tests/runtime.sql` — database assertions executed after the real fixtures are published.
- `docs/component-inventory.md` — already-indexed configuration documentation; smallest place for plain-language field definitions.
- `release/release-manifest.json`, `config/release-set.json` — canonical input hashes and activation-manifest binding affected by SQL/test changes.

## Tasks & Acceptance

**Execution:**
- [x] `database/001-initial.sql` — add exact allowed-key checks for the five business kinds, including nested objects, and make `publish_config` accept only a literal successful validation result.
- [x] `tests/runtime.sql` — validate the five published fixtures and add missing, invalid, unexpected-root, unexpected-nested, and public-publication rejection assertions without introducing a test framework.
- [x] `docs/component-inventory.md` — explain every field, allowed value/range, nested structure, provider-owned template wording, distributed Handoff-trigger ownership, and separation from operational configuration using the existing fixtures as examples.
- [x] `release/release-manifest.json`, `config/release-set.json` — refresh changed input hashes and the canonical activation binding while keeping live promotion disabled.

**Acceptance Criteria:**
- Given each existing business fixture is published, when database validation runs, then all five return literal `true`.
- Given any documented negative case, when validation or publication runs, then it fails closed and an explicit public-path assertion proves the active configuration is unchanged.
- Given a non-technical reviewer reads the configuration section, when they inspect any field in the five contracts, then its purpose, allowed value, and example are available in plain language.
- Given the canonical harness is run with Docker available, when it completes, then all manifest, fixture, database, workflow, and cleanup checks pass.
- Given no recorded second-engineer approval exists, when release status is reviewed, then production activation remains prohibited.

## Spec Change Log

- 2026-08-05: Implemented all tasks; the canonical harness passed with disposable credentials and volumes removed.

## Design Notes

Use PostgreSQL's native JSONB key subtraction at the existing validator boundary. This fixes every `publish_config` caller once and avoids duplicating validation in PowerShell, workflows, or five new schema files. Structural validation does not pretend to approve the meaning of business content; human approval remains required. Operational configurations retain their existing validators because SP1-T1 explicitly covers only the five business contracts.

## Verification

**Commands:**
- `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1` — expected: `FULL PASS`, exact manifest binding, all five fixtures accepted, negative contracts rejected, and cleanup confirmed.
- `git diff --check` — expected: no whitespace errors.

## Suggested Review Order

**Validation boundary**

- Start with the shared identity, exact-key, and JSON-type gate.
  [`001-initial.sql:46`](../../database/001-initial.sql#L46)

- Review the five contract-specific structural and range checks.
  [`001-initial.sql:51`](../../database/001-initial.sql#L51)

- Confirm publication accepts only literal successful validation.
  [`001-initial.sql:60`](../../database/001-initial.sql#L60)

**Reviewer-facing contract**

- Read the plain-language fields, ownership boundaries, and examples.
  [`component-inventory.md:45`](../../docs/component-inventory.md#L45)

**Regression evidence**

- Confirm every published business fixture validates successfully.
  [`runtime.sql:38`](../../tests/runtime.sql#L38)

- Trace missing, mistyped, invalid, and undocumented-field rejection cases.
  [`runtime.sql:39`](../../tests/runtime.sql#L39)

- Verify rejected publication preserves the active version.
  [`runtime.sql:46`](../../tests/runtime.sql#L46)

**Release binding**

- Check changed SQL and test hashes in the activation manifest.
  [`release-manifest.json:77`](../../release/release-manifest.json#L77)

- Confirm the reviewed activation digest remains promotion-blocked.
  [`release-manifest.json:91`](../../release/release-manifest.json#L91)

- Confirm the Release Set pins the same reviewed digest.
  [`release-set.json:1`](../../config/release-set.json#L1)
