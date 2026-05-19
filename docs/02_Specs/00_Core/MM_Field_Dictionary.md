# MM Field Dictionary (SSOT)
## 🔒 Document Status
Version: v1.0  
Status: ✅ ACTIVE (SSOT)  
Last Updated: 2026-05-19 (UTC+8)    
Version Compatibility Note:
- Snapshot schema is v2.1; Event and Cycle Summary schemas are v2.2.
- This is expected: v2.2 primarily refines volume/aggregation semantics while CLOSE remains Event-only under the current runtime model.


## 🎯 Purpose
This document defines the *semantic meaning* of every field produced by the Money Management (MM) logging model.
It is the SSOT “field meaning layer” used by:
- Implementation (to populate fields correctly)
- Validation (to test correctness)
- Analytics (to interpret logs consistently)

## 🧭 Governance Rules (Non-Negotiable)
1. **Contract > Schema > Analytics interpretation.**  
   - Contract defines meaning and invariants; schemas define structure. 
2. **Field meanings must match runtime truth.**     
   Any semantic change requires:
   - Contract update (if behavior/invariants changed)
   - Schema update (if structure changed)
   - Validation gate re-pass (if meaning impacts acceptance)
3. **Volume semantics are v2.2:**  
   - Event `close_volume` is per-event executed close volume (Scale-out / Close only).
   - Cycle Summary `close_volume` is lifecycle aggregate: `SUM(scale_out close_volume) + close close_volume`.  
   - `total_traded_volume` is removed (no redundancy under monotonic lifecycle).
4. If a field exists in multiple logs (Event/Snapshot/Cycle), its meaning must remain consistent unless explicitly stated here.

## 🔗 Authoritative References (SSOT)
- Logging Contract (semantics + invariants): `MM-LOG-01_Logging_Schema_Contract.md`
- Event Schema (structure): `MM_Event_Log_Schema.md`
- Snapshot Schema (structure): `MM_Snapshot_Schema.md`
- Cycle Summary Schema (structure): `MM_Cycle_Summary_Schema.md`
- Runtime Gate: `MM-LOG-01_Runtime_Validation_Checklist.md`

---

# 1) Dictionary Format (How to Fill Entries)

Each field entry MUST include:

- **Field Name**
- **Appears In**: Event / Snapshot / Cycle Summary
- **Type**: string/int/double/bool/datetime (or MQL5 equivalent)
- **Nullable**: Yes/No + default behavior
- **Definition**: human meaning
- **Population Rule**: when/how it is set
- **Invariants / Validation Rules**
- **Analytics Notes**: how to interpret it safely
- **Examples**: 1–2 examples (optional but recommended)

Template:

## FIELD: <field_name>
- Appears In:
- Type:
- Nullable:
- Definition:
- Population Rule:
- Invariants / Validation Rules:
- Analytics Notes:
- Examples:

---

# 2) Cross-Log Meaning Rules

## 2.1 Event vs Cycle Summary Aggregation Rule
Some Event fields aggregate into Cycle Summary fields.
These MUST be explicitly defined here (not assumed in analytics).

### Known Aggregations (v2.2)
- **Cycle Summary `pnl`** = SUM(Event `close_profit` for SCALE_OUT) + Event `close_profit` for CLOSE. 
- **Cycle Summary `close_volume`** = SUM(Event `close_volume` for SCALE_OUT) + Event `close_volume` for CLOSE. 

---

# 3) Core Fields (Common / Shared)

> NOTE: Populate this section by scanning schemas and copying the exact field names.

## FIELD: correlation_id
- Appears In: Event, Snapshot
- Type: ulong
- Nullable: No
- Definition: Action-level trace identifier grouping one logical MM action/evaluation chain inside a lifecycle (cycle_id). Used to bind Event ↔ Snapshot BEFORE/AFTER for successful non-CLOSE actions.
- Population Rule:
  - Always populated for every Event row and every Snapshot row.
  - Engine-driven EXIT → CLOSE may share `correlation_id` only when CLOSE is the broker-confirmed result of that explicit EXIT intent and close_reason = `MM_EXPERT: Exit Signal`.
  - Broker-driven CLOSE must use a dedicated CLOSE `correlation_id`.
- Invariants / Validation Rules:
  - Snapshot BEFORE/AFTER pairing must be 1:1 per correlation_id.
  - Successful non-CLOSE Event rows must join to Snapshot pairs by `correlation_id`.
- Analytics Notes:
  - Use correlation_id for action-chain reconstruction; use cycle_id for lifecycle reconstruction.

## FIELD: close_volume
- Appears In: Event, Cycle Summary
- Type: double
- Nullable: Yes (Event); No (Cycle Summary)
- Definition:
  - Event: executed closed volume for that event (only SCALE_OUT and CLOSE are meaningful). 
  - Cycle Summary: total closed volume across lifecycle = SUM(scale-outs + final close). 
- Population Rule:
  - Event:
    - MM_EVENT_SCALE_OUT and MM_EVENT_CLOSE: set to executed close volume
    - All other events: default neutral (0 or empty per schema/contract) 
  - Cycle Summary:
    - `close_volume = SUM(SCALE_OUT close_volume) + CLOSE close_volume` 
- Invariants / Validation Rules:
  - Must reconcile Cycle Summary `close_volume` against sum of Event closes. 
- Analytics Notes:
  - Use for “scale-out vs final close attribution.”
- Examples:
  - Event SCALE_OUT close_volume: `0.02`
  - Cycle Summary close_volume: `0.05`

## FIELD: close_profit
- Appears In: Event (CLOSE and optionally SCALE_OUT when deal matched)
- Type: double
- Nullable: Yes (but REQUIRED for CLOSE; conditional for SCALE_OUT)
- Definition: Broker-confirmed realized PnL for that specific close/partial-close event.
- Analytics Notes:
  - Cycle Summary does not have close_profit; it has pnl (aggregate).
  - Reconcile Cycle.pnl = SUM(Event SCALE_OUT.close_profit) + Event CLOSE.close_profit.

## FIELD: pnl
- Appears In: Cycle Summary
- Type: double
- Nullable: No
- Definition: Total realized profit/loss for the cycle.
- Population Rule:
  - `pnl = SUM(SCALE_OUT close_profit) + CLOSE close_profit`. 
- Invariants / Validation Rules:
  - Must match aggregated event close profits. 
- Analytics Notes:
  - Use for expectancy, win-rate, R-multiples.

## FIELD: close_reason
- Appears In: Event (CLOSE), Cycle Summary
- Type: string/enum
- Nullable: Yes (Event for non-close events); No/Yes per schema in Cycle Summary
- Definition: Semantic reason for lifecycle termination (final close outcome).
- Population Rule:
  - Only meaningful for CLOSE outcome evidence. 
- Invariants / Validation Rules:
  - Cycle Summary close evidence must reconcile against Event CLOSE evidence. 
- Analytics Notes:
  - Use to segment outcomes by termination reason (SL/TP/manual/broker/etc.)

## FIELD: close_price
- Appears In: Event (CLOSE and optionally SCALE_OUT when deal matched)
- Type: double
- Nullable: Yes (but REQUIRED for CLOSE; conditional for SCALE_OUT)
- Definition: Broker-confirmed executed price for the close / partial-close deal.
- Population Rule:
  - REQUIRED for MM_EVENT_CLOSE.
  - Conditional for MM_EVENT_SCALE_OUT when a broker partial-close deal is matched.
  - Neutral for ENTRY/BE/TRAIL/EXIT
- Analytics Notes:
  - Cycle Summary uses exit_price (not close_price); reconcile Cycle.exit_price to Event CLOSE.close_price.

## FIELD: deal_id
- Appears In: Event (CLOSE and optionally SCALE_OUT), Cycle Summary
- Type: long
- Nullable: Yes in Event (but REQUIRED for CLOSE); No in Cycle Summary
- Definition: Broker deal identifier confirming execution evidence.
- Population Rule:
  - Event: REQUIRED for CLOSE; conditional for SCALE_OUT when deal matched; neutral otherwise.
  - Cycle Summary: must match Event CLOSE.deal_id.

---

# 4) Event Log Fields (MM_Events.csv / JSON)

> Source: `MM_Event_Log_Schema.md` (v2.2 SSOT). Column order is fixed and MUST remain 19 columns. 
## FIELD: debug_event_id
- Appears In: Event
- Type: ulong
- Nullable: No
- Definition: Monotonic debug sequence ID generated by the logger for each physical Event row. 
- Population Rule: Increment per emitted Event row; must be present for every row. 
- Invariants / Validation Rules:
  - MUST be present (non-empty) for every Event row. 
- Analytics Notes:
  - Use for debugging ordering issues only; not a lifecycle key.
- Examples:
  - `101`, `102`, `103`

## FIELD: correlation_id
- Appears In: Event
- Type: ulong
- Nullable: No
- Definition: Action-level trace identifier grouping one logical MM action/evaluation chain inside a lifecycle (`cycle_id`). 
- Population Rule:
  - MUST be populated for every Event row. 
  - For successful non-CLOSE actions, binds Event to Snapshot BEFORE/AFTER via `correlation_id`. 
  - For CLOSE: may preserve EXIT’s `correlation_id` only for engine-driven EXIT→CLOSE with `close_reason = MM_EXPERT: Exit Signal`; otherwise broker-driven closes must have a dedicated CLOSE correlation_id. 
- Invariants / Validation Rules:
  - MUST allow joining successful non-CLOSE Event rows to corresponding Snapshot rows (BEFORE/AFTER) when applicable. 
  - CLOSE correlation rule must be respected (engine-driven may share; broker-driven must be dedicated). 
- Analytics Notes:
  - Use to reconstruct sub-chains (e.g., “EXIT intent → CLOSE outcome”) inside a single cycle. 

## FIELD: event_time
- Appears In: Event
- Type: string (datetime)
- Nullable: No
- Definition: Timestamp emitted by the EA at the time the Event row is logged. 
- Population Rule: Always populate with event timestamp string (datetime). 
- Invariants / Validation Rules:
  - MUST exist for every Event row. 
