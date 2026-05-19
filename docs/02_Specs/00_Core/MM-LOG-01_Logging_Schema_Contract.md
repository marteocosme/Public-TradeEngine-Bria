
# MM-LOG-01 Logging Schema Contract

## 🔒 Document Status

**Version:** v1.7

**Status:** ✅ ACTIVE (SSOT) — PENDING RUNTIME VALIDATION (v2.2)  

**Last Updated:** 2026-05-19 (UTC+8)

---

## 🎯 Purpose

Defines the contract between:

- Trade Lifecycle
- Snapshot Schema
- Logging System

Ensures logs are:
- Complete
- Consistent
- Auditable (MM-LOG-01 compliant)

---

## Status
✅ Approved (Snapshot Schema v1.3 Active)


## Version
v1.6

### Supersedes
- v1.5
- v1.4
- v1.3
- v1.2
- v1.1

---


## 🔗 Dependencies (SSOT)

This contract depends on the following SSOT specifications:

- MM_Snapshot_Schema.md  *(SSOT)*
- MM_Event_Log_Schema.md *(SSOT) — *defines MM_Events.csv / JSON, including MM_EVENT_CLOSE + close_reason fields*
- TradeLifecycleEvents.md *(SSOT)* — *canonical event identifiers and mappings*
- MM_Cycle_Summary_Schema.md *(SSOT) — defines Cycle Summary aggregation rules (pnl + close_volume lifecycle aggregates)*
- Logging_Architecture.md *(SSOT) — end-to-end logging pipeline + reconciliation rules*
- MM-LOG-01_Runtime_Validation_Checklist.md *(SSOT) — runtime acceptance + regression gates*


Dependency rules:
- Dependencies must reference SSOT filenames only. Versioned documents belong under `/00_Core/_archive/`.
- If any dependency listed here changes → Schema → Contract → Validation MUST update (in that order) before any code update is allowed.

---


## Phase Mapping

Phase: Phase 4 — Logging & Observability  
Extended in: Phase 4B — Logging Hardening  

This contract represents the final state of Phase 4 logging.

---

## Scope

This specification covers:

- Money Management (MM) snapshot logging
- BEFORE and AFTER snapshot structure
- Exposure and risk tracking
- Execution State (resulting system state)
- Execution Outcome (MM decision results)

This specification does NOT cover:

- Broker execution logging (OrderSend / OrderModify)
- External execution responses or errors

→ Broker-level execution is handled in:
EXEC-LOG-01 (separate contract)



---

## Terminology Clarification

**Execution Outcome (MM Context):**
- Refers to the result of MM actions
- Includes:
  - SCALE_OUT
  - BREAK-EVEN
  - TRAILING

**Execution Outcome (Broker Context):**
- Refers to order execution results
- Includes:
  - OrderSend
  - OrderModify

✅ Broker execution logging is OUT OF SCOPE for MM-LOG-01

---

## Trade Termination Model (Two‑Phase)

MM‑LOG‑01 separates **engine intent** from **broker-confirmed outcome** to ensure lifecycle completeness and accurate auditability.

### MM_EVENT_EXIT (Intent — Engine Close Request)
`MM_EVENT_EXIT` MUST NOT be used as proof of closure; broker-confirmed closure is represented only by `MM_EVENT_CLOSE`.

**Rules**
- Optional per lifecycle: a cycle MAY have **0..1** `MM_EVENT_EXIT`
- If present, `MM_EVENT_EXIT` MUST occur **before** `MM_EVENT_CLOSE`
- `MM_EVENT_EXIT` represents **intent**, not guaranteed closure

### MM_EVENT_CLOSE (Outcome — Broker/Deal Confirmed Closure)
`MM_EVENT_CLOSE` is emitted only when the broker/deal confirms the position is actually closed.

**Rules**
- Mandatory per lifecycle: a cycle MUST have **exactly 1** `MM_EVENT_CLOSE`
- `MM_EVENT_CLOSE` is the **official lifecycle terminator** for MM‑LOG‑01 validation and cycle summary emission
- `MM_EVENT_CLOSE` may occur with or without a prior `MM_EVENT_EXIT` (e.g., TP/SL/STOP_OUT)

