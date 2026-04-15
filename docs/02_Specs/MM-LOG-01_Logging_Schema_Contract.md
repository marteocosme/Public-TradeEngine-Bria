# MM‑LOG‑01 — Logging Schema Contract
**Status:** Draft 

**Scope:** Money Management & Trade Lifecycle observability

**Applies to:** Phase 5 closure (MM‑LOG‑01 execution)

**Non‑Goal:** Analytics, dashboards, replay tools


## 1. Purpose
This document defines the minimum authoritative logging schema required to satisfy **MM‑LOG‑01**.

Its purpose is to ensure that:

- All lifecycle and Money Management (MM) decisions are observable
- A trade can be fully reconstructed from logs alone
- Logging is consistent, deterministic, and audit‑safe

This is a **contract**, not an implementation guide.

## 2. Design Principles
All logs produced under this contract MUST be:


1. **Deterministic**
    - Log what actually happened, not what was intended
2. **Snapshot‑based**
    - Values must come from captured context, not recomputed later
3. **Structured**
    - Flat, machine‑readable fields (CSV‑safe)
4. **Complete**
- If a lifecycle or MM decision is evaluated, it must log
5. **Minimal**
- Only fields required for reconstruction and validation


## 3. Log Entry Types
All logging events under MM‑LOG‑01 fall into exactly four types:

| Log Type | Purpose |
| --- | --- |
| LIFECYCLE | State transitions & lifecycle milestones | 
| MM_DECISION | Evaluation of MM rules (even if no action taken) |
| MM_ACTION | Executed MM actions (BE, Scale, Trail) |
| EXECUTION | OrderSend / OrderModify outcomes |

No other custom types are allowed during MM‑LOG‑01.


## 4. Common Fields (Required for ALL Logs)
Every log entry MUST include the following fields.

```cpp
timestamp
trade_id
symbol
log_type
lifecycle_state
mm_action
```

### Field Definitions


`timestamp`
Event timestamp (strategy tester / terminal time)


`trade_id`
Stable, unique ID for the trade


`symbol`
Instrument being traded


`log_type`
One of: LIFECYCLE, MM_DECISION, MM_ACTION, EXECUTION


`lifecycle_state`
Current lifecycle state at time of logging


`mm_action`
One of: NONE, BE, SCALE, TRAIL



## 5. Snapshot Fields (Required for Snapshot Logs)
Snapshot logs represent state evidence and MUST include the following.

```cpp
price
stop_loss
take_profit
position_size
risk_percent
floating_pnlr
ealized_pnl
```

### Snapshot Rules

- Snapshot values must reflect exact runtime values
- Snapshots MUST be taken:

    - Before MM action
    - After MM action
    - At lifecycle boundaries
    - At final trade exit

## 6. Lifecycle Logging Contract
### Required Lifecycle Events
For every trade, the following MUST be logged as LIFECYCLE entries:

- Trade opened
- Each lifecycle state transition
- Invalid transition attempt (with reason)
- Trade exit intent
- Final trade exit

### Additional Required Fields
```cpp
prev_lifecycle_state
next_lifecycle_state
reason
```

## 7. Money Management Decision Logging
### MM_DECISION Logs
Every MM rule evaluation MUST emit a MM_DECISION log, even if no action is taken.
```cpp
rule_id
decision_result   // TRIGGERED | SKIPPED
reason
```

Examples:

- BE evaluated but conditions not met
- Trailing stop evaluated but no update made

Silent MM evaluations are forbidden.

## 8. Money Management Action Logging
### MM_ACTION Logs
When an MM action is executed, an explicit MM_ACTION log MUST be emitted.

Additional required fields:
```cpp
old_stop_loss
new_stop_loss
old_position_size
new_position_size
```

Rules:

- Before‑snapshot → MM_ACTION → After‑snapshot is mandatory
- Partial information is considered invalid


## 9. Execution Outcome Logging
### EXECUTION Logs
All trade execution actions MUST be logged.
```cpp
execution_type    // OrderSend | OrderModify
result            // SUCCESS | FAILURE
error_code
error_message
```
Rules:
- Failures must never be silent
 -Blocked execution paths must log explicitly


## 10. Snapshot Enforcement Rules
The following are **hard guarantees:**

- No lifecycle transition without a snapshot
- No MM action without before & after snapshots
- No trade exit without a terminal snapshot
- Violations must:
    - Emit an error log
    - Fail deterministically


## 11. Contract Versioning

- This schema is versioned
- Breaking changes require:
    - Schema version bump
    - Explicit mention in Phase documentation

Current version:
```cpp
MM-LOG-01_SCHEMA_VERSION = 1
```

## 12. Out of Scope (Explicit)
This contract does not define:

- Replay tooling
- Analytics queries
- Dashboards
- Storage formats beyond structured logs

Those belong to **Phase 6** only.

## 13. Final Assertion

If a lifecycle or Money Management action cannot be reconstructed
using only logs conforming to this schema,
**MM‑LOG‑01 is not complete.**

---
✅ End of Logging Schema Contract
