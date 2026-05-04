# MM‑LOG‑01 — Execution Mapping

## 🔗 Dependencies

### Snapshot Schema
→ /docs/02_Specs/00_Core/MM_Snapshot_Schema_v1.2.md

All snapshot fields referenced in this document must conform to the schema above.

⚠️ This file does NOT define or override schema fields.

## Purpose:
Translate MM‑LOG‑01 requirements into exact execution touchpoints in the codebase.

This document answers one question only:

_“Where, exactly, do I add or validate logging and snapshot enforcement?”_

It is a bridge between:

- ✅ MM‑LOG‑01 checklist
- ✅ Logging Schema Contract
- ✅ Actual code execution


## 1. Guiding Rules for Execution

- No new logic paths are introduced
- No strategy or entry logic is modified
- Every mapping below corresponds to one or more checklist items
- If a function appears here, it must be MM‑LOG‑01‑compliant before phase closure


## 2. Trade Entry & Initialization
### Trigger

- Trade is opened (post‑OrderSend success)

### Touchpoints

- Trade execution module
- TradeContext initialization
- Lifecycle state initialization

### Required Actions

- Emit LIFECYCLE log → Trade Opened
- Capture initial snapshot:
    - Price
    - SL / TP
    - Position size
    - Risk %
    - Lifecycle state

### Checklist Coverage
- Lifecycle snapshot: ✅
- Trade start observability: ✅


## 3. Lifecycle State Transitions (Global)
### Trigger

- Any lifecycle state change
- Any invalid transition attempt

### Touchpoints

- Lifecycle orchestrator
- State transition guard logic

### Required Actions

- BEFORE transition:
    - Emit snapshot
- Transition event:
    - Emit LIFECYCLE log (prev → next)
- Invalid transition:
    - Emit LIFECYCLE log with reason
    - Fail deterministically

## Checklist Coverage

- Lifecycle logging completeness: ✅
- Snapshot enforcement rules: ✅


## 4. Break‑Even (BE) Execution Mapping
### 4.1 BE Evaluation
#### Trigger:
BE check function (called per tick / lifecycle event)
#### Required Logs:

- Emit MM_DECISION log
    - Rule evaluated
    - Result: TRIGGERED / SKIPPED
    - Reason

✅ Even when BE does nothing.

### 4.2 BE Execution
#### Trigger:
BE condition met
#### Required Sequence (Strict Order):

1. Snapshot (before)
2. Emit MM_ACTION log

- mm_action = BE
- old SL → new SL
3. OrderModify
4. Emit EXECUTION log
5. Snapshot (after)

#### Enforcement Rule:

- Missing snapshot → block BE execution

#### Checklist Coverage

- BE decisions: ✅
- BE snapshots: ✅
- Execution evidence: ✅


## 5. Scale‑Out Execution Mapping
### 5.1 Scale‑Out Evaluation
#### Trigger:
Scale‑out check function
#### Required Logs:

- Emit MM_DECISION
    - Triggered / Skipped
    - Reason




### 5.2 Scale‑Out Execution
#### Trigger:
Scale‑out condition met
#### Required Sequence:

1. Snapshot (before)
2. Emit MM_ACTION
    - mm_action = SCALE
    - old size → new size
3. Partial OrderClose / equivalent
4. Emit EXECUTION log
5. Snapshot (after)

#### Checklist Coverage

- Scale‑out observability: ✅
- Volume evolution traceable: ✅


## 6. Trailing Stop Execution Mapping
### 6.1 Trailing Evaluation
#### Trigger:
Trailing rule check
#### Required Logs:

- Emit MM_DECISION
    - Updated / Not updated
    - Rule used
    - Reason (if skipped)

### 6.2 Trailing Execution
#### Trigger:
Trailing update condition met
#### Required Sequence:

1. Snapshot (before)
2. Emit MM_ACTION
    - mm_action = TRAIL
    - old SL → new SL
3. OrderModify
4. Emit EXECUTION log
5. Snapshot (after)

#### Checklist Coverage
- Trailing auditability: ✅
- SL evolution traceable: ✅

## 7. Trade Exit Mapping
### 7.1 Exit Intent
#### Trigger:
Exit condition detected (TP/SL/manual/forced)
#### Required Actions:
- Emit LIFECYCLE log → Exit Intent
- Snapshot of final MM state


### 7.2 Final Exit
#### Trigger:
Trade fully closed
#### Required Actions:
- Emit final snapshot
- Emit LIFECYCLE log → Trade Closed
- Record realized P/L

#### Hard Rule:

- No trade may exit without a terminal snapshot

#### Checklist Coverage
- Terminal observability: ✅
- Replay completeness: ✅


## 8. Execution Failure & Blocking Paths
### Trigger
- OrderSend fails
- OrderModify fails
- MM execution blocked due to missing snapshot

### Required Actions
- Emit EXECUTION log
    - FAILURE
    - Error code
    - Reason
- Abort further action deterministically

✅ Silent fallback is forbidden.

## 9. Global Enforcement Hooks
These checks must exist globally:

- Lifecycle transition requires snapshot
- MM execution requires before/after snapshots
- Trade exit requires terminal snapshot

Violations:

- Logged explicitly
- Cause deterministic failure


## 10. Validation Mapping (Post‑Coding)
After implementation:

- Run Strategy Tester
- Extract logs only
- Reconstruct:
    - Lifecycle
    - MM decisions
    - SL / volume evolution
- Confirm 100% checklist coverage


### 11. Completion Condition
This execution mapping is considered fulfilled when:

- Every listed touchpoint emits logs per the schema
- No checklist item maps to an unimplemented path
- MM‑LOG‑01 validation passes

Only then may MM‑LOG‑01 be formally closed.

---

✅ End of MM‑LOG‑01 Execution Mapping