- Analytics Notes:
  - Use for sequencing within and across cycles; prefer parsing as datetime in downstream tools.

## FIELD: symbol
- Appears In: Event
- Type: string
- Nullable: No
- Definition: Trade symbol (instrument) associated with the Event. 
- Population Rule: Populate from runtime chart/position context. 
- Invariants / Validation Rules:
  - MUST exist for every Event row. 
- Analytics Notes:
  - Primary dimension for grouping performance by instrument.

## FIELD: timeframe
- Appears In: Event
- Type: string (enum)
- Nullable: No
- Definition: Chart timeframe at logging time; MUST use `EnumToString` format (e.g., `PERIOD_M15`). 
- Population Rule: Emit using EnumToString output; no custom shortened labels. 
- Invariants / Validation Rules:
  - MUST be EnumToString output. 
- Analytics Notes:
  - Use for stratification by timeframe.

## FIELD: phase
- Appears In: Event
- Type: string (enum)
- Nullable: No
- Definition: Canonical MM phase string at event time (e.g., `MM_PHASE_ENTRY`, `MM_PHASE_MANAGE`, `MM_PHASE_EXIT`). 
- Population Rule: Emit canonical phase values; no custom labels. 
- Invariants / Validation Rules:
  - MUST be canonical phase strings and present for every Event row. 
- Analytics Notes:
  - Enables phase-based attribution (entry vs manage vs exit behavior).

## FIELD: event_type
- Appears In: Event
- Type: string (enum)
- Nullable: No
- Definition: Canonical event identifier representing the action/outcome being logged. 
- Allowed Values (canonical):
  - `MM_EVENT_ENTRY`
  - `MM_EVENT_SCALE_OUT`
  - `MM_EVENT_BE`
  - `MM_EVENT_TRAIL`
  - `MM_EVENT_EXIT` (intent; optional)
  - `MM_EVENT_CLOSE` (outcome; mandatory terminator) 
- Population Rule: MUST match one of the canonical values. 
- Invariants / Validation Rules:
  - Lifecycle MUST end with exactly one `MM_EVENT_CLOSE`. 
  - Lifecycle MAY contain 0..1 `MM_EVENT_EXIT`. 
- Analytics Notes:
  - Primary event classifier; use for attribution (Scale-out vs Close vs Trail, etc.).

## FIELD: cycle_id
- Appears In: Event
- Type: int
- Nullable: No
- Definition: Lifecycle grouping ID for reconstructing ENTRY → … → CLOSE. 
- Population Rule:
  - Constant across all events in the same lifecycle.
  - Increments on each ENTRY lifecycle start. 
- Invariants / Validation Rules:
  - MUST be constant within a lifecycle and increment across lifecycles. 
- Analytics Notes:
  - Primary “trade cycle” key for grouping.

## FIELD: trade_id
- Appears In: Event
- Type: long
- Nullable: No
- Definition: Internal/logging trade identifier; in current implementation aligned with broker ticket where applicable. 
- Population Rule: Always populate (use internal id strategy; current alignment with broker ticket acceptable). 
- Invariants / Validation Rules:
  - MUST exist for every row; should allow cross-log joins when combined with `ticket` and/or `cycle_id`. 
- Analytics Notes:
  - Useful join key; treat as “engine ID” even if currently equals ticket.

## FIELD: ticket
- Appears In: Event
- Type: ulong
- Nullable: No
- Definition: Broker ticket for the position/trade context. 
- Population Rule: Populate from broker position/ticket context at event time. 
- Invariants / Validation Rules:
  - MUST exist for every Event row.
  - For successful non-CLOSE actions, Event ticket MUST match Snapshot ticket. 
- Analytics Notes:
  - Join key to broker telemetry (EXEC-LOG-01) when needed.

## FIELD: position_type
- Appears In: Event
- Type: string (enum)
- Nullable: No (must be present; may be `NA`)
- Definition: Direction context of the position at event time. 
- Allowed Values:
  - `LONG`, `SHORT`, `NA` 
- Population Rule:
  - If live position is selectable at event time, MUST reflect live direction.
  - ENTRY MAY use intended direction prior to broker confirmation.
  - CLOSE MAY use last-known cached direction.
  - If direction cannot be derived, MUST be `NA`.
  - Trend labels (UpTrend/DownTrend) are invalid. 
- Invariants / Validation Rules:
  - MUST be one of LONG/SHORT/NA for every Event row. 
  - For successful non-CLOSE actions, Event position_type MUST match Snapshot position_type. 
- Analytics Notes:
  - Use for direction-based performance segmentation.

## FIELD: action_summary
- Appears In: Event
- Type: string
- Nullable: No
- Definition: Human-readable description of the action taken / evaluation outcome. 
- Population Rule: Must be populated for every Event row (even if action is “no-op/skip”, describe outcome). 
- Invariants / Validation Rules:
  - MUST exist for every row. 
- Analytics Notes:
  - Not a primary analytical field; useful for debugging and qualitative audits.

## FIELD: scale_steps
- Appears In: Event
- Type: int
- Nullable: No
- Definition: Scale-out step counter for scale-out actions; otherwise neutral. 
- Population Rule:
  - For `MM_EVENT_SCALE_OUT`: MUST be populated (step count).
  - For all other event types: MUST be `0`. 
- Invariants / Validation Rules:
  - Non-scale-out events MUST have `scale_steps = 0`. 
- Analytics Notes:
  - Enables “scale step” attribution (step 1 vs step 2 performance, etc.).

## FIELD: scale_fraction_total
- Appears In: Event
- Type: double
- Nullable: No
- Definition: Total fraction closed across scale-outs at this point; applies to SCALE_OUT events; otherwise neutral. 
- Population Rule:
  - For `MM_EVENT_SCALE_OUT`: MUST be populated.
  - For all other event types: MUST be `0.0`. 
- Invariants / Validation Rules:
  - Non-scale-out events MUST have `scale_fraction_total = 0.0`. 
- Analytics Notes:
  - Helps analyze aggressiveness of partial closes vs performance.

## FIELD: close_reason
- Appears In: Event
- Type: string (enum)
- Nullable: Yes (but REQUIRED for CLOSE; conditionally for SCALE_OUT)
- Definition: Broker-confirmed reason for closure/partial-closure event evidence. 
- Population Rule:
  - REQUIRED when `event_type = MM_EVENT_CLOSE`.
  - MAY be populated for `MM_EVENT_SCALE_OUT` when a broker partial-close deal is matched.
  - MUST be neutral (null/empty) for ENTRY / BE / TRAIL / EXIT. 
- Allowed Values (canonical list):
  - `MM_EXPERT`
  - `MM_EXPERT: Exit Signal`
  - `MM_EXPERT: Scale Out`
  - `MANUAL_DESKTOP_TERMINAL`
  - `MANUAL_MOBILE_APP`
  - `MANUAL_WEB_PLATFORM`
  - `TP_HIT`
  - `SL_HIT`
  - `STOP_OUT Event`
  - `ROLLOVER`
  - `VARIATION_MARGIN`
  - `CORPORATE_ACTION`
  - `SPLIT_ANNOUNCEMENT`
  - `UNKNOWN` 
- Invariants / Validation Rules:
  - CLOSE evidence fields must be populated for CLOSE rows. 
- Analytics Notes:
  - Primary outcome categorization (TP/SL/manual/engine exit/unknown).

## FIELD: close_price
- Appears In: Event
- Type: double
- Nullable: Yes (but REQUIRED for CLOSE; conditionally for SCALE_OUT)
- Definition: Broker-confirmed executed price for the close/partial-close deal. 
- Population Rule:
  - REQUIRED when `event_type = MM_EVENT_CLOSE`.
  - MAY be populated for `MM_EVENT_SCALE_OUT` when partial-close deal matched.
  - MUST be neutral (null/empty) for ENTRY / BE / TRAIL / EXIT. 
- Invariants / Validation Rules:
  - Must be present on CLOSE; must remain neutral on non-close evidence events. 
- Analytics Notes:
  - Use for slippage analysis and exit price attribution.

## FIELD: close_profit
- Appears In: Event
- Type: double
- Nullable: Yes (but REQUIRED for CLOSE; conditionally for SCALE_OUT)
- Definition: Broker-confirmed realized PnL for that specific close/partial-close event. 
- Population Rule:
  - REQUIRED when `event_type = MM_EVENT_CLOSE`.
  - MAY be populated for `MM_EVENT_SCALE_OUT` when partial-close deal matched.
  - MUST be neutral for ENTRY / BE / TRAIL / EXIT. 
- Invariants / Validation Rules:
  - Cycle Summary `pnl` must reconcile as SUM(scale-out close_profit) + final close close_profit. 
- Analytics Notes:
  - This is the key field for “profit by lifecycle event” attribution.

## FIELD: close_volume
- Appears In: Event
- Type: double
- Nullable: Yes (but REQUIRED > 0 for SCALE_OUT when executed, and for CLOSE)
- Definition: Executed closed volume for this specific event (event-level volume). 
- Population Rule (v2.2 semantics):
  - MUST be populated (>0) for:
    - `MM_EVENT_SCALE_OUT` (when a partial close is executed)
    - `MM_EVENT_CLOSE` (final close)
  - MUST be 0 or empty for:
    - `MM_EVENT_ENTRY`, `MM_EVENT_BE`, `MM_EVENT_TRAIL`, `MM_EVENT_EXIT`
  - MUST represent actual executed volume derived from broker-confirmed deal data. 
- Invariants / Validation Rules:
  - SUM(Event.close_volume across all events within the same cycle_id) MUST equal Cycle Summary close_volume. 
- Analytics Notes:
  - Enables “scale-out vs final close” volume attribution and consistency checks.

## FIELD: deal_id
- Appears In: Event
- Type: long
- Nullable: Yes (but REQUIRED for CLOSE; conditionally for SCALE_OUT)
- Definition: Broker deal identifier confirming the close/partial-close execution evidence. 
- Population Rule:
  - REQUIRED when `event_type = MM_EVENT_CLOSE`.
  - MAY be populated for `MM_EVENT_SCALE_OUT` when broker partial-close deal matched.
  - MUST be neutral for ENTRY / BE / TRAIL / EXIT. 
