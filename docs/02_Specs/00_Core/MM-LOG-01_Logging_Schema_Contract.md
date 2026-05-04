
# MM-LOG-01 Logging Schema Contract

## 🔒 Document Status

Version: v1.0  
Status: ✅ ACTIVE (SSOT)  
Last Updated: 2026-05-04  

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
✅ Approved (Schema v1.2 Active)

---

## Version
v1.2

### Supersedes
- v1.1

---


## 🔗 Dependency

This contract depends on:

- MM_Snapshot_Schema_v1.2.md
- TradeLifecycleEvents.md
- Trade_Lifecycle_Orchestrator_v1.2.md

---

## ⚠️ Rule

If schema changes → contract MUST be updated before implementation


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

## Active Schema Version

Current Active Version: v1.2

All logging output MUST conform to:

➡️ MM_Snapshot_Schema_v1.2.md

Previous versions:
- v1.1 (superseded, retained for reference)


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

- `MM_LogSchema_v1_2.mqh` (schema definition)
- `CUnifiedTradeLogger` (logging engine)

All logging output MUST:

- Use `MM_LogSchema_v1_2.mqh` as single source of truth
- Match schema exactly
- Pass runtime validation checks

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

2. MM_SNAPSHOT_AFTER MUST include execution outcome fields:
   - execution_result
   - error_code (if applicable)

3. All snapshots MUST comply with MM_Snapshot_Schema_v1.2:
   - No missing fields
   - No extra fields
   - Fixed column order

4. Snapshot pairing is STRICT:
   - One BEFORE → One AFTER
   - No orphan records allowed

5. mm_event_intent MUST:
   - Be populated BEFORE execution
   - Persist in AFTER snapshot
   - NEVER be empty


## 🔗 Dependencies

This contract depends on:

- MM_Snapshot_Schema_v1.2.md
- TradeLifecycleEvents.md
- Trade_Lifecycle_Orchestrator_v1.2.md

---

## ⚠️ Change Rule

If any dependency changes:

1. Schema → Contract MUST update
2. Contract → Validation MUST update
3. Only then → Code update allowed


## 🚫 Contract Violations

The following are considered system violations:

- Missing execution_result in AFTER snapshot
- Missing mm_event_intent
- Snapshot column mismatch vs schema
- Orphan BEFORE or AFTER snapshot
- Event executed without corresponding snapshot pair

---

## ✅ Handling

All violations must:

- Be detected during MM-LOG-01 validation
- Be treated as system failures

## Change Log

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
- Any modification requires a new version (v1.3+)
- Historical versions must remain unchanged

---
✅ End of Logging Schema Contract