### close_reason (Required for MM_EVENT_CLOSE)
`MM_EVENT_CLOSE` MUST include `close_reason`, one of:
- `MM_EXPERT` (closed by EA/Expert action; engine-initiated closure)
- `MANUAL` (user/manual close outside signal logic)
- `TP_HIT` (take profit executed by broker)
- `SL_HIT` (stop loss executed by broker)
- `STOP_OUT` (margin/stop-out)
- `UNKNOWN` (fallback when reason cannot be reliably determined)


> Note: `close_reason` is an MM‑LOG‑01 field used for lifecycle reconstruction and analytics. Broker execution telemetry remains out of scope and belongs to EXEC‑LOG‑01.

#### E2 Close Outcome Fields — Applicability Rules (Authoritative)

The following E2 close outcome fields are broker/deal-derived outcome fields:

- `close_reason`
- `close_price`
- `close_profit`
- `close_volume`
- `deal_id`

**Rules**
- For MM_EVENT_CLOSE (final outcome):
  - These fields **MUST** be populated with broker/deal-confirmed values (or `UNKNOWN` fallback for `close_reason`).
  - MM_EVENT_CLOSE remains the **official lifecycle terminator**.

- For MM_EVENT_SCALE_OUT (partial outcome evidence):
  - These fields **MUST** be populated when a broker partial-close deal is matched.
  - If no matching deal is found, emit neutral defaults (same as other non-close events).

- For all non-CLOSE events (`MM_EVENT_ENTRY`, `MM_EVENT_EXIT`, `MM_EVENT_BE`, `MM_EVENT_TRAIL`): 
  - These fields **MUST** be emitted as neutral defaults:
    - `close_reason = ""`
    - `close_price = 0.0`
    - `close_profit = 0.0`
    - `close_volume = 0.0`
    - `deal_id = 0`

**Rationale**

- Prevents data contamination by reserving final lifecycle termination to `MM_EVENT_CLOSE`.
- Allows SCALE_OUT to carry broker-confirmed partial-close evidence for auditability without redefining termination semantics.

---

## Cycle Summary Aggregation Rules (v2.2)

Under the v2.2 volume model:

- Event.close_volume represents executed volume closed in the specific event:
  - MM_EVENT_SCALE_OUT → partial closed volume for that scale-out
  - MM_EVENT_CLOSE → remaining volume closed at lifecycle termination

- Cycle Summary close_volume represents total lifecycle closed volume and MUST be derived as:
  close_volume = SUM(Event.close_volume for MM_EVENT_SCALE_OUT) + Event.close_volume for MM_EVENT_CLOSE

- No separate lifecycle volume field is maintained (total_traded_volume removed as redundant under the monotonic-decreasing lifecycle model).


## Protective Exit Configuration vs Exit Execution

The engine defines **protective exit levels** (SL/TP placement and subsequent modifications such as Break‑Even and Trailing Stop).
These represent **engine decisions about risk geometry**, but the *actual closure* occurs when the broker executes and confirms a deal.

### Contract clarification (Minimal-change approach)
MM‑LOG‑01 does NOT introduce separate event types for TP/SL.

Instead:
- Existing MM events (BE/TRAIL) remain the authoritative record of protective stop decisions
- The final closure is represented by `MM_EVENT_CLOSE` with `close_reason` indicating TP_HIT / SL_HIT / STOP_OUT / etc.

This preserves the Phase 4 contract surface area while enabling correct lifecycle closure attribution.

## Active Schema Version

Current Active Version: v1.3

All logging output MUST conform to:

➡️ MM_Snapshot_Schema.md _(SSOT)_ 

Previous versions:
- v1.2 (superseded)
- v1.1 (superseded)



---

## 🔭 Lifecycle Grouping (cycle_id)

### 🔹 cycle_id