- Invariants / Validation Rules:
  - CLOSE evidence fields must be complete on CLOSE rows (includes deal_id). 
- Analytics Notes:
  - Use to reconcile against broker execution/deal history when needed.

## 4.1 Close Evidence Applicability Matrix (Event Log v2.2)

This matrix defines when the **close evidence fields** are **REQUIRED**, **CONDITIONAL**, or **NEUTRAL** per `event_type`, based on the Event Log Schema SSOT. 

### Legend
- **REQUIRED**: must be populated (non-empty) for schema compliance. 
- **CONDITIONAL**: may/must be populated only when a broker-confirmed deal match exists (e.g., partial close matched for SCALE_OUT). 
- **NEUTRAL**: must remain empty/null/0 (as applicable) because evidence is not meaningful for that event type. 

### Evidence Fields Covered
- `close_reason`, `close_price`, `close_profit`, `close_volume`, `deal_id` 

### Applicability Matrix
| Event Type | close_reason | close_price | close_profit | close_volume | deal_id |
|---|---|---|---|---|---|
| MM_EVENT_ENTRY | NEUTRAL | NEUTRAL | NEUTRAL | NEUTRAL (0/empty) | NEUTRAL |
| MM_EVENT_BE | NEUTRAL | NEUTRAL | NEUTRAL | NEUTRAL (0/empty) | NEUTRAL |
| MM_EVENT_TRAIL | NEUTRAL | NEUTRAL | NEUTRAL | NEUTRAL (0/empty) | NEUTRAL |
| MM_EVENT_EXIT (intent) | NEUTRAL | NEUTRAL | NEUTRAL | NEUTRAL (0/empty) | NEUTRAL |
| MM_EVENT_SCALE_OUT | CONDITIONAL* | CONDITIONAL* | CONDITIONAL* | REQUIRED when executed (>0)* | CONDITIONAL* |
| MM_EVENT_CLOSE (outcome) | REQUIRED | REQUIRED | REQUIRED | REQUIRED (>0) | REQUIRED |

\* **SCALE_OUT conditionality rule:** Evidence fields (`close_reason/price/profit/volume/deal_id`) are populated **only when a broker partial-close deal is matched**; otherwise they remain neutral. 

### Additional Semantic Notes (v2.2)
1. **Event close_volume is event-level executed volume** (per-event source of truth).   
2. **close_volume must be populated (>0)** for:
   - `MM_EVENT_SCALE_OUT` when a partial close is executed, and  
   - `MM_EVENT_CLOSE` for the final close.   
3. For `MM_EVENT_ENTRY/BE/TRAIL/EXIT`, `close_volume` must be **0 or empty** (neutral).   
4. **Lifecycle aggregation invariant:**  
   `SUM(Event.close_volume across all events within the same cycle_id) == Cycle Summary close_volume`.   
5. **CLOSE evidence reconciliation:** Cycle Summary close evidence must reconcile against Event CLOSE evidence fields.   

## 4.2 Neutral Default Spec (Evidence Fields)

To ensure consistent ingestion (Excel/Power BI/scripts) while remaining schema-compliant, the following **preferred neutral defaults** SHALL be used for evidence fields when they are **NEUTRAL** per the matrix above. 

#### A) CSV Neutral Defaults (preferred)
When a close evidence field is **NEUTRAL**, emit:
- `close_reason` = `""` (empty string) 
- `close_price` = `0.0` 
- `close_profit` = `0.0` 
- `close_volume` = `0.0` 
- `deal_id` = `0` 

**Rationale:**  
The schema allows evidence fields to be null/empty for non-applicable events; standardizing neutral numeric values to `0/0.0` avoids mixed “empty vs zero” parsing issues in downstream analytics. 

#### B) JSON Neutral Defaults (required keys + neutral values)
The JSON Event Object MUST include all keys matching the CSV field names.   
When a close evidence field is **NEUTRAL**, emit:
- `close_reason: null` (or empty string if your serializer cannot emit null strings consistently)
- `close_price: null`
- `close_profit: null`
- `close_volume: null`
- `deal_id: null` 

**Rationale:**  
Schema requires the keys to exist, and for non-close event types the evidence values MUST be null/empty. Using JSON `null` cleanly expresses “not applicable” without implying a numeric zero was executed. 

#### C) Applicability Overrides (non-neutral cases)
These overrides take precedence over neutral defaults:

- For `MM_EVENT_CLOSE`: all evidence fields MUST be populated (non-neutral).   
- For `MM_EVENT_SCALE_OUT`: evidence fields are populated only when a broker partial-close deal is matched; otherwise remain neutral.   
- For `close_volume` (v2.2 semantics):
  - MUST be `> 0` for `MM_EVENT_CLOSE` and for `MM_EVENT_SCALE_OUT` when partial close executed, and
  - MUST be `0 or empty` (neutral) for ENTRY/BE/TRAIL/EXIT. 

---


---

## 4.3 Event → Cycle Summary Mapping (v2.2 — FULL, 20 Fields)

This section defines how **Event rows** (`MM_Events.csv / JSON`) transform into **one Cycle Summary row per completed lifecycle**, per Cycle Summary Schema v2.2 SSOT.   

### A) Grouping & Lifecycle Completion Rule
- **Grouping key:** `cycle_id` (one Cycle Summary row per unique `cycle_id`).   
- A **completed lifecycle** MUST contain exactly one `MM_EVENT_CLOSE` (broker-confirmed terminator).   
- `MM_EVENT_EXIT` is intent-only and MAY be absent (broker-driven TP/SL/manual close).   
- Cycle Summary rows are emitted **only** for completed lifecycles (no failed entry, skipped actions, failed actions, open cycles).   

---

### B) Field-by-Field Mapping (Cycle Summary Columns in Exact Order)

> Cycle Summary column order is fixed (20 columns).   

### 1) cycle_id
- **Cycle Summary:** `cycle_id`
- **Source/Rule:** group identifier reused from ENTRY until CLOSE.   
- **Derivation:** take the group key `cycle_id`.   

### 2) internal_trade_id
- **Cycle Summary:** `internal_trade_id`
- **Source/Rule:** deterministic engine trade identity; current rule `internal_trade_id == cycle_id`.   
- **Derivation:** `internal_trade_id = cycle_id`.   

### 3) trade_id
- **Cycle Summary:** `trade_id`
- **Source/Rule:** legacy-compatible trade identifier; current rule `trade_id == ticket`.   
- **Derivation:** `trade_id = ticket` (prefer CLOSE.ticket for broker truth).   

### 4) ticket
- **Cycle Summary:** `ticket`
- **Source/Rule:** broker ticket associated with lifecycle.   
- **Derivation:** `ticket = Event(CLOSE).ticket` (preferred).   
- **Reconciliation:** `summary.ticket == Event CLOSE.ticket`.   

### 5) position_id
- **Cycle Summary:** `position_id`
- **Source/Rule:** broker position identifier; may match ticket in current runtime but must NOT be assumed across brokers/modes.   
- **Derivation (preferred):** set from broker position identity when available; otherwise use best-known position id at close time.   

### 6) position_type
- **Cycle Summary:** `position_type`
- **Source/Rule:** direction context; allowed `LONG/SHORT/NA`; must match Event CLOSE when available.   
- **Derivation:** `position_type = Event(CLOSE).position_type` (else last-known; else `NA`).   
- **Reconciliation:** `summary.position_type == Event CLOSE.position_type`.   

### 7) symbol
- **Cycle Summary:** `symbol`
- **Source/Rule:** trading symbol.   
- **Derivation (recommended):** `symbol = first non-empty symbol in cycle` (ENTRY preferred).   

### 8) entry_time
- **Cycle Summary:** `entry_time`
- **Source/Rule:** engine/current entry execution time; does not have to equal Event ENTRY event_time (Event may reflect bar/signal context).   
- **Derivation:** use engine entry execution timestamp captured for lifecycle.   

### 9) exit_time
- **Cycle Summary:** `exit_time`
- **Source/Rule:** broker-confirmed close event time; must match Event CLOSE event_time.   
- **Derivation:** `exit_time = Event(CLOSE).event_time`.   
- **Reconciliation:** `summary.exit_time == Event CLOSE.event_time`.   

### 10) duration_sec
- **Cycle Summary:** `duration_sec`
- **Source/Rule:** `duration_sec = exit_time - entry_time`; negative duration must be normalized to 0.   
- **Derivation:** `duration_sec = max(0, exit_time - entry_time)` (seconds).   

### 11) entry_price
- **Cycle Summary:** `entry_price`
- **Source/Rule:** entry price captured by the engine for the lifecycle.   
- **Derivation:** use engine-captured entry price at lifecycle start.   

### 12) exit_price
- **Cycle Summary:** `exit_price`
- **Source/Rule:** broker-confirmed close price; must match Event CLOSE close_price.   
- **Derivation:** `exit_price = Event(CLOSE).close_price`.   
- **Reconciliation:** `summary.exit_price == Event CLOSE.close_price`.   

### 13) pnl
- **Cycle Summary:** `pnl`
- **Source/Rule:** total realized lifecycle PnL (NOT final-close only).   
- **Derivation (v2.2):**
  - `pnl = SUM(Event.close_profit where event_type = MM_EVENT_SCALE_OUT) + Event(CLOSE).close_profit`   
- **Reconciliation:** must equal the above aggregation over realized-PnL events.   

### 14) scale_count
- **Cycle Summary:** `scale_count`
- **Source/Rule:** count of successful `MM_EVENT_SCALE_OUT` events.   
- **Derivation:** `scale_count = COUNT(Event rows where event_type = MM_EVENT_SCALE_OUT)` (Event log contains confirmed events).   

### 15) trail_count
- **Cycle Summary:** `trail_count`
- **Source/Rule:** count of successful `MM_EVENT_TRAIL` events.   
- **Derivation:** `trail_count = COUNT(Event rows where event_type = MM_EVENT_TRAIL)`.   

