
## ✅ STATUS: ACTIVE — SINGLE SOURCE OF TRUTH

This is the authoritative MM Snapshot Schema (latest version).

All implementations and logging must follow this schema.

Previous versions are stored in:
/00_Core/_archive/

# MM Snapshot Schema

## Status ✅ Active (SSOT) 
Version: v2.0
Status: ✅ Active ✅ LOCKED
Last Updated: 2026-05-11 (UTC+8)
 

## Supersedes
- MM_Snapshot_Schema_v1.3.md
- MM_Snapshot_Schema_v1.2.md
- MM_Snapshot_Schema_v1.1.md


## 📚 Previous Versions

- v1.0 → Initial schema version (archived)
- v1.1 → Intermediate version (archived)
- v1.2 → Added Execution Outcome fields (archived)
- v1.3 → Doc clarifications (archived)

Location: `/00_Core/_archive/`



## Change Summary (v2.0)

**Breaking change release.**
- Switched Snapshot logging to **FULL-STATE** for BOTH BEFORE and AFTER (no blank fields).
- Deprecated and removed `trade_context_id` from the schema (replaced with explicit identity fields).
- Added explicit identity model:
  - `cycle_id`, `internal_trade_id`, `ticket`, `position_id`
- Added `correlation_id` to bind:
  - Event ↔ Snapshot BEFORE ↔ Snapshot AFTER
- Added MM inputs actually used:
  - `risk_model`, `risk_value`, `risk_amount_used`
- Formalized N/A rules:
  - numeric N/A = 0, string N/A = "" (no denormals, no blanks-as-missing)


## Change Log

### v1.3
- Aligned schema coverage with MM-LOG-01 contract v1.4 by explicitly including MM_EVENT_CLOSE as a covered lifecycle action (no column changes).
- Clarified CLOSE snapshot population rules (Outcome confirmation; not an engine execution attempt).
- Corrected documentation inconsistencies (no schema column changes).

### v1.2
- Added Execution Outcome fields
- Introduced causal MM logging:
  - action_executed
  - previous_stoploss / new_stoploss
  - closed_lots
- Separated:
  - Execution State vs Execution Outcome
- Added enforcement rules for schema and validation

### v1.1
- Initial snapshot schema
- BEFORE / AFTER state logging


## Scope

This schema defines:

- Money Management (MM) snapshot logging
- Trade state BEFORE and AFTER MM actions
- Exposure and risk tracking
- Execution State (resulting system state)
- Execution Outcome (MM action results)

This schema does NOT cover:

- Broker execution logging (OrderSend / OrderModify)
- External execution responses or broker errors

→ Covered under: EXEC-LOG-01



## Implementation Status

Status: Implemented ✅  
Phase: Phase 4 — Logging & Observability  
Validation: Partial (manual log inspection)

## Implementation Binding

This schema is implemented in:

`/MyInclude/NNFX/Core/Logging/MM_LogSchema.mqh`

All logging output MUST:

- Match field names exactly
- Follow column order exactly
- Pass runtime validation checks

Any deviation invalidates the schema contract.

### Notes
- BEFORE / AFTER snapshot pairing enforced (INF-3)
- Header generation implemented (content-based detection)
- Schema not yet centralized in code (duplication exists)
- Automated validation layer not yet implemented
- `current_position_lots` reflects the actual live position size at the time of snapshot.
- `current_risk_exposure` remains anchored to ENTRY risk and does not change during BE, TRAIL, or SCALE_OUT.


### Next Steps
- Introduce Single Schema Definition (code-level enforcement)
- Apply Logging Hardening (header dispatcher integration)
- Add schema validation checks


---

# MM Snapshot Schema v2.0 (SSOT)

## 1. Purpose
This schema defines the snapshot contract used to make Money Management (MM) decisions fully observable, reconstructable, and auditable from logs alone.
Snapshots capture:
- State BEFORE an MM action
- Execution Outcome (what happened + why)
- State AFTER an MM action

**v2.0 policy: FULL-STATE**
- BOTH BEFORE and AFTER snapshots MUST populate the full core state set (no blanks-as-missing).
- If a field is not applicable for an event, it MUST be set to a stable sentinel:
  - numeric fields → 0
  - string fields → "" (empty string)

This prevents uninitialized/denormal artifacts (e.g., `5e-324`) and enables deterministic parsing.