**Type:** integer  
**Required:** ✅ YES  
**Scope:** Per trade lifecycle  

---

### Definition

A unique identifier assigned to each trade lifecycle.

A lifecycle is defined as:

ENTRY → (SCALE_OUT / BREAK_EVEN / TRAIL) → (optional EXIT intent) → CLOSE 

---

### Purpose

- Enables grouping of events into a single trade lifecycle
- Allows full reconstruction of trade behavior
- Supports validation, debugging, and backtesting analysis
  
---

### Rules

- MUST increment on every ENTRY event
- MUST remain constant for all events in the same lifecycle
- MUST be included in:
  - Event logs
  - Snapshot logs
- Every lifecycle MUST terminate with MM_EVENT_CLOSE
- MM_EVENT_EXIT is optional (intent only) and may not appear for TP/SL/STOP_OUT closures

---

### ✅ Contract Requirement

All MM-LOG-01 logs MUST include `cycle_id`.

Logs without `cycle_id` are considered INVALID for lifecycle traceability.

---


## Schema Requirements

### Snapshot Integrity

- Every MM event MUST produce:
  - One BEFORE snapshot
  - One AFTER snapshot

- BEFORE and AFTER MUST be paired

---



### Field Consistency

- All fields MUST match:
  - Name
  - Order
  - Type

as defined in the schema file.

---

### Execution State (Section 5.3)

These fields represent resulting system state AFTER MM action:

- take_profit
- realized_pnl

---

### Execution Outcome (Section 5.4)

These fields represent MM action results:

- action_executed
- execution_reason
- previous_stoploss
- new_stoploss
- closed_lots



## ✅ Execution Outcome Contract

For every MM action:

- Execution MUST be attempted through Execution Layer
- Result MUST be captured and written in AFTER snapshot

---

### ✅ Required Fields

- execution_result (success/failure)
- execution_type (OrderSend / Modify)
- error_code (if failure)

---

### ❌ Invalid State

The following is NOT allowed:

- Action logged without execution result
- AFTER snapshot without execution status
---

### Rules

- Execution Outcome fields MUST be present in AFTER snapshots
- Execution Outcome fields MUST be empty in BEFORE snapshots
- State fields MUST reflect post-action values

---

## ✅ Event to Snapshot Mapping

| Event | BEFORE | AFTER | Execution Required |
|------|--------|------|------------------|
| MM_EVENT_ENTRY | ✅ | ✅ | ✅ |
| MM_EVENT_SCALE_OUT | ✅ | ✅ | ✅ |
| MM_EVENT_BE | ✅ | ✅ | ✅ |
| MM_EVENT_TRAIL | ✅ | ✅ | ✅ |
| MM_EVENT_EXIT | ✅ | ✅ | ✅ |
| MM_EVENT_CLOSE | ✅ | ✅ | ❌ |

## Column Integrity

- Column count MUST match schema definition
- Column order MUST NOT change

Any mismatch MUST trigger a runtime validation error.

---

## Validation Requirements

Logging system MUST enforce:

- Column count validation
- Required field checks
- BEFORE / AFTER pairing
- Non-empty critical fields:
  - symbol
  - mm_phase
  - mm_event

---

## Implementation Binding

This contract is enforced by:

- `MM_LogSchema.mqh` (SSOT include — points to current active schema implementation)
- `CUnifiedTradeLogger` (logging engine)

All logging output MUST:

- Use `MM_LogSchema.mqh` as single source of truth
- Match schema exactly
- Pass runtime validation checks


Additional binding:
- Event logs MUST conform to: MM_Event_Log_Schema.md (SSOT)


---

## Traceability Guarantee

The logging system guarantees that:

- Every MM decision is captured
- Every state transition is reconstructable
- Every action outcome is recorded
- Every log row maps to a defined schema

This enables deterministic reconstruction and audit.

---


## ✅ Contract Enforcement Rules

The following rules are MANDATORY:

1. Every MM event MUST produce:
   - MM_SNAPSHOT_BEFORE
   - MM_SNAPSHOT_AFTER