### 16) be_triggered
- **Cycle Summary:** `be_triggered`
- **Source/Rule:** boolean indicating whether at least one successful `MM_EVENT_BE` occurred.   
- **Derivation:** `be_triggered = (EXISTS Event row where event_type = MM_EVENT_BE)`   

### 17) close_reason
- **Cycle Summary:** `close_reason`
- **Source/Rule:** broker-confirmed close reason; must match Event CLOSE close_reason; allowed values governed by Event schema.   
- **Derivation:** `close_reason = Event(CLOSE).close_reason`.   
- **Reconciliation:** `summary.close_reason == Event CLOSE.close_reason`.   

### 18) close_volume
- **Cycle Summary:** `close_volume`
- **Source/Rule:** total lifecycle closed volume; aggregated across all closing events (scale-outs + final close).   
- **Derivation (v2.2):**
  - `close_volume = SUM(Event.close_volume where event_type = MM_EVENT_SCALE_OUT) + Event(CLOSE).close_volume`   
- **Reconciliation:** lifecycle volume must reconcile against Event rows using the above sum.   
- **Important note (schema text inconsistency):**
  - Section 4.5 in Cycle Summary schema shows a minus sign in the close_volume “Calculation” line, but Section 6 (Reconciliation Rules) correctly uses “+” for SCALE_OUT + CLOSE aggregation. Treat the “+” rule as authoritative and fix the minus typo in the schema to avoid confusion.   

### 19) deal_id
- **Cycle Summary:** `deal_id`
- **Source/Rule:** broker-confirmed close deal identifier; must match Event CLOSE deal_id.   
- **Derivation:** `deal_id = Event(CLOSE).deal_id`.   
- **Reconciliation:** `summary.deal_id == Event CLOSE.deal_id`.   

### 20) lifecycle_status
- **Cycle Summary:** `lifecycle_status`
- **Source/Rule:** status of lifecycle; current allowed value `CLOSED`; current runtime emits only completed lifecycles with `CLOSED`.   
- **Derivation:** set to `CLOSED` for all emitted rows under current model.   

---

### C) Mandatory Reconciliation Checklist (Cycle Summary vs Event)
For each completed `cycle_id` (exactly one CLOSE exists), the Cycle Summary row MUST reconcile as follows:   

- `summary.ticket == Event(CLOSE).ticket`   
- `summary.position_type == Event(CLOSE).position_type`   
- `summary.exit_time == Event(CLOSE).event_time`   
- `summary.exit_price == Event(CLOSE).close_price`   
- `summary.close_reason == Event(CLOSE).close_reason`   
- `summary.deal_id == Event(CLOSE).deal_id`   
- `summary.pnl == SUM(scale_out close_profit) + close close_profit`   
- `summary.close_volume == SUM(scale_out close_volume) + close close_volume`   

---

## 4.4 Snapshot ↔ Event ↔ Cycle Join & Reconstruction Rules (v2.1 Snapshot / v2.2 Event+Cycle)

This section defines how Snapshot rows bind to Event rows and how completed lifecycles reconcile into Cycle Summary.
It is the SSOT join logic for reconstruction and analytics.

### A) Keys & Their Purpose
- `cycle_id`:
  - Groups the full lifecycle: ENTRY → (SCALE_OUT/BE/TRAIL/EXIT)* → CLOSE.
- `correlation_id`:
  - Action-level trace identifier grouping one logical MM action/evaluation chain inside a `cycle_id`.
- `debug_event_id`:
  - Monotonic debug sequence for physical rows (Event rows, and Snapshot rows) — useful for ordering/debugging, not a lifecycle key.

### B) Snapshot Pairing Rule (BEFORE ↔ AFTER)
- For every MM action attempt covered by Snapshot logging, there exists a **BEFORE/AFTER pair** sharing the same `correlation_id`.
- `record_type` identifies snapshot type:
  - `MM_SNAPSHOT_BEFORE`
  - `MM_SNAPSHOT_AFTER`

### C) Event ↔ Snapshot Binding Rule (non-CLOSE)
- For successful non-CLOSE actions, the **Event row binds to the Snapshot BEFORE/AFTER pair via `correlation_id`**.
- Consistency requirements for successful non-CLOSE actions:
  - Event `event_type` MUST match Snapshot `mm_event`.
  - Event `ticket` MUST match Snapshot `ticket`.
  - Event `position_type` MUST match Snapshot `position_type`.

### D) CLOSE Handling Rule (Event-only)
- Under the current validated Snapshot runtime model:
  - `MM_EVENT_CLOSE` is **Event-only broker-confirmed lifecycle terminator**
  - CLOSE does **NOT** require Snapshot BEFORE/AFTER pairs.
- CLOSE evidence is recorded in Event log fields:
  - `close_reason`, `close_price`, `close_profit`, `close_volume`, `deal_id`.
- Completed lifecycle aggregation is recorded in Cycle Summary (one row per CLOSE).

### E) Cycle Summary Reconciliation Rule (completed lifecycle)
For each completed `cycle_id`, Cycle Summary must reconcile to Events:
- `summary.exit_time == Event(CLOSE).event_time`
- `summary.exit_price == Event(CLOSE).close_price`
- `summary.close_reason == Event(CLOSE).close_reason`
- `summary.deal_id == Event(CLOSE).deal_id`
- `summary.pnl == SUM(scale_out close_profit) + close close_profit`
- `summary.close_volume == SUM(scale_out close_volume) + close close_volume`

---

# 5) Snapshot Fields (MM_Snapshots.csv / JSON) — v2.1 (36 columns, Full-State)

> Source: `MM_Snapshot_Schema.md` (v2.1 SSOT). Snapshot logs are FULL-STATE for BOTH BEFORE and AFTER; numeric N/A = 0 and string N/A = "".

## FIELD: debug_event_id
- Appears In: Snapshot
- Type: ulong
- Nullable: No
- Definition: Monotonic debug sequence ID generated by the logger for each Snapshot row.
- Population Rule: Must be populated for every Snapshot row (BEFORE and AFTER).
- Invariants / Validation Rules:
  - Must exist for all rows; used for debugging ordering.
- Analytics Notes: Use for debugging only; not a lifecycle key.

## FIELD: correlation_id
- Appears In: Snapshot
- Type: ulong
- Nullable: No
- Definition: Action-level trace identifier that binds Snapshot BEFORE ↔ Snapshot AFTER and binds to the corresponding non-CLOSE Event row for the same MM action.
- Population Rule:
  - Same value must be used for the BEFORE/AFTER pair of the same MM action attempt.
- Invariants / Validation Rules:
  - BEFORE/AFTER pairing by correlation_id must pass runtime validation.
- Analytics Notes:
  - Primary key for reconstructing a single MM attempt (before state → outcome → after state).

## FIELD: cycle_id
- Appears In: Snapshot
- Type: int
- Nullable: No
- Definition: Lifecycle grouping ID shared across logs for a single trade lifecycle.
- Population Rule: Generated at ENTRY and reused until CLOSE.
- Invariants / Validation Rules:
  - Must be constant across snapshots in the same lifecycle.
- Analytics Notes:
  - Primary key for grouping actions by lifecycle.

## FIELD: internal_trade_id
- Appears In: Snapshot
- Type: long
- Nullable: No
- Definition: Deterministic engine trade identity; current implementation rule: `internal_trade_id == cycle_id`.
- Population Rule: Set equal to cycle_id in current validated runtime.
- Invariants / Validation Rules:
  - internal_trade_id == cycle_id must pass runtime validation.
- Analytics Notes:
  - Treat as engine-level stable ID; future-proof against multi-ticket lifecycles.

## FIELD: ticket
- Appears In: Snapshot
- Type: ulong
- Nullable: No
- Definition: Broker ticket for the position; may be 0 pre-entry depending on lifecycle stage.
- Population Rule: Populate from broker position context; 0 allowed when not yet available (e.g., pre-entry).
- Invariants / Validation Rules:
  - Ticket identity sanity checks must pass runtime validation.
- Analytics Notes:
  - Join key to Event/Cycle (when available) and broker telemetry logs.

## FIELD: position_id
- Appears In: Snapshot
- Type: long
- Nullable: No
- Definition: Broker position identifier (`POSITION_IDENTIFIER`), intended to remain stable across deals; important for netting/hedging modes.
- Population Rule: Populate from broker position identity when available; 0 allowed when not applicable/available under N/A rules.
- Invariants / Validation Rules:
  - Must be present (may be 0 under stable N/A rules).
- Analytics Notes:
  - Prefer for position-level joins when brokers reuse/change tickets.

## FIELD: position_type
- Appears In: Snapshot
- Type: string (enum)
- Nullable: No (but may be NA)
- Definition: Direction context at snapshot time. Allowed values: LONG, SHORT, NA.
- Population Rule:
  - If live position selectable: must reflect live direction.
  - If not selectable: may use last-known cached direction.
  - If unknown: NA.
  - Trend labels (UpTrend/DownTrend) are invalid.
- Invariants / Validation Rules:
  - Must be one of LONG/SHORT/NA; validated.
- Analytics Notes:
  - Use to segment behavior and outcomes by direction.

## FIELD: timestamp
- Appears In: Snapshot
- Type: string (datetime)
- Nullable: No
- Definition: Snapshot timestamp representing when the BEFORE/AFTER record was emitted.
- Population Rule: Always populate for both BEFORE and AFTER.
- Invariants / Validation Rules:
  - Must exist for every row; used in sequencing and duration reasoning.
- Analytics Notes:
  - Parse as datetime; useful for action timing and sequencing.

## FIELD: symbol
- Appears In: Snapshot
- Type: string
- Nullable: No
- Definition: Trading symbol for the snapshot context.
- Population Rule: Populate from runtime chart/position context.
- Invariants / Validation Rules: Must exist.
- Analytics Notes: Dimension for filtering and grouping.

## FIELD: timeframe
- Appears In: Snapshot
- Type: string (enum)
- Nullable: No
- Definition: Chart timeframe; should use EnumToString output (e.g., PERIOD_M15).
- Population Rule: Populate using EnumToString-style values.
- Invariants / Validation Rules:
  - Must be consistently formatted for joins/analytics.