## 2. Snapshot Types
Two snapshot types exist and are used uniformly across all MM actions:
- MM_SNAPSHOT_BEFORE — state immediately before an MM decision/execution attempt
- MM_SNAPSHOT_AFTER  — state immediately after an MM decision/execution attempt

## 3. Deprecation (Breaking Change)
### Deprecated/Removed Field
- `trade_context_id` — removed in v2.0

### Replacement Identity Fields (v2.0)
- `cycle_id` (int) — lifecycle grouping id (shared with MM Event log)
- `internal_trade_id` (long) — deterministic engine id (stable across lifecycle)
- `ticket` (ulong) — broker ticket (0 pre-entry)
- `position_id` (long) — POSITION_IDENTIFIER (stable lifecycle id across deals; important for hedging/netting)
- `correlation_id` (ulong) — binds Event ↔ Snapshot BEFORE ↔ Snapshot AFTER for the same MM action


#### Implementation Note (v2.0)
**Current rule:** `internal_trade_id == cycle_id`.

Rationale:
- The engine currently models **one trade lifecycle per entry**:
  ENTRY → (SCALE_OUT / BE / TRAIL / EXIT) → CLOSE.
- Therefore, the lifecycle grouping id (`cycle_id`) is sufficient as the deterministic trade identity in the current design.

Future:
- `internal_trade_id` is reserved for cases where a single trade concept may span multiple broker tickets/positions
  (e.g., scale-in, multi-order entries, persistence across restarts, complex netting/hedging flows).


## 4. Actions Covered
This schema applies to:
- MM_EVENT_ENTRY
- MM_EVENT_SCALE_OUT
- MM_EVENT_BE
- MM_EVENT_TRAIL
- MM_EVENT_EXIT
- MM_EVENT_CLOSE (broker-confirmed lifecycle outcome)

## 5. Column Order Guarantee (v2.0)
All logs MUST follow the exact column order below. Missing or extra columns invalidate the log.

### 5.1 Snapshot Columns (v2.0) — Full-State
1.  debug_event_id
2.  correlation_id

**Identity**
3.  cycle_id
4.  internal_trade_id
5.  ticket
6.  position_id

**Timing / Classification**
7.  timestamp
8.  symbol
9.  timeframe
10. record_type
11. mm_phase
12. mm_event

**Account (Full-State)**
13. balance
14. equity
15. free_margin

**Exposure (Full-State)**
16. current_position_lots
17. current_risk_exposure

**Market Context (Full-State)**
18. current_price
19. atr_value

**Execution State (Full-State)**
20. take_profit
21. floating_pnl
22. realized_pnl

**Risk Geometry (Full-State)**
23. stoploss_points
24. value_per_point

**MM Inputs Actually Used (Full-State)**
25. risk_model
26. risk_value
27. risk_amount_used

**Scale Context (Full-State, N/A=0)**
28. scale_atr_multiple
29. scale_fraction

**Execution Outcome (Always Populated)**
30. action_executed
31. execution_reason
32. previous_stoploss
33. new_stoploss
34. closed_lots
35. event_outcome   (SUCCESS | FAIL | SKIP)

## 6. Field Population Rules (Strict)
- BEFORE snapshot MUST be emitted before any MM decision logic mutates state.
- AFTER snapshot MUST be emitted after the MM attempt completes (success/fail/skip).
- FULL-STATE rule: AFTER MUST NOT write blank placeholders for numeric fields.
- action_executed MUST be TRUE or FALSE (never empty).
- execution_reason MUST be populated when action_executed = FALSE.
- Scale context fields MUST be 0 for non-SCALE_OUT events.
- Stoploss outcome fields apply only to BE/TRAIL:
  - previous_stoploss and new_stoploss MUST be 0 for non BE/TRAIL events.
- closed_lots applies only to SCALE_OUT:
  - closed_lots MUST be 0 for non SCALE_OUT events.
- CLOSE rule:
  - CLOSE is broker-confirmed outcome, not an engine execution attempt.
  - action_executed = TRUE indicates closure confirmation succeeded.

## 7. Reconstruction Guarantee
This schema guarantees that every MM action is reconstructable using:
- Snapshot BEFORE (Full-State)
- Execution Outcome (Always Populated)
- Snapshot AFTER (Full-State)

---


# MM Snapshot Schema v1.2
**Document ID:** MM-SNAPSHOT-SCHEMA-v1.2

