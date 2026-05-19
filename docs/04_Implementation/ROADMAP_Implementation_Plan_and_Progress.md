## ROADMAP — Implementation Plan & Progress (SSOT)

### 🔒 Document Status
Version: v3.0  
Status: ✅ ACTIVE (SSOT) — PENDING RUNTIME RE-VALIDATION (v2.2 volume semantics)  
Last Updated: 2026-05-19 (UTC+8)

### Supersedes
- ROADMAP_Implementation_Plan_and_Progress_v2.md (Revised v2 — 2026-04-15)
- Roadmap v1 (historical)

---

## 🎯 Purpose
This Roadmap is the authoritative SSOT for post-engine-core development and phase governance.

Why v3 exists:
- Roadmap v2 captured earlier “logging completeness” gaps as blocking Phase 6.
- The MM-LOG-01 logging system and validation have since matured (PASSED under v2.1).
- A v2.2 schema/semantic update (P5-FIX-05: lifecycle volume model simplification) requires a targeted re-validation gate.
- Phase 6 is now explicitly the analytics layer (turn logs into dashboards/metrics), not logging completion.

This Roadmap defines:
- Ground-truth phase status
- Phase gates (exit criteria)
- Near-term priorities
- Governance rules (no phase progression without gates met)

---

## ✅ Ground Truth Status (as of 2026-05-19)

### Phase Status Table
| Phase | Focus | Status |
|------:|-------|--------|
| 4 | Logging Hardening / Observability Foundation | ✅ CLOSED |
| 5 | Execution Behavior Validation (MM-LOG-01 runtime truth) | 🟡 v2.1 PASSED / v2.2 PENDING RE-VALIDATION (P5-FIX-05) |
| 6 | Data Analytics Layer (Dashboards / Metrics / Replay tooling) | 🟢 READY TO START (blocked until Phase 5 v2.2 gate passes) |
| 7 | Forward Testing (Demo) | 🔵 PLANNED |
| 8 | Controlled Live Deployment | 🔵 PLANNED |
| 9 | Performance Analysis & Optimization | 🔵 PLANNED |
| 10 | Production Hardening | 🔵 PLANNED |
| 11 | Strategy / Signal Integration | 🔵 PLANNED |

---

## 🧱 Non-Negotiable Project Principles (SSOT)
1) Auditability over performance: logs must reconstruct decisions without code inspection.  
2) Specs/Schema/Contract must match runtime truth.  
3) No phase progression without exit criteria.  
4) MM-LOG-01 observability is mandatory before analytics/scaling.

---

## 🚦 Phase Gates (Hard Requirements)

### Phase 5 (v2.2) Re-Validation Gate — REQUIRED before Phase 6
Phase 5 may be considered complete under the current model only when v2.2 runtime validation passes for:

**Schema / Semantics**
- Event close_volume is per-event executed close volume:
  - MM_EVENT_SCALE_OUT and MM_EVENT_CLOSE only
  - Neutral defaults for ENTRY / BE / TRAIL / EXIT
- Cycle Summary close_volume is lifecycle aggregate:
  - close_volume = SUM(SCALE_OUT close_volume) + CLOSE close_volume
- total_traded_volume is removed from Cycle Summary (no redundancy under monotonic-decreasing lifecycle).

**Reconciliation**
- Cycle Summary pnl = SUM(SCALE_OUT close_profit) + CLOSE close_profit
- Cycle Summary close evidence (reason/price/deal_id) reconciles against Event CLOSE evidence.
- correlation_id rules remain valid (engine EXIT→CLOSE may share correlation_id; broker-driven close must use a dedicated CLOSE correlation_id).

**CSV Compliance**
- Headers and column order match SSOT schema exactly.
- No shifted columns, missing fields, or uninitialized garbage values.

Output of this gate:
- “RUNTIME VALIDATION PASSED — v2.2” recorded in the validation checklist SSOT.

---

## 📦 Phase Definitions (What each phase means NOW)

### Phase 4 — Logging Hardening / Observability Foundation (CLOSED)
Goal:
- Establish deterministic, schema-compliant logging across Snapshot / Event / Cycle Summary.
- Implement two-phase termination model (EXIT intent vs CLOSE broker-confirmed outcome).

Exit Criteria:
- Logs are schema-compliant and reconstructable.
- CLOSE is the lifecycle terminator for validation and Cycle Summary emission.

---

### Phase 5 — Execution Behavior Validation (v2.2 pending)
Goal:
- Validate that runtime output matches schema/contract with cycle-by-cycle evidence.
- Fix defects uncovered by backtests and log inspections (PnL, correlation rules, volume semantics).

Exit Criteria:
- Phase 5 v2.2 re-validation gate passes (see above).

---

### Phase 6 — Data Analytics Layer (Dashboards / Metrics / Replay Tools)
Prerequisite:
- Phase 5 v2.2 gate must be ✅ PASSED.

Goal:
- Turn validated logs into analytics: performance attribution, lifecycle behavior, risk utilization.
- Build repeatable ingestion and dashboards (Excel/Power BI/scripts).

Scope:
- CSV ingestion pipeline and schema version awareness
- KPI set: expectancy, win-rate, R-multiples, drawdown, scale-out vs final-close attribution
- Data quality monitors: missing rows, reconciliation checks, schema mismatch alerts
- Optional replay tooling (reconstruct lifecycle timeline from logs)

Non-Scope:
- New strategy logic
- Entry/indicator signal expansion
- Performance tuning

---

### Phase 7 — Forward Testing (Demo)
Goal:
- Validate system behavior in live market conditions without capital risk.
Focus:
- Execution behavior, logging integrity, lifecycle correctness.

---

### Phase 8 — Controlled Live Deployment
Goal:
- Low-risk live validation.
Focus:
- Broker behavior, execution reliability, risk model validation.

---

### Phase 9 — Performance Analysis & Optimization
Goal:
- Use logs to refine performance (not curve fit).
Focus:
- Risk efficiency, lifecycle optimization, parameter tuning.

---

### Phase 10 — Production Hardening
Goal:
- Robustness under real-world conditions.
Scope:
- error handling, recovery, monitoring, alerting.

---

### Phase 11 — Strategy / Signal Integration
Goal:
- Integrate signal generation into a validated engine.
Rule:
- Signals must remain independent of:
  - lot sizing
  - SL/TP/MM logic
  - trade management mechanics

---

## 🧭 Near-Term Top Priorities (Next 1–2 Sessions)
1) Phase 5 v2.2 re-validation sign-off (runtime evidence)
2) Update/lock SSOT schemas + contract + checklist (already aligned; confirm PASS)
3) Start Phase 6 analytics scaffolding (data model + dashboard MVP)
4) Build repeatable “Test Scenario Catalog” for validation regression
5) Repo polish: traceability matrix + field dictionary (optional but high ROI)

---

## 📜 Roadmap Governance Rules
- SSOT rule: this file is the authoritative roadmap; versioned files live in archive.
- Any structural changes require a new Roadmap version (v3.1, v3.2…).
- Phase gates are mandatory; no phase progression without explicit evidence.

---

### Change Log
#### v3.0 (2026-05-19)
- Reframed Phase 6 as Analytics Layer (not logging completion).
- Recorded Phase 5 as v2.1 passed with v2.2 re-validation pending due to volume semantics simplification (P5-FIX-05).
- Consolidated phase gates into explicit, auditable sign-off rules.