- Analytics Notes: Useful for stratification.

## FIELD: record_type
- Appears In: Snapshot
- Type: string (enum)
- Nullable: No
- Definition: Snapshot type discriminator: BEFORE vs AFTER. Allowed values:
  - MM_SNAPSHOT_BEFORE
  - MM_SNAPSHOT_AFTER
- Population Rule: Must be set correctly for each row.
- Invariants / Validation Rules:
  - BEFORE/AFTER pairing enforced; must be correct.
- Analytics Notes:
  - Use to reconstruct action attempts and to validate outcome neutrality rules.

## FIELD: mm_phase
- Appears In: Snapshot
- Type: string (enum)
- Nullable: No
- Definition: Canonical MM phase at snapshot time (entry/manage/exit phase classification).
- Population Rule: Populate from engine phase model.
- Invariants / Validation Rules: Must be present.
- Analytics Notes: Phase-based behavior attribution.

## FIELD: mm_event
- Appears In: Snapshot
- Type: string (enum)
- Nullable: No
- Definition: Canonical MM event being attempted/logged (ENTRY/SCALE_OUT/BE/TRAIL/EXIT). CLOSE is Event-only in current runtime model.
- Population Rule: Must match the MM action being evaluated/executed for that Snapshot pair.
- Invariants / Validation Rules:
  - For successful non-CLOSE actions, Event.event_type must match Snapshot.mm_event.
- Analytics Notes:
  - Use as the action classifier for Snapshot-based reconstruction.

## FIELD: balance
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Account balance at snapshot time (FULL-STATE).
- Population Rule: Always populate for BEFORE and AFTER (no blanks).
- Invariants / Validation Rules:
  - Numeric N/A must be 0; full-state must not contain blanks.
- Analytics Notes: Use for equity curve sanity checks and exposure context.

## FIELD: equity
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Account equity at snapshot time (FULL-STATE).
- Population Rule: Always populate (FULL-STATE).
- Invariants / Validation Rules: No blanks; numeric N/A = 0.
- Analytics Notes: Use for drawdown and risk tracking.

## FIELD: free_margin
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Free margin at snapshot time (FULL-STATE).
- Population Rule: Always populate (FULL-STATE).
- Invariants / Validation Rules: No blanks; numeric N/A = 0.
- Analytics Notes: Useful for margin pressure analysis.

## FIELD: current_position_lots
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Live position size (lots) at time of snapshot.
- Population Rule: Populate from live position context; 0 if no open position.
- Invariants / Validation Rules:
  - Must reflect actual live position size at snapshot time.
- Analytics Notes:
  - Use to validate monotonic decreasing size after entry and to contextualize actions.

## FIELD: current_risk_exposure
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Current risk exposure value tracked by engine; remains anchored to ENTRY risk and does not change during BE/TRAIL/SCALE_OUT under current design.
- Population Rule: Populate consistently per engine’s risk exposure model; 0 when not applicable (stable N/A).
- Invariants / Validation Rules:
  - Must follow the engine’s anchored-to-entry rule in current implementation.
- Analytics Notes:
  - Used for risk utilization and behavior attribution.

## FIELD: current_price
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Current market price at snapshot time (market context, full-state).
- Population Rule: Populate from market data source used by engine.
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Useful for state reconstruction and context checks.

## FIELD: atr_value
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Current ATR value used for MM calculations (market context, full-state).
- Population Rule: Populate with valid ATR; must not emit DBL_MAX or invalid sentinel values.
- Invariants / Validation Rules:
  - ATR sanitation validated: no DBL_MAX/invalid sentinels.
- Analytics Notes: Important for scale-out and risk geometry analytics.

## FIELD: take_profit
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Current take-profit level/state tracked at snapshot time (execution state, full-state).
- Population Rule: Always populate (0 if not applicable).
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Use to understand lifecycle state decisions.

## FIELD: floating_pnl
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Floating (unrealized) PnL at snapshot time (execution state, full-state).
- Population Rule: Populate from broker/engine PnL context (0 if N/A).
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Useful for decision context reconstruction.

## FIELD: realized_pnl
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Realized PnL tracked at snapshot time (execution state, full-state).
- Population Rule: Populate from engine’s realized PnL tracking (0 if N/A).
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Use for progression checks and reconciliation context.

## FIELD: stoploss_points
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Stoploss distance/geometry expressed in points at snapshot time (risk geometry, full-state).
- Population Rule: Populate from engine SL geometry; 0 if not applicable.
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Used for risk sizing and SL adjustment analysis.

## FIELD: value_per_point
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Monetary value per point used for risk/position sizing geometry at snapshot time.
- Population Rule: Populate consistently (0 if N/A).
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Useful for risk normalization and consistency checks.

## FIELD: risk_model
- Appears In: Snapshot
- Type: string
- Nullable: No
- Definition: Risk model identifier actually used by the engine for this lifecycle/action (MM input used).
- Population Rule: Always populate; if not applicable, empty string ("") per stable N/A rules.
- Invariants / Validation Rules: String N/A must be "" (except controlled enum-like fields).
- Analytics Notes: Dimension for comparing risk models and outcomes.

## FIELD: risk_value
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Risk value input actually used (e.g., percentage or fixed amount value depending on model).
- Population Rule: Always populate (0 if N/A).
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Helps normalize results by risk settings.

## FIELD: risk_amount_used
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Computed risk amount actually used by engine for sizing/exposure.
- Population Rule: Always populate (0 if N/A).
- Invariants / Validation Rules: Numeric N/A = 0; no blanks.
- Analytics Notes: Use to track real risk utilization vs intended.

## FIELD: scale_atr_multiple
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Scale-out context: ATR multiple used/considered for scale-out decisions.
- Population Rule:
  - Applies to SCALE_OUT events; must be 0 for non-SCALE_OUT events.
- Invariants / Validation Rules:
  - Scale context fields must be 0 for non-SCALE_OUT events.
- Analytics Notes: Useful for scale-out threshold attribution.

## FIELD: scale_fraction
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Scale-out context: fraction considered/used for partial close sizing.
- Population Rule:
  - Applies to SCALE_OUT; must be 0 for non-SCALE_OUT events.
- Invariants / Validation Rules:
  - Must be 0 for non-SCALE_OUT events.
- Analytics Notes: Enables partial close aggressiveness analytics.

## FIELD: action_executed
- Appears In: Snapshot
- Type: bool
- Nullable: No
- Definition: Indicates whether the MM action was actually executed (Outcome field).
- Population Rule:
  - BEFORE must be neutral: false.
  - AFTER must be true/false reflecting execution.
- Invariants / Validation Rules:
  - action_executed must be true or false; validated.
  - BEFORE outcome neutrality must hold.
- Analytics Notes:
  - Use for success/failure rates and action attempt auditing.

## FIELD: execution_reason
- Appears In: Snapshot
- Type: string
- Nullable: No
- Definition: Human-readable reason explaining why an action was executed or not (Outcome field).
- Population Rule:
  - BEFORE must be neutral: "".
  - AFTER must be populated when action_executed = false.
- Invariants / Validation Rules:
  - Failed/skipped AFTER rows must include execution_reason; validated.
- Analytics Notes:
  - Critical for understanding “why not executed” (filters, constraints, guards).

## FIELD: previous_stoploss
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Stoploss value before a BE/TRAIL adjustment (Outcome field).
- Population Rule:
  - BEFORE neutral: 0.
  - AFTER:
    - For BE/TRAIL: set previous SL.
    - For non-BE/TRAIL: must remain 0.
- Invariants / Validation Rules:
  - Must be 0 for non-BE/TRAIL events.
- Analytics Notes:
  - Enables measurement of stoploss movement magnitude and frequency.

## FIELD: new_stoploss
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Stoploss value after a BE/TRAIL adjustment (Outcome field).
- Population Rule:
  - BEFORE neutral: 0.
  - AFTER:
    - For BE/TRAIL: set new SL.
    - For non-BE/TRAIL: must remain 0.
- Invariants / Validation Rules:
  - Must be 0 for non-BE/TRAIL events.
- Analytics Notes:
  - Used to evaluate trailing logic effectiveness and BE behavior.

## FIELD: closed_lots
- Appears In: Snapshot
- Type: double
- Nullable: No
- Definition: Closed lots for SCALE_OUT actions (Outcome field).
- Population Rule:
  - BEFORE neutral: 0.
  - AFTER:
    - For SCALE_OUT: set closed lots.
    - For non-SCALE_OUT: must remain 0.
- Invariants / Validation Rules:
  - closed_lots must be 0 for non-SCALE_OUT events.
- Analytics Notes:
  - Used for scale-out sizing attribution and reconciliation with Event close_volume (conceptually related but not identical fields).
  - closed_lots (Snapshot) is an engine attempt/outcome perspective, while close_volume (Event) is broker-confirmed executed volume.

## FIELD: event_outcome
- Appears In: Snapshot
- Type: string (enum)
- Nullable: No
- Definition: Outcome classification of the MM attempt (Outcome field). AFTER must be one of: SUCCESS, FAIL, SKIP.
- Population Rule:
  - BEFORE neutral: "".
  - AFTER must be one of:
    - SUCCESS
    - FAIL
    - SKIP
  - ENTRY AFTER must be SUCCESS or FAIL only (not SKIP).
- Invariants / Validation Rules:
  - Valid outcomes only; validated.
  - BEFORE outcome neutrality must hold.
- Analytics Notes:
  - Primary field for action success/failure/skip metrics.

---

## 5.1 Snapshot Evidence Matrix (v2.1 — FULL-STATE + Applicability Rules)

This matrix defines when Snapshot fields are **REQUIRED**, **CONDITIONAL**, or **NEUTRAL** based on:
- `record_type` (BEFORE vs AFTER), and
- `mm_event` (ENTRY / SCALE_OUT / BE / TRAIL / EXIT)

Snapshot logs are FULL-STATE:
- numeric N/A MUST be `0`
- string N/A MUST be `""`
No blanks-as-missing are allowed.