**Applies** To: TradeEngine-Bria (NNFX)

**Related Spec:** MM-LOG-01 — Logging Completion & Validation

**Status:** ✅ Frozen (Do not modify without version bump)


## 1. Purpose
This document defines the frozen snapshot contract used to make all Money Management (MM) decisions **fully observable, reconstructable, and auditable from logs alone.**

The snapshot system captures state-before and state-after every MM action, without influencing MM logic itself.


Version v1.1 extends v1.0 by explicitly logging market context required for precise reconstruction:

Current market price
ATR value actually used by MM


``` 
⚠️ Rule: Once frozen, no fields may be added, removed, or repurposed without incrementing the schema version.
```



## 2. Snapshot Types
Two snapshot types exist and are used uniformly across all MM actions:

- **MM_SNAPSHOT_BEFORE —** Captures state immediately before an MM decision
- **MM_SNAPSHOT_AFTER —** Captures state immediately after an MM decision

Both snapshots are **purely observational.**


### BEFORE vs AFTER Snapshot Rules

#### BEFORE Snapshot

- Represents system state BEFORE MM action
- MUST NOT contain Execution Outcome values
- Execution Outcome fields MUST be empty


#### AFTER Snapshot

- Represents system state AFTER MM action
- MUST include Execution State values
- MUST include Execution Outcome fields

### CLOSE Snapshot Rules (MM_EVENT_CLOSE)
- CLOSE is a broker-confirmed lifecycle outcome (not an engine execution attempt).
- BEFORE snapshot: observational capture immediately before closure confirmation is recorded.
- AFTER snapshot: observational capture immediately after closure is confirmed (position lots may be 0).
- Execution Outcome fields remain valid:
  - action_executed = TRUE indicates closure was confirmed
  - execution_reason may remain empty unless closure confirmation failed (rare/unknown cases)


## 3. MM Actions Covered
This schema applies to the following MM paths:

|   | MM Action | Code Event | Covered |
| --- | --- | --- | --- |
| 1 | Entry	| MM_EVENT_ENTRY	| ✅
| 2 | Scale-Out |	MM_EVENT_SCALE_OUT	| ✅ |
| 3 | Break-Even | 	MM_EVENT_BE | 	✅ |
| 4 | Trailing Stop |	MM_EVENT_TRAIL	| ✅ |
| 5 | Exit |	MM_EVENT_EXIT	| ✅ |
| 6 | Close (Broker-confirnmed) | MM_EVENT_CLOSE | ✅ |


## 4. MM_SNAPSHOT_BEFORE Schema
### 4.1 Identity & Timing

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | timestamp |	datetime |	Snapshot capture time |	All |
| 2 | symbol	| string |	Trading symbol	| All
| 3 | timeframe	| ENUM_TIMEFRAMES |	Execution timeframe |	All
| 4 | trade_context_id	| ulong |	Trade / ticket identifier (0 pre-entry) |	All


### 4.2 Lifecycle Intent

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 |  mm_phase	| string |	MM lifecycle phase (ENTRY / MANAGE / EXIT) | 	All |
| 2 | mm_event_intent |	string |	MM intent (ENTRY, SCALE_OUT, BE, TRAIL, EXIT) |	All



### 4.3 Account State

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | balance |	double |	Account balance at decision time |	All |
| 2 | equity |	double |	Account equity at decision time |	All |
| 3 | free_margin |	double | 	Free margin (ACCOUNT_MARGIN_FREE) |	All |



### 4.4 Exposure State

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | current_position_lots	|  double	| Current open volume |	All |
| 2 | current_risk_exposure	| double | ENTRY-anchored risk amount |	All |

### 4.5 Market Context (NEW in v1.1)

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | current_price  |	double | Market price at MM decision time (Bid/Ask as appropriate) | All |
| 2 | atr_value  |	double | ATR value actually used by MM at decision time | All |

### 4.6 Execution-State Observability

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | take_profit  |	double |	Current TP price |	MANAGE / EXIT |
| 2 | floating_pnl |	double	| Floating P/L at decision time |	MANAGE / EXIT |



### 4.7 Risk Geometry (ENTRY-Anchored)

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | stoploss_points |	double |	SL distance in points |	All |
| 2 | value_per_point |	double |	Monetary value per point |	All |


