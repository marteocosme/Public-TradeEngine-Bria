
# MM Snapshot Schema v1.2

## Status
Version: v1.2
Status: ✅ Active ✅  LOCKED  

## Supersedes
- MM_Snapshot_Schema_v1.1.md


## 📚 Previous Versions

- v1.0 → Initial schema version (archived)
- v1.1 → Intermediate version (archived)

Location: `/00_Core/_archive/`



## Change Summary
- Added Execution Outcome fields
- Improved observability for MM actions

## Change Log

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

/MyInclude/NNFX/Core/Logging/MM_LogSchema_v1_2.mqh

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



## 3. MM Actions Covered
This schema applies to the following MM paths:

|   | MM Action | Code Event | Covered |
| --- | --- | --- | --- |
| 1 | Entry	| MM_EVENT_ENTRY	| ✅
| 2 | Scale-Out |	MM_EVENT_SCALE_OUT	| ✅ |
| 3 | Break-Even | 	MM_EVENT_BE | 	✅ |
| 4 | Trailing Stop |	MM_EVENT_TRAIL	| ✅ |
| 5 | Exit |	MM_EVENT_EXIT	| ✅ |


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
| 2  | equity |	double |	Account equity at decision time |	All |
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



### 4.6 Risk Geometry (ENTRY-Anchored)

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | stoploss_points |	double |	SL distance in points |	All |
| 2 | value_per_point |	double |	Monetary value per point |	All |


### 4.7 SCALE_OUT Trigger Context (Conditional)

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
| 1 | current_position_lot |	double |	Current position volume after MM action |	All |
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
- Any modification requires a new version (v1.3+)
- Historical versions must remain unchanged


--- 
#### End of Document — MM_Snapshot_Schema_v1.2