### Legend
- **REQUIRED**: must be populated with meaningful value
- **CONDITIONAL**: populated only if the attempt/action is applicable/executed; otherwise neutral sentinel
- **NEUTRAL**: must be stable sentinel (numeric `0`, string `""`, bool `false`)
- **CONTROLLED**: must be one of allowed enum values

---

## A) Outcome Evidence by record_type (BEFORE vs AFTER)

Outcome fields:
- `action_executed` (bool)
- `execution_reason` (string)
- `previous_stoploss` (double)
- `new_stoploss` (double)
- `closed_lots` (double)
- `event_outcome` (string enum)

### A.1 Record-Type Applicability
| record_type | action_executed | execution_reason | previous_stoploss | new_stoploss | closed_lots | event_outcome |
|---|---|---|---|---|---|---|
| MM_SNAPSHOT_BEFORE | NEUTRAL (`false`) | NEUTRAL (`""`) | NEUTRAL (`0`) | NEUTRAL (`0`) | NEUTRAL (`0`) | NEUTRAL (`""`) |
| MM_SNAPSHOT_AFTER | REQUIRED | CONDITIONAL* | CONDITIONAL** | CONDITIONAL** | CONDITIONAL*** | CONTROLLED |

\* `execution_reason` MUST be populated when `action_executed = false`.  
\** `previous_stoploss` and `new_stoploss` apply only to BE/TRAIL; otherwise MUST be `0`.  
\*** `closed_lots` applies only to SCALE_OUT; otherwise MUST be `0`.  

### A.2 Controlled Values
- AFTER `event_outcome` MUST be one of: `SUCCESS`, `FAIL`, `SKIP`.  
- ENTRY AFTER MUST be only: `SUCCESS` or `FAIL` (not `SKIP`).  

---

## B) Event-Specific Evidence Fields by mm_event (applies to BOTH BEFORE and AFTER)

These fields are FULL-STATE but only meaningful for specific `mm_event` types.

### B.1 Scale Context (only for SCALE_OUT)
Fields:
- `scale_atr_multiple`
- `scale_fraction`

| mm_event | scale_atr_multiple | scale_fraction |
|---|---|---|
| MM_EVENT_ENTRY | NEUTRAL (`0`) | NEUTRAL (`0`) |
| MM_EVENT_SCALE_OUT | REQUIRED (meaningful) | REQUIRED (meaningful) |
| MM_EVENT_BE | NEUTRAL (`0`) | NEUTRAL (`0`) |
| MM_EVENT_TRAIL | NEUTRAL (`0`) | NEUTRAL (`0`) |
| MM_EVENT_EXIT | NEUTRAL (`0`) | NEUTRAL (`0`) |

Rule: Scale context fields MUST be `0` for non-SCALE_OUT events.  

### B.2 Stoploss Adjustment Evidence (only for BE / TRAIL)
Fields:
- `previous_stoploss`
- `new_stoploss`

| mm_event | previous_stoploss | new_stoploss |
|---|---|---|
| MM_EVENT_ENTRY | NEUTRAL (`0`) | NEUTRAL (`0`) |
| MM_EVENT_SCALE_OUT | NEUTRAL (`0`) | NEUTRAL (`0`) |
| MM_EVENT_BE | REQUIRED (meaningful) | REQUIRED (meaningful) |
| MM_EVENT_TRAIL | REQUIRED (meaningful) | REQUIRED (meaningful) |
| MM_EVENT_EXIT | NEUTRAL (`0`) | NEUTRAL (`0`) |

Rule: `previous_stoploss` and `new_stoploss` MUST be `0` for non-BE/TRAIL events.  

### B.3 Partial Close Evidence (only for SCALE_OUT)
Field:
- `closed_lots`

| mm_event | closed_lots |
|---|---|
| MM_EVENT_ENTRY | NEUTRAL (`0`) |
| MM_EVENT_SCALE_OUT | REQUIRED (meaningful) |
| MM_EVENT_BE | NEUTRAL (`0`) |
| MM_EVENT_TRAIL | NEUTRAL (`0`) |
| MM_EVENT_EXIT | NEUTRAL (`0`) |

Rule: `closed_lots` MUST be `0` for non-SCALE_OUT events.  

---

## C) Full-State Enforcement (all fields)
- BEFORE and AFTER snapshots MUST populate the full core state set (no blanks-as-missing).  
- Numeric N/A MUST be `0`; String N/A MUST be `""` (empty string).  
- ATR values MUST NOT emit DBL_MAX or invalid sentinel values.  

---

## D) CLOSE Handling (important exclusion)
- `MM_EVENT_CLOSE` is currently Event-only broker-confirmed terminator and does not require Snapshot BEFORE/AFTER pairs under v2.1 runtime model.  

---

## 5.2 Snapshot ↔ Event ↔ Cycle Join Applicability Matrix (v2.1 Snapshot / v2.2 Event+Cycle)

This matrix specifies which MM lifecycle actions are expected to produce:
- Snapshot BEFORE/AFTER pairs,
- Event rows, and
- Cycle Summary rows,
and when joins are REQUIRED vs OPTIONAL vs NOT APPLICABLE.

### Legend
- **REQUIRED**: must exist for schema/runtime compliance
- **OPTIONAL**: may exist depending on runtime behavior / broker-driven outcomes
- **CONDITIONAL**: must exist only if the action was successfully executed/confirmed
- **N/A**: not expected by design under the current runtime model

### Join Keys
- Snapshot ↔ Snapshot: `correlation_id` pairs BEFORE/AFTER  
- Event ↔ Snapshot: `correlation_id` binds successful non-CLOSE Event rows to Snapshot pairs  
- Cycle Summary ↔ Event: `cycle_id` groups lifecycle; Cycle Summary reconciles against Event CLOSE and aggregated Event rows  

---

### A) Applicability Matrix (by lifecycle action)

| Lifecycle action (semantic) | Snapshot BEFORE/AFTER pair | Event row | Event ↔ Snapshot join by correlation_id | Cycle Summary row |
|---|---|---|---|---|
| MM_EVENT_ENTRY | REQUIRED | CONDITIONAL* | CONDITIONAL* | N/A |
| MM_EVENT_SCALE_OUT | REQUIRED | CONDITIONAL* | CONDITIONAL* | N/A |
| MM_EVENT_BE | REQUIRED | CONDITIONAL* | CONDITIONAL* | N/A |
| MM_EVENT_TRAIL | REQUIRED | CONDITIONAL* | CONDITIONAL* | N/A |
| MM_EVENT_EXIT (intent) | REQUIRED | OPTIONAL** | OPTIONAL / CONDITIONAL*** | N/A |
| MM_EVENT_CLOSE (outcome) | N/A | REQUIRED (exactly 1 per completed cycle) | N/A | REQUIRED (exactly 1 per completed cycle) |

\* **CONDITIONAL (successful non-CLOSE actions):**  
Event rows exist only for confirmed lifecycle/MM events; when a non-CLOSE action succeeds, the Event row MUST join to the Snapshot BEFORE/AFTER pair via `correlation_id`.  

\** **EXIT is optional:**  
A lifecycle MAY contain 0..1 `MM_EVENT_EXIT` rows because EXIT is intent-only and may be absent in broker-driven closes (TP/SL/manual).  

\*** **EXIT join nuance:**  
If an EXIT is logged as a successful non-CLOSE action, it can join to Snapshot by correlation_id like other actions.  
Additionally, engine-driven EXIT → CLOSE may share correlation_id only when CLOSE is the broker-confirmed result of that explicit EXIT intent and `close_reason = MM_EXPERT: Exit Signal`.  

---

### B) Required Existence Rules (Hard Assertions)

1. **Snapshot pairing rule:**  
For Snapshot-covered actions (ENTRY/SCALE_OUT/BE/TRAIL/EXIT), Snapshot MUST produce a BEFORE/AFTER pair sharing the same `correlation_id`.  

2. **CLOSE is Event-only rule:**  
`MM_EVENT_CLOSE` does not require Snapshot BEFORE/AFTER pairs under the current v2.1 runtime model.  

3. **Completed cycle termination rule:**  
Each completed lifecycle MUST have exactly one `MM_EVENT_CLOSE` row.  

4. **Cycle Summary emission rule:**  
One Cycle Summary row MUST be emitted for each completed lifecycle (i.e., each Event CLOSE), and no Summary rows should exist without Event CLOSE.  

---

### C) Practical Analytics Checks Enabled by This Matrix

- **Missing Snapshot pair detection:**  
For each correlation_id, exactly 1 BEFORE + 1 AFTER must exist (for Snapshot-covered actions).  

- **Missing Event join detection (non-CLOSE success):**  
If Snapshot AFTER indicates success for an action (event_outcome=SUCCESS and action_executed=true), then an Event row with matching correlation_id is expected for that action chain (non-CLOSE).  

- **Close completeness detection:**  
For each cycle_id in Cycle Summary, there must be exactly 1 Event CLOSE row.  

---

## 5.3 Join Failure Taxonomy (Cross-Log Data Quality)

This taxonomy standardizes how to classify and report join/reconciliation failures across:
- Snapshot (BEFORE/AFTER),
- Event (confirmed actions + CLOSE evidence),
- Cycle Summary (completed lifecycle aggregates).

Each failure type includes:
- **Symptom**: what is observed in logs
- **Detection Rule**: how analytics/validators detect it
- **Severity**: INFO / WARN / ERROR / FATAL
- **Likely Cause**: common root causes
- **Recommended Action**: what to fix or verify

### Legend (Severity)
- **INFO**: expected edge-case or non-blocking anomaly (track only)
- **WARN**: suspicious but may be explainable (investigate)
- **ERROR**: violates expected behavior; analytics results may be wrong
- **FATAL**: violates SSOT invariants; runtime validation should fail

---

## A) Snapshot Pairing Failures (correlation_id)

