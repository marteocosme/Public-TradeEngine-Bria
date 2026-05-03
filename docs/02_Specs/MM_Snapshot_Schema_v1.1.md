

## Implementation Status

Status: Implemented ✅  
Phase: Phase 4 — Logging & Observability  
Validation: Partial (manual log inspection)

### Notes
- BEFORE / AFTER snapshot pairing enforced (INF-3)
- Header generation implemented (content-based detection)
- Schema not yet centralized in code (duplication exists)
- Automated validation layer not yet implemented

### Next Steps
- Introduce Single Schema Definition (code-level enforcement)
- Apply Logging Hardening (header dispatcher integration)
- Add schema validation checks

# MM Snapshot Schema v1.0
**Document ID:** MM-SNAPSHOT-SCHEMA-v1.1

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
| 1 | calculated_lot_size |	double |	Resulting position volume |	All |
| 2 | calculated_risk_amount |	double |	ENTRY-anchored risk amount	| All |



### 5.3 Execution Outcome

|  | Field |	Type |	Description |	Used By |
| --- | --- | --- |	--- | --- |
| 1 | take_profit |	double |	TP after MM action	| MANAGE / EXIT |
| 2 | realized_pnl |	double	| Realized P/L after MM action |	SCALE_OUT / EXIT |



### 5.4 Risk Geometry (Unchanged)

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

--- 
#### End of Document — MM_Snapshot_Schema_v1.1
