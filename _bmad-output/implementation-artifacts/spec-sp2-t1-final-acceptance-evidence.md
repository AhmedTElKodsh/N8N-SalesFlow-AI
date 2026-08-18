---
title: 'Harden SP2-T1 final acceptance evidence'
type: 'chore'
created: '2026-08-18'
status: 'done'
route: 'one-shot'
---

# Harden SP2-T1 final acceptance evidence

## Intent

**Problem:** SP2-T1 already had a working local-only WhatsApp-shaped intake, but its final acceptance evidence did not directly prove that malformed and oversized requests left all relevant business data unchanged or that post-rejection recovery reached a terminal staging state.

**Approach:** Strengthen the disposable integration harness with account-scoped, content-level database evidence; require completed staging turns without customer-facing actions; refresh signed release hashes; and pass the complete regression suite plus independent acceptance, adversarial, and edge-case review.

## Suggested Review Order

**Acceptance evidence**

- Start with the five SP2 cases, latency bound, storage, idempotency, and ordering assertions.
  [`run.ps1:166`](../../tests/run.ps1#L166)

- Content fingerprints prove rejected malformed requests cannot silently mutate business rows.
  [`run.ps1:174`](../../tests/run.ps1#L174)

- Oversize and recovery checks prove immutability, continued health, and terminal staging.
  [`run.ps1:180`](../../tests/run.ps1#L180)

**Review trace**

- The story ledger records every final review patch as resolved.
  [`spec-sp2-t1-test-whatsapp-intake.md:56`](spec-sp2-t1-test-whatsapp-intake.md#L56)

**Release integrity**

- The reviewed manifest hash binds the final activation inputs.
  [`release-set.json:1`](../../config/release-set.json#L1)

- The release manifest preserves local-only promotion policy and refreshed evidence hashes.
  [`release-manifest.json:77`](../../release/release-manifest.json#L77)