### 4.8 SCALE_OUT Trigger Context (Conditional)

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | scale_atr_multiple | double |	ATR multiple triggering scale-out |	SCALE_OUT |
| 2| scale_fraction	| double |	Fraction of position to close | SCALE_OUT |

```
⚠️ These fields must be zero for non-SCALE_OUT snapshots.
```

## 5. MM_SNAPSHOT_AFTER Schema
### 5.1 Identity & Timing

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 |  timestamp | datetime |	Snapshot capture time |	All |
| 2 | symbol |	string |	Trading symbol |	All |
| 3 | timeframe |	ENUM_TIMEFRAMES |	Execution timeframe | 	All |



### 5.2 Exposure Result

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | current_position_lots |	double |	Current position volume after MM action |	All |
| 2 | current_risk_exposure |	double |	ENTRY-anchored risk amount	| All |


#### Notes

- current_position_lots reflects LIVE position size at snapshot time
- current_risk_exposure is anchored to ENTRY risk
- current_risk_exposure does NOT change during:
  - BREAK-EVEN
  - TRAILING
  - SCALE_OUT

This ensures risk consistency for reconstruction analysis.




### 5.3 Execution State

These fields represent the resulting trade state AFTER a Money Management (MM) action is applied.

They describe the resulting system state rather than the decision process itself.


|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | take_profit |	double |	TP after MM action	| MANAGE / EXIT |
| 2 | realized_pnl |	double	| Realized P/L after MM action |	SCALE_OUT / EXIT |


#### Notes

- These values reflect the system AFTER execution.
- They are required for reconstructing trade outcomes.


### 5.4 Execution Outcome

These fields represent the outcome of the Money Management decision process.

They describe:
- Whether an action was executed
- What change occurred
- Why an action was not executed (if applicable)


|  | Field | Type | Description | Used By |
|--- |------|------|-------------|--------|
| 1 | action_executed | bool | Whether the MM action was executed | All |
| 2 | execution_reason | string | Reason if action was skipped or failed | All |
| 3 | previous_stoploss | double | Previous SL before modification | BE, TRAIL |
| 4 | new_stoploss | double | New SL after modification | BE, TRAIL |
| 5 | closed_lots | double | Lots closed during scale-out | SCALE_OUT |


#### Execution Outcome Rules

- action_executed MUST be TRUE or FALSE (not empty)
- execution_reason MUST be populated when action_executed = FALSE
- previous_stoploss and new_stoploss apply ONLY to BE and TRAIL
- closed_lots applies ONLY to SCALE_OUT



### 5.5 Risk Geometry (Unchanged)

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | stoploss_points |	double |	SL distance (unchanged)	| All |
| 2 | value_per_point |	double |	Value per point (unchanged) |	All |

## 6. Field Population Rules (Strict)

- BEFORE snapshots **must be emitted before any MM decision logic**
- AFTER snapshots **must be emitted only after MM action succeeds**
- No snapshot may mutate system state
- No MM logic may depend on snapshot values


## 7. Versioning Rules

- Any schema change → new version (v1.1, v2.0, etc.)
- Old versions remain valid for historical log parsing
- MM-LOG-01 validation is tied to v1.0 only


### 8. Compliance Statement
✅ ENTRY, SCALE_OUT, BREAK-EVEN, TRAILING, and EXIT have been validated against this schema.3

✅ MM decisions are fully reconstructable from logs alone.

✅ This schema satisfies MM-LOG-01 observability requirements.

## 9. Column Order Guarantee

All logs MUST follow the exact column order defined in this schema.

- Column order MUST NOT change
- Missing or extra columns invalidate the log
- Column integrity MUST be enforced at runtime

This is required for machine parsing and validation.


## 10. Reconstruction Guarantee

This schema guarantees that:

- Every MM decision is captured
- Every state transition can be reconstructed
- Every action outcome is traceable

Each event must provide:

1. BEFORE state
2. Execution Outcome
3. AFTER state

All three layers are REQUIRED for valid reconstruction.


## 11. Event Field Mapping

### SCALE_OUT
- action_executed
- closed_lots

### BREAK-EVEN
- action_executed
- previous_stoploss
- new_stoploss

### TRAILING
- action_executed
- previous_stoploss
- new_stoploss


## 12 Immutability Rule

This schema version is locked.

- No structural changes allowed after approval
- Any modification requires a new version (v2.1+ or v3.0)
- Historical versions must remain unchanged


--- 
#### End of Document — MM_Snapshot_Schema
