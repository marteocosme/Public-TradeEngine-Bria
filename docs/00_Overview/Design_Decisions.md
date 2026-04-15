
# Design Decisions
## Purpose of This Document
This document records explicit design decisions made during the development of the TradeEngine‑Bria project.

Its goals are to:

- Preserve long‑term project context
- Prevent repeated debates on settled topics
- Explain why certain architectural and behavioral choices were made
- Serve as an authoritative reference for future phases, contributors, and tooling

Every decision here represents a conscious trade‑off, not an accident.

---
## How to Use This Document

- Each decision is immutable once recorded
- New decisions are appended; old ones are never rewritten
- If a decision is overturned, a new decision entry must explicitly supersede it

If an implementation question arises, consult this file before changing code.

---
## Decision Log
### DD‑001 — Money Management Is the Highest Priority Algorithm
**Date:** 2026‑04‑15

**Decision:** Money Management (MM) correctness takes precedence over entry strategies, indicators, or optimization.

**Rationale:**
- MM can make or break any trading system regardless of entry quality
- Incorrect MM invalidates backtest and forward‑test conclusions
- Entry strategies are meaningless without trustworthy risk behavior

**Implications:**

- MM must be validated first
- Entry strategy work is intentionally deferred


### DD‑002 — Production Readiness Is the Primary Goal
**Date:** 2026‑04‑15

**Decision:** The project is explicitly production‑oriented, not exploratory or academic.

**Rationale:**
- The intent is to release a usable EA as soon as it is safely possible
- Engineering discipline exists to accelerate safe delivery, not delay it

**Implications:**

- Incremental, compile‑safe work is mandatory
- Perfect architecture does not justify blocking validation progress


### DD‑003 — Logging Is a Core Validation Tool, Not a Diagnostic Extra
**Date:** 2026‑04‑15

**Decision:** Logs are treated as first‑class artifacts used to validate behavior, not merely for debugging.

**Rationale:**
- MM correctness must be provable without inspecting code
- Backtests and forward tests must be analyzable post‑hoc
- Logs enable deterministic replay and audit

**Implications:**

- If behavior is not logged, it is not trusted
- Snapshot‑level logging is required for MM validation

### DD‑004 — Trade Lifecycle Is Explicit and Enforced
**Date:** 2026‑04‑14

**Decision:** All trades must progress through explicit lifecycle states with enforced valid transitions.

**Rationale:**

- Prevents implicit or invalid trade behavior
- Enables deterministic control flow
- Grounds MM actions in state‑based validation

**Implications:**

- No procedural "do‑anything" logic
- Invalid transitions must fail deterministically and log errors


## DD‑005 — Money Management Actions Are Lifecycle‑Bound
**Date:** 2026‑04‑15

**Decision:** Money Management actions (BE, scale‑out, trailing, exit) are treated as lifecycle‑dependent transitions, not standalone features.

*Rationale:*

- MM actions depend on trade state
- Standalone MM introduces invalid or unsafe behavior
- Lifecycle binding enables validation and consistency

**Implications:**

- MM cannot exist as an independent processing loop
- Original standalone MM phases were superseded architecturally


## DD‑006 — Phase MM‑01 to MM‑04 Were Architecturally Superseded
**Date:** 2026‑04‑15

**Decision:** Original roadmap MM‑01 to MM‑04 phases are considered architecturally fulfilled but observability‑incomplete.

**Rationale:**

- MM logic, enforcement, and event emission were absorbed into Phase 4 and Phase 5
- Logging completeness and validation criteria remained open

**Implications:**

- A dedicated follow‑up phase is required to close logging obligations
- No MM logic re‑implementation is required


## DD‑007 — Phase Completion Markers Are the Source of Truth
**Date:** 2026‑04‑14

**Decision:** Phase‑X‑Completion.md files are the authoritative indicator of project progress.

**Rationale:**

- Roadmaps express intent, not reality
- Completion markers document what actually exists and was validated

**Implications:**

- A phase is not complete without a completion marker
- Roadmap discrepancies defer to completion files


## DD‑008 — Incremental, Compile‑Safe Development Is Mandatory
**Date:** 2026‑04‑15

**Decision:** All changes must be incremental, compile‑safe, and individually testable.

**Rationale:**

- Enables continuous backtesting during development
- Prevents destabilizing regressions
- Supports fast feedback loops toward production

**Implications:**

- No large refactors without validation benefit
- No speculative batching of changes


## DD‑009 — Entry Strategy Work Is Explicitly Deferred
**Date:** 2026‑04‑15

**Decision:** Trade entry strategies will only be developed after MM behavior is validated through logs.

**Rationale:**

- Entry logic distractions delay MM validation
- MM confidence is a prerequisite for meaningful strategy testing

**Implications:**

- Entry strategy placeholders may exist, but are not optimized
- Phase sequencing enforces this order


## DD‑010 — Logs Must Support Replay Without Code Inspection
**Date:** 2026‑04‑15

**Decision:** A complete trade lifecycle must be reconstructible from logs alone.

**Rationale:**

- Enables independent analysis
- Supports Excel, Python, and BI tooling
- Validates behavior empirically

**Implications:**

- Lifecycle snapshot logging is mandatory
- Silent or partial logging is disallowed

---
## Final Note
This document exists to **reduce cognitive load and decision churn.**

If a question has already been answered here, the correct action is to follow the recorded decision — not reopen the debate.


✅ End of Design Decisions
