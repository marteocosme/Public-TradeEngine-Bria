
## ✅ STATUS: ACTIVE — SINGLE SOURCE OF TRUTH

This is the authoritative MM Snapshot Schema (latest version).

All implementations and logging must follow this schema.

Previous versions are stored in:
/00_Core/_archive/

# MM Snapshot Schema

## Status ✅ Active (SSOT) 
Version: v2.1
Status: ✅ Active ✅ LOCKED
Last Updated: 2026-05-12 (UTC+8)
 

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


## Change Summary (v2.1)

**Additive schema release.**

- Added `position_type` to Snapshot identity fields.
- `position_type` uses stable string values:
  - `LONG`
  - `SHORT`
  - `NA`
- Snapshot column count increased from 35 to 36.
- Confirmed `correlation_id` pairing across BEFORE and AFTER snapshots.
- Confirmed `internal_trade_id == cycle_id` for the current implementation.
- Confirmed C1 outcome semantics:
  - `SUCCESS`
  - `FAIL`
  - `SKIP`
- Confirmed failed/skipped AFTER rows include `execution_reason`.
- Confirmed ENTRY AFTER no longer emits `SKIP`; ENTRY AFTER uses `SUCCESS` or `FAIL`.
- Confirmed no DBL_MAX / invalid ATR sentinel values are emitted.
- Clarified that `MM_EVENT_CLOSE` is currently Event-only broker confirmation and does not require Snapshot BEFORE/AFTER pairs under v2.1.


### Change Summary (v2.0)
**Historical baseline for v2.1.**

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

### v2.1 (2026-05-12)
- Added `position_type` after `position_id`.
- Increased Snapshot schema column count from 35 to 36.
- Validated `position_type` values as `LONG`, `SHORT`, or `NA`.
- Validated BEFORE/AFTER pairing by `correlation_id`.
- Validated Full-State AFTER population.
- Validated C1 outcome semantics for AFTER snapshots:
  - `SUCCESS`
  - `FAIL`
  - `SKIP`
- Validated that failed/skipped AFTER rows include `execution_reason`.
- Validated ENTRY AFTER outcomes as `SUCCESS` or `FAIL` only.
- Validated ATR sanitation; no DBL_MAX or invalid ATR sentinel values are emitted.
- Clarified CLOSE handling: `MM_EVENT_CLOSE` is Event-only broker confirmation in the current v2.1 runtime model.

### v2.0 (2026-05-11)
- Introduced Full-State BEFORE/AFTER snapshot policy.
- Removed `trade_context_id`.
- Added explicit identity fields:
  - `cycle_id`
  - `internal_trade_id`
  - `ticket`
  - `position_id`
- Added `correlation_id`.
- Added risk input fields:
  - `risk_model`
  - `risk_value`
  - `risk_amount_used`
- Formalized stable N/A rules:
  - numeric N/A = 0
  - string N/A = ""

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
Runtime Validation: ✅ Passed under v2.1
Validation: Outputs:
- `NNFX_TradeEvents_MM_Snapshots.csv`
- `NNFX_TradeEvents_MM_Events.csv`
- `NNFX_TradeEvents_MM_Cycle_Summary.csv`


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

# MM Snapshot Schema v2.1 (SSOT)

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


#### position_type Rule (v2.1)

`position_type` provides direction context for the position at snapshot time.

Allowed values:

- `LONG`
- `SHORT`
- `NA`

Population rules:

- If a live position is selectable, `position_type` MUST reflect the live position direction
- If a live position is not selectable, the logger MAY use last-known cached direction.
- If direction cannot be derived, `position_type` MUST be `NA`.
- Trend values such as `UpTrend` or `DownTrend` are not valid for `position_type`.


## 4. Actions Covered
This schema applies to Snapshot BEFORE/AFTER pairs for:

- `MM_EVENT_ENTRY`
- `MM_EVENT_SCALE_OUT`
- `MM_EVENT_BE`
- `MM_EVENT_TRAIL`
- `MM_EVENT_EXIT`

### CLOSE Handling

`MM_EVENT_CLOSE` is currently emitted as an Event-only broker-confirmed lifecycle terminator.

Under the current v2.1 runtime model:

- CLOSE does not require a Snapshot BEFORE/AFTER pair.
- CLOSE evidence is recorded in the Event log.
- Completed lifecycle aggregation is recorded in the Cycle Summary log.
- A future schema version may introduce CLOSE snapshots if explicitly required.


## 5. Column Order Guarantee (v2.1)
All logs MUST follow the exact column order below. Missing or extra columns invalidate the log.

### 5.1 Snapshot Columns (v2.1) — Full-State
1.  `debug_event_id`
2.  `correlation_id`

**Identity**
3.  `cycle_id`
4.  `internal_trade_id`
5.  `ticket`
6.  `position_id`
7.  `position_type`

**Timing / Classification**
8.  `timestamp`
9.  `symbol`
10. `timeframe`
11. `record_type`
12. `mm_phase`
13. `mm_event`

**Account (Full-State)**
14. `balance`
15. `equity`
16. `free_margin`

**Exposure (Full-State)**
17. `current_position_lots`
18. `current_risk_exposure`

**Market Context (Full-State)**
19. `current_price`
20. `atr_value`

**Execution State (Full-State)**
21. `take_profit`
22. `floating_pnl`
23. `realized_pnl`

**Risk Geometry (Full-State)**
24. `stoploss_points`
25. `value_per_point`

**MM Inputs Actually Used (Full-State)**
26. `risk_model`
27. `risk_value`
28. `risk_amount_used`

**Scale Context (Full-State, N/A=0)**
29. `scale_atr_multiple`
30. `scale_fraction`

**Execution Outcome (Always Populated)**
31. `action_executed`
32. `execution_reason`
33. `previous_stoploss`
34. `new_stoploss`
35. `closed_lots`
36. `event_outcome` 

## 6. Field Population Rules (Strict)

- BEFORE snapshot MUST be emitted before an MM decision/execution attempt.
- AFTER snapshot MUST be emitted after the MM attempt completes.
- FULL-STATE rule: AFTER MUST NOT write blank placeholders for numeric fields.
- Numeric N/A MUST be `0`.
- String N/A MUST be `""`, except controlled enum-like fields such as `position_type` and `event_outcome`.
- `position_type` MUST be one of:
  - `LONG`
  - `SHORT`
  - `NA`
- `action_executed` MUST be `true` or `false`.
- BEFORE rows MUST keep outcome fields neutral:
  - `action_executed = false`
  - `execution_reason = ""`
  - `previous_stoploss = 0`
  - `new_stoploss = 0`
  - `closed_lots = 0`
  - `event_outcome = ""`
- AFTER rows MUST set `event_outcome` to one of:
  - `SUCCESS`
  - `FAIL`
  - `SKIP`
- `execution_reason` MUST be populated when `action_executed = false`.
- ENTRY AFTER MUST use `SUCCESS` or `FAIL`, not `SKIP`.
- Scale context fields MUST be `0` for non-SCALE_OUT events.
- Stoploss outcome fields apply only to BE/TRAIL:
  - `previous_stoploss`
  - `new_stoploss`
- `previous_stoploss` and `new_stoploss` MUST be `0` for non-BE/TRAIL events.
- `closed_lots` applies only to SCALE_OUT.
- `closed_lots` MUST be `0` for non-SCALE_OUT events.
- ATR values MUST NOT emit DBL_MAX or invalid sentinel values.


### 7. Runtime Validation Evidence — v2.1

Runtime validation passed for the Snapshot log under v2.1.

Validated rules:

- 36-column schema matched exactly.
- No missing columns.
- No extra columns.
- Critical identity fields were populated.
- `position_type` contained only valid values.
- BEFORE/AFTER pairing by `correlation_id` passed.
- `internal_trade_id == cycle_id` passed.
- Ticket identity sanity checks passed.
- Full-State AFTER population passed.
- BEFORE rows remained outcome-neutral.
- AFTER rows used only valid outcomes:
  - `SUCCESS`
  - `FAIL`
  - `SKIP`
- Failed/skipped AFTER rows had populated `execution_reason`.
- ENTRY AFTER rows used `SUCCESS` or `FAIL` only.
- No DBL_MAX / invalid ATR values were emitted.
- No denormal / uninitialized numeric values were detected.

## 8. Reconstruction Guarantee
This schema guarantees that every MM action is reconstructable using:
- Snapshot BEFORE (Full-State)
- Execution Outcome (Always Populated)
- Snapshot AFTER (Full-State)

---

## Archived Historical Versions

Historical schema versions are stored under:

`/docs/02_Specs/00_Core/_archive/`

This active SSOT file only defines the latest Snapshot schema.

Archived versions include:

- `MM_Snapshot_Schema_v1.3.md`
- `MM_Snapshot_Schema_v1.2.md`
- `MM_Snapshot_Schema_v1.1.md`

Historical content MUST NOT override this v2.1 schema.

--- 
# End of Document — MM_Snapshot_Schema v2.1