2. Trade lifecycle termination is STRICT:
   - Every lifecycle MUST include exactly one MM_EVENT_CLOSE
   - A lifecycle without MM_EVENT_CLOSE is INVALID

3. MM_SNAPSHOT_AFTER MUST include execution outcome fields:
   - execution_result
   - error_code (if applicable)

4. All snapshots MUST comply with MM_Snapshot_Schema_v1.2:
   - No missing fields
   - No extra fields
   - Fixed column order

5. Snapshot pairing is STRICT:
   - One BEFORE → One AFTER
   - No orphan records allowed

6. mm_event_intent MUST:
   - Be populated BEFORE execution
   - Persist in AFTER snapshot
   - NEVER be empty




---




## 🚫 Contract Violations

The following are considered system violations:

- Missing execution_result in AFTER snapshot
- Missing mm_event_intent
- Snapshot column mismatch vs schema
- Orphan BEFORE or AFTER snapshot
- Event executed without corresponding snapshot pair
- Missing MM_EVENT_CLOSE (lifecycle termination not confirmed)

---

## ✅ Handling

All violations must:

- Be detected during MM-LOG-01 validation
- Be treated as system failures

## Change Log
### v1.7 (2026-05-19)
- Added SSOT dependency references for Cycle Summary schema, Logging Architecture, and Runtime Validation Checklist.
- Documented v2.2 Cycle Summary lifecycle volume aggregation:
  - Cycle Summary close_volume = SUM(SCALE_OUT close_volume) + CLOSE close_volume.
- Clarified SCALE_OUT E2 close fields must be populated when a broker partial-close deal is matched.
- Marked contract as pending runtime validation under v2.2 semantics.
  
### v1.6
- Updated applicability rules for E2 close outcome fields:
  - MM_EVENT_CLOSE remains mandatory and authoritative terminator (MUST populate close_* + deal_id)
  - MM_EVENT_SCALE_OUT may populate close_* + deal_id when a broker partial-close deal is matched
  - Other non-CLOSE events must continue to emit neutral defaults
- No change to two-phase termination model (EXIT intent vs CLOSE outcome)
- Removed duplicate “Purpose” section by merging lifecycle-grouping bullets into the cycle_id Purpose section (editorial cleanup; no rule changes).

### v1.5
- Added explicit applicability rules for E2 close outcome fields:
  - E2 close fields are authoritative ONLY for MM_EVENT_CLOSE
  - Non-CLOSE events must emit neutral defaults (blank/0)
- Refined close_reason classification to include EA/Expert-initiated closure (MM_EXPERT)
- Clarified MM_EVENT_EXIT as intent-only and not proof of closure
- Resolved Active Schema Version section to reference SSOT snapshot schema consistently

### v1.4
- Introduced two-phase termination model:
  - MM_EVENT_EXIT = engine intent to close (optional)
  - MM_EVENT_CLOSE = broker-confirmed closure (mandatory lifecycle terminator)
- Added close_reason requirement for MM_EVENT_CLOSE (TP_HIT / SL_HIT / STOP_OUT / etc.)
- Clarified protective configuration vs execution outcome (minimal-change approach; BE/TRAIL unchanged)

### v1.3
- Introduced `cycle_id` for lifecycle grouping
- Defined lifecycle-based logging structure (ENTRY → MANAGE → EXIT)
- Added requirement for all logs to include cycle_id
- Enables full trade lifecycle traceability and grouping

### v1.2
- Added Execution Outcome fields
- Introduced:
  - action_executed
  - previous_stoploss / new_stoploss
  - closed_lots
- Separated:
  - Execution State vs Execution Outcome
- Added schema enforcement rules

### v1.1
- Initial snapshot schema
- BEFORE / AFTER state logging

---

## Immutability Rule

This document is version-locked.

- No structural changes allowed after approval
- Any modification requires a new version (v1.4+)
- Historical versions must remain unchanged

---
✅ End of Logging Schema Contract