### JF-SNAP-01 — Missing AFTER Snapshot
- Symptom: Snapshot has BEFORE but no corresponding AFTER for same `correlation_id`.
- Detection Rule: For each `correlation_id`, count(record_type=BEFORE)=1 and count(record_type=AFTER)=0.
- Severity: **FATAL**
- Likely Cause: logger emission failure, early return/exception between BEFORE and AFTER, or write failure.
- Recommended Action: fix Snapshot emission to guarantee AFTER is always written after attempt completion.

### JF-SNAP-02 — Missing BEFORE Snapshot
- Symptom: Snapshot has AFTER but no corresponding BEFORE for same `correlation_id`.
- Detection Rule: For each `correlation_id`, count(AFTER)=1 and count(BEFORE)=0.
- Severity: **FATAL**
- Likely Cause: incorrect call order or missing BEFORE hook.
- Recommended Action: enforce BEFORE emission prior to MM attempt.

### JF-SNAP-03 — Duplicate BEFORE or AFTER
- Symptom: More than one BEFORE or more than one AFTER for the same `correlation_id`.
- Detection Rule: For each `correlation_id`, count(BEFORE) != 1 OR count(AFTER) != 1.
- Severity: **ERROR**
- Likely Cause: duplicate logging calls, retries without dedupe, or correlation_id reuse bug.
- Recommended Action: ensure correlation_id uniqueness per MM attempt and single emission per record_type.

### JF-SNAP-04 — Outcome Fields Not Neutral in BEFORE
- Symptom: BEFORE snapshot contains non-neutral values in outcome fields (e.g., action_executed=true, non-empty execution_reason).
- Detection Rule: For record_type=BEFORE enforce:
  - action_executed=false, execution_reason="", previous_stoploss=0, new_stoploss=0, closed_lots=0, event_outcome="".
- Severity: **ERROR**
- Likely Cause: incorrect reuse of state buffer, not resetting outcome fields.
- Recommended Action: explicitly set neutral sentinels for BEFORE rows.

### JF-SNAP-05 — AFTER Outcome Invalid / Missing Reason
- Symptom: AFTER snapshot has invalid `event_outcome` or missing `execution_reason` when action_executed=false.
- Detection Rule:
  - record_type=AFTER: event_outcome ∈ {SUCCESS, FAIL, SKIP}
  - if action_executed=false then execution_reason != ""
- Severity: **ERROR**
- Likely Cause: outcome classification bug or missing reason propagation.
- Recommended Action: enforce strict outcome rules for AFTER rows.

---

## B) Event ↔ Snapshot Join Failures (correlation_id)

> Rule basis: For successful non-CLOSE actions, Event rows bind to Snapshot BEFORE/AFTER via `correlation_id`; CLOSE is Event-only and does not require Snapshot pairing.

### JF-JOIN-01 — Snapshot Success but Missing Event Row (non-CLOSE)
- Symptom: Snapshot AFTER indicates SUCCESS (and/or action_executed=true) but there is no matching Event row for same `correlation_id` (excluding CLOSE).
- Detection Rule:
  - For each Snapshot AFTER where event_outcome=SUCCESS:
    - expect exactly one Event row with same correlation_id and matching event_type == mm_event (non-CLOSE).
- Severity: **ERROR**
- Likely Cause: Event emission omitted for successful action, or correlation_id mismatch between modules.
- Recommended Action: ensure successful non-CLOSE actions emit an Event row using the same correlation_id.

### JF-JOIN-02 — Event Row Exists but Missing Snapshot Pair (non-CLOSE)
- Symptom: Event row exists (non-CLOSE) but no Snapshot BEFORE/AFTER pair exists for same `correlation_id`.
- Detection Rule: For each Event row where event_type != MM_EVENT_CLOSE:
  - require Snapshot BEFORE and AFTER rows for correlation_id.
- Severity: **FATAL** (breaks reconstruction guarantee)
- Likely Cause: Snapshot logging not triggered for that action type or correlation_id mismatch.
- Recommended Action: ensure Snapshot pair creation is mandatory for Snapshot-covered actions.

### JF-JOIN-03 — Event Type Mismatch vs Snapshot mm_event
- Symptom: Event.event_type does not match Snapshot.mm_event for same correlation_id (non-CLOSE actions).
- Detection Rule: For joined rows:
  - enforce Event.event_type == Snapshot.mm_event (successful non-CLOSE actions).
- Severity: **ERROR**
- Likely Cause: incorrect enum mapping or action classification bug.
- Recommended Action: fix canonical event naming alignment between modules.

### JF-JOIN-04 — Ticket / Position Type Mismatch (Event vs Snapshot)
- Symptom: Event.ticket or Event.position_type differs from Snapshot.ticket or Snapshot.position_type for same correlation_id (non-CLOSE successful actions).
- Detection Rule: For successful non-CLOSE joins:
  - Event.ticket == Snapshot.ticket
  - Event.position_type == Snapshot.position_type
- Severity: **ERROR**
- Likely Cause: stale cached ticket/direction, wrong position context selection.
- Recommended Action: ensure both logs source identity fields from the same live position context at action time.

### JF-JOIN-05 — Unexpected CLOSE Snapshot Rows
- Symptom: Snapshot rows exist where mm_event == MM_EVENT_CLOSE (under current runtime model).
- Detection Rule: Under v2.1 Snapshot model:
  - mm_event should be one of ENTRY/SCALE_OUT/BE/TRAIL/EXIT; CLOSE should not have Snapshot pairs.
- Severity: **WARN** (or ERROR if it breaks downstream joins)
- Likely Cause: accidental logging of CLOSE through snapshot pipeline.
- Recommended Action: enforce CLOSE as Event-only in current model, unless schema version explicitly changes.

---

## C) Cycle Summary ↔ Event (cycle_id) Reconciliation Failures

> Rule basis: One Cycle Summary row per completed lifecycle; completed lifecycle requires exactly one Event CLOSE; Cycle Summary reconciles to Event CLOSE evidence and aggregated SCALE_OUT + CLOSE PnL/volume.

### JF-CYCLE-01 — Cycle Summary Row Without Event CLOSE
- Symptom: Cycle Summary has cycle_id but no matching Event CLOSE for that cycle_id.
- Detection Rule:
  - For each Cycle Summary cycle_id: count(Event where event_type=CLOSE) must be exactly 1.
- Severity: **FATAL**
- Likely Cause: summary emitted prematurely or CLOSE detection failed.
- Recommended Action: enforce emission only after broker-confirmed CLOSE is observed.

### JF-CYCLE-02 — Event CLOSE Without Cycle Summary Row
- Symptom: Event CLOSE exists but no corresponding Cycle Summary row for that cycle_id.
- Detection Rule:
  - For each Event CLOSE cycle_id: exactly 1 Cycle Summary row must exist.
- Severity: **FATAL**
- Likely Cause: Cycle Summary emission skipped or write failure.
- Recommended Action: ensure 1:1 CLOSE→Summary emission rule.

### JF-CYCLE-03 — Duplicate Event CLOSE Within One cycle_id
- Symptom: More than one Event CLOSE for the same cycle_id.
- Detection Rule: For each cycle_id: count(Event CLOSE) must equal 1.
- Severity: **FATAL**
- Likely Cause: duplicate close detection, correlation mis-grouping, or lifecycle restart bug.
- Recommended Action: enforce single CLOSE terminator per lifecycle.

### JF-CYCLE-04 — CLOSE Evidence Mismatch (Summary vs Event CLOSE)
- Symptom: Cycle Summary fields do not match Event CLOSE evidence:
  - exit_time, exit_price, close_reason, deal_id, ticket, position_type.
- Detection Rule (per cycle_id):
  - summary.exit_time == Event(CLOSE).event_time
  - summary.exit_price == Event(CLOSE).close_price
  - summary.close_reason == Event(CLOSE).close_reason
  - summary.deal_id == Event(CLOSE).deal_id
  - summary.ticket == Event(CLOSE).ticket
  - summary.position_type == Event(CLOSE).position_type
- Severity: **ERROR** (can become FATAL if gate requires strict pass)
- Likely Cause: wrong source row used, stale cache, formatting/time conversion errors.
- Recommended Action: derive these fields directly from the single Event CLOSE row for the cycle.

### JF-CYCLE-05 — PnL Aggregation Mismatch (Summary.pnl)
- Symptom: Cycle Summary `pnl` does not equal aggregated realized PnL from Event SCALE_OUT + Event CLOSE close_profit.
- Detection Rule:
  - summary.pnl == SUM(Event.close_profit where event_type=SCALE_OUT) + Event(CLOSE).close_profit
- Severity: **FATAL** (Phase 5 gate reconciliation requirement)
- Likely Cause: missing partial closes, wrong filtering, mixing unrealized PnL.
- Recommended Action: compute pnl strictly from realized close_profit evidence rows only.

### JF-CYCLE-06 — Volume Aggregation Mismatch (Summary.close_volume)
- Symptom: Cycle Summary `close_volume` does not equal SUM(Event close_volume for SCALE_OUT) + Event CLOSE close_volume.
- Detection Rule:
  - summary.close_volume == SUM(Event.close_volume where event_type=SCALE_OUT) + Event(CLOSE).close_volume
- Severity: **FATAL** (Phase 5 v2.2 semantics)
- Likely Cause: using final close volume only, missing a scale-out deal match, or parsing empty vs 0 inconsistently.
- Recommended Action: treat Event close_volume as the single source of truth and aggregate.

---

## 5.4 Snapshot Stable N/A Defaults (FULL-STATE policy)

Snapshot logs follow FULL-STATE for BOTH BEFORE and AFTER:
- numeric N/A MUST be `0`
- string N/A MUST be `""` (empty string)
This prevents denormal/uninitialized numeric artifacts and ensures deterministic parsing.

Exceptions:
- Enum-like controlled fields MUST use their allowed values:
  - `position_type` ∈ {LONG, SHORT, NA}
  - `event_outcome` ∈ {SUCCESS, FAIL, SKIP} (AFTER only; BEFORE is neutral "").

---

# 6) Cycle Summary Fields (MM_Cycle_Summary.csv) — v2.2 (20 columns)

> Source: `MM_Cycle_Summary_Schema.md` (v2.2 SSOT). Cycle Summary emits **one row per completed lifecycle** (i.e., per broker-confirmed MM_EVENT_CLOSE). 

## FIELD: cycle_id
- Appears In: Cycle Summary
- Type: int 
- Nullable: No
- Definition: Lifecycle grouping identifier generated at ENTRY and reused until CLOSE. 
- Population Rule: Set to the lifecycle’s cycle_id; constant for the lifecycle. 
- Invariants / Validation Rules:
  - Must match the cycle_id of the lifecycle’s Event CLOSE row. 
- Analytics Notes: Primary lifecycle key for grouping.

## FIELD: internal_trade_id
- Appears In: Cycle Summary
- Type: long 
- Nullable: No
- Definition: Deterministic engine trade identity. Current implementation rule: `internal_trade_id == cycle_id`. 
- Population Rule: Set `internal_trade_id = cycle_id` (current validated behavior). 
- Invariants / Validation Rules:
  - Must satisfy `internal_trade_id == cycle_id` under current runtime model. 
- Analytics Notes: Treat as stable engine ID; reserved for future multi-ticket lifecycles.

## FIELD: trade_id
- Appears In: Cycle Summary
- Type: long 
- Nullable: No
- Definition: Legacy-compatible trade identifier. Current implementation rule: `trade_id == ticket`. 
- Population Rule: Set `trade_id = ticket` (current validated behavior). 
- Invariants / Validation Rules:
  - Must satisfy `trade_id == ticket` under current runtime model. 
- Analytics Notes: Use for backward compatibility; prefer cycle_id for lifecycle grouping.

## FIELD: ticket
- Appears In: Cycle Summary
- Type: ulong 
- Nullable: No
- Definition: Broker ticket associated with the lifecycle. 
- Population Rule: Derive from broker/lifecycle identity; reconcile against Event CLOSE.ticket. 
- Invariants / Validation Rules:
  - `summary.ticket == Event CLOSE.ticket`. 
- Analytics Notes: Useful for broker-side joins; do not assume it equals position_id across brokers.

## FIELD: position_id
- Appears In: Cycle Summary
- Type: long 
- Nullable: No
- Definition: Broker position identifier. Consumers MUST NOT assume `position_id == ticket` across broker/account modes. 
- Population Rule: Populate from broker position identity when available; otherwise best-known lifecycle position identity. 
- Invariants / Validation Rules:
  - Must be populated (may differ from ticket depending on broker/account mode). 
- Analytics Notes: Prefer position_id for position-level joins in netting/hedging contexts.

## FIELD: position_type
- Appears In: Cycle Summary
- Type: string (enum) 
- Nullable: No (but may be NA)
- Definition: Trade direction context. Allowed values: LONG, SHORT, NA. 
- Population Rule: If available, must match Event CLOSE.position_type; else use NA. 
- Invariants / Validation Rules:
  - `summary.position_type == Event CLOSE.position_type` when derived. 
  - Must be one of LONG/SHORT/NA. 
- Analytics Notes: Dimension for long/short performance.

## FIELD: symbol
- Appears In: Cycle Summary
- Type: string 
- Nullable: No
- Definition: Trading symbol. 
- Population Rule: Populate from lifecycle instrument context (ENTRY context preferred). 
- Invariants / Validation Rules: Must be populated. 
- Analytics Notes: Dimension for grouping by instrument.

## FIELD: entry_time
- Appears In: Cycle Summary
- Type: string (datetime) 
- Nullable: No
- Definition: Engine/current entry execution time for the lifecycle; not required to match Event ENTRY event_time exactly (Event ENTRY may reflect signal/bar context time). 
- Population Rule: Use engine entry execution timestamp captured for the lifecycle. 
- Invariants / Validation Rules:
  - Used for duration computation with exit_time. 
- Analytics Notes: Use for lifecycle timing and session filters; do not equate to signal time.

## FIELD: exit_time
- Appears In: Cycle Summary
- Type: string (datetime) 
- Nullable: No
- Definition: Broker-confirmed close event time. Must match Event CLOSE.event_time. 
- Population Rule: `exit_time = Event CLOSE.event_time`. 
- Invariants / Validation Rules:
  - `summary.exit_time == Event CLOSE.event_time`. 
- Analytics Notes: Use for close timing; primary end timestamp for lifecycle.

## FIELD: duration_sec
- Appears In: Cycle Summary
- Type: int (seconds) 
- Nullable: No
- Definition: Lifecycle duration in seconds. Rule: `duration_sec = exit_time - entry_time`. If negative, normalize to 0. 
- Population Rule: Compute `max(0, exit_time - entry_time)` in seconds. 
- Invariants / Validation Rules:
  - Must reflect the normalized time delta rule. 
- Analytics Notes: Enables hold-time analysis; clamp prevents negative artifacts.

## FIELD: entry_price
- Appears In: Cycle Summary
- Type: double 
- Nullable: No
- Definition: Entry price captured by the engine for the lifecycle. 
- Population Rule: Set from engine-captured entry execution price. 
- Invariants / Validation Rules: Must be populated. 
- Analytics Notes: Used for R-multiple and price-based analytics.

## FIELD: exit_price
- Appears In: Cycle Summary
- Type: double 
- Nullable: No
- Definition: Broker-confirmed close price. Must match Event CLOSE.close_price. 
- Population Rule: `exit_price = Event CLOSE.close_price`. 
- Invariants / Validation Rules:
  - `summary.exit_price == Event CLOSE.close_price`. 
- Analytics Notes: Use for exit price attribution and slippage studies.

## FIELD: pnl
- Appears In: Cycle Summary
- Type: double 
- Nullable: No
- Definition: Total realized lifecycle PnL for the completed cycle (not final-close only). 
- Population Rule:
  - `pnl = SUM(Event.close_profit for MM_EVENT_SCALE_OUT) + SUM(Event.close_profit for MM_EVENT_CLOSE)` (effectively scale-outs + final close). 
- Invariants / Validation Rules:
  - Must reconcile to realized-PnL Event rows for the same cycle_id. 
- Analytics Notes: Primary measure for expectancy/win-rate; always use this instead of final close_profit alone.

## FIELD: scale_count
- Appears In: Cycle Summary
- Type: int 
- Nullable: No
- Definition: Count of successful MM_EVENT_SCALE_OUT events for the cycle. 
- Population Rule: Count Event rows where event_type == MM_EVENT_SCALE_OUT for the cycle_id. 
- Invariants / Validation Rules:
  - Must match successful SCALE_OUT Event count. 
- Analytics Notes: Useful for scale-out behavior segmentation.

## FIELD: trail_count
- Appears In: Cycle Summary
- Type: int 
- Nullable: No
- Definition: Count of successful MM_EVENT_TRAIL events for the cycle. 
- Population Rule: Count Event rows where event_type == MM_EVENT_TRAIL for the cycle_id. 
- Invariants / Validation Rules:
  - Must match successful TRAIL Event count. 
- Analytics Notes: Used for trailing behavior and frequency analytics.

## FIELD: be_triggered
- Appears In: Cycle Summary
- Type: bool 
- Nullable: No
- Definition: Boolean indicating whether at least one successful MM_EVENT_BE occurred in the cycle. 
- Population Rule: True if exists Event row where event_type == MM_EVENT_BE for the cycle_id; else false. 
- Invariants / Validation Rules:
  - Must match existence of BE Event. 
- Analytics Notes: Enables outcome analysis by BE involvement.

## FIELD: close_reason
- Appears In: Cycle Summary
- Type: string (enum) 
- Nullable: No
- Definition: Broker-confirmed close reason. Must match Event CLOSE.close_reason; allowed values governed by Event schema. 
- Population Rule: `close_reason = Event CLOSE.close_reason`. 
- Invariants / Validation Rules:
  - `summary.close_reason == Event CLOSE.close_reason`. 
- Analytics Notes: Segment outcomes by TP/SL/manual/expert exit/unknown.

## FIELD: close_volume
- Appears In: Cycle Summary
- Type: double 
- Nullable: No
- Definition: Total lifecycle closed volume aggregated across all lifecycle closing events (scale-outs + final close). 
- Population Rule (v2.2):
  - `close_volume = SUM(Event.close_volume for MM_EVENT_SCALE_OUT) + Event.close_volume for MM_EVENT_CLOSE` (lifecycle total). 
- Invariants / Validation Rules:
  - Must reconcile to Event-level volume model:
    - `summary.close_volume == SUM(scale_out close_volume) + close close_volume`. 
- Analytics Notes:
  - Lifecycle executed volume; do not interpret as “final close only”.
- Note (doc consistency):
  - If any formula line elsewhere shows a conflicting operator, treat the reconciliation rule (SCALE_OUT + CLOSE) as authoritative. 

## FIELD: deal_id
- Appears In: Cycle Summary
- Type: long 
- Nullable: No
- Definition: Broker-confirmed close deal identifier. Must match Event CLOSE.deal_id. 
- Population Rule: `deal_id = Event CLOSE.deal_id`. 
- Invariants / Validation Rules:
  - `summary.deal_id == Event CLOSE.deal_id`. 
- Analytics Notes: Join key for broker deal reconciliation if needed.

## FIELD: lifecycle_status
- Appears In: Cycle Summary
- Type: string (enum) 
- Nullable: No
- Definition: Status of the lifecycle represented by the row. Current allowed value: CLOSED (v2.2 runtime emits only completed lifecycles). 
- Population Rule: Set to `CLOSED` for all emitted rows under current model. 
- Invariants / Validation Rules:
  - Must be CLOSED for all emitted rows in current runtime. 
- Analytics Notes: Future-proof field (e.g., OPEN_AT_TEST_END in later versions), but currently constant.

# 7) Versioning Notes
- This dictionary version is independent of schema versions.
- If a field meaning changes due to contract/semantic changes, bump dictionary version:
  - v1.0 → v1.1 (small clarifications)
  - v1.x → v2.0 (semantic model change)

---

# 8) Changelog
## v1.0 (2026-05-19)
- Created SSOT field dictionary skeleton.
- Encoded v2.2 semantic rules for volume and PnL aggregation. 