## MM Cycle Summary Schema

### 🔒 Document Status

Version: v2.2
Status: ✅ ACTIVE (SSOT) — RUNTIME VALIDATION PASSED (v2.2) 
Last Updated: 2026-05-19 (UTC+8)  
Runtime Schema Version: v2.2

### 🎯 Purpose

Defines the authoritative schema for the Money Management Cycle Summary log.

The Cycle Summary log provides one completed-lifecycle aggregate row per broker-confirmed trade closure.

Runtime output:

- `NNFX_TradeEvents_MM_Cycle_Summary.csv`

This schema is the SSOT for:

- Cycle Summary column order
- Field names
- Field types
- Completed lifecycle aggregation rules
- Total lifecycle PnL aggregation rules across SCALE_OUT and CLOSE events
- Event CLOSE reconciliation rules
  
---

## 1. Scope

This schema covers the Cycle Summary CSV output.

Cycle Summary rows are emitted only for completed lifecycles.

A completed lifecycle is defined as a lifecycle with a broker-confirmed:

- `MM_EVENT_CLOSE`

Cycle Summary does not represent:

- failed ENTRY attempts
- skipped MM actions
- failed MM actions
- open cycles at test end

Those are represented by Snapshot and Event logs where applicable.

---

## 2. Relationship to Other Logs

The logging model uses three complementary outputs:

- Snapshot Log — records MM action attempts and outcomes
- Event Log — records confirmed lifecycle/MM events
- Cycle Summary Log — records completed lifecycle aggregates

Cycle Summary is reconciled against the completed lifecycle Event rows for the same cycle_id. Broker close evidence is reconciled against the mandatory `MM_EVENT_CLOSE` row, while lifecycle PnL is aggregated from successful realized-PnL events, including `MM_EVENT_SCALE_OUT` and `MM_EVENT_CLOSE`.

### Join Rules

- `cycle_id` groups one lifecycle.
- `internal_trade_id` currently equals `cycle_id`.
- `ticket` links to the broker ticket.
- `position_id` links to broker position identity.
- `deal_id` links to the broker-confirmed close deal.
- `position_type` provides direction context.

---

## 3. Column Order Guarantee — v2.1

All Cycle Summary logs MUST follow the exact column order below.

Missing or extra columns invalidate the log.

1. `cycle_id`
2. `internal_trade_id`
3. `trade_id`
4. `ticket`
5. `position_id`
6. `position_type`
7. `symbol`
8. `entry_time`
9. `exit_time`
10. `duration_sec`
11. `entry_price`
12. `exit_price`
13. `pnl`
14. `scale_count`
15. `trail_count`
16. `be_triggered`
17. `close_reason`
18. `close_volume`
19. `deal_id`
20. `lifecycle_status`

---

## 4. Field Definitions

### 4.1 Identity Fields

#### cycle_id

Lifecycle grouping identifier generated at ENTRY and reused until CLOSE.

#### internal_trade_id

Deterministic engine trade identity.

Current implementation rule:

```text
internal_trade_id == cycle_id
```

#### trade_id

Legacy-compatible trade identifier.

Current implementation rule:

```text
trade_id == ticket
```

#### ticket

Broker ticket associated with the lifecycle.

#### position_id

Broker position identifier.

In the current validated runtime, `position_id` matched `ticket`, but consumers MUST NOT assume this is always true across all broker/account modes.

#### position_type

Trade direction context.

Allowed values:

- `LONG`
- `SHORT`
- `NA`

Rules:

- If available, `position_type` MUST match the Event CLOSE `position_type`.
- If direction cannot be derived, `position_type` MUST be `NA`.
- Trend values such as `UpTrend` or `DownTrend` are not valid for `position_type`.

---

### 4.2 Symbol and Timing Fields

#### symbol

Trading symbol.

#### entry_time

Engine/current entry execution time for the lifecycle.

Note:

`entry_time` is not required to exactly match ENTRY Event `event_time` because ENTRY Event `event_time` may represent signal/bar context time.

#### exit_time

Broker-confirmed close event time.

Must match Event CLOSE `event_time`.

#### duration_sec

Lifecycle duration in seconds.

Rule:

```text
duration_sec = exit_time - entry_time
```

If computed duration would be negative, implementation MUST normalize to `0`.

---

### 4.3 Price and PnL Fields

#### entry_price

Entry price captured by the engine for the lifecycle.

#### exit_price

Broker-confirmed close price.

Must match Event CLOSE `close_price`.

#### pnl


Total realized lifecycle PnL for the completed cycle.

Cycle Summary pnl MUST represent the aggregate realized PnL across the full trade lifecycle, not only the final CLOSE leg.

Calculation rule:

```text
summary.pnl =
  SUM(Event.close_profit where event_type = MM_EVENT_SCALE_OUT and close_profit is broker-confirmed)
+ SUM(Event.close_profit where event_type = MM_EVENT_CLOSE)
```

---

### 4.4 Lifecycle Aggregate Fields

#### scale_count

Count of successful `MM_EVENT_SCALE_OUT` events for the cycle.

#### trail_count

Count of successful `MM_EVENT_TRAIL` events for the cycle.

#### be_triggered

Boolean indicating whether at least one successful `MM_EVENT_BE` occurred in the cycle.

#### Lifecycle aggregate relationship to pnl

scale_count, trail_count, and be_triggered summarize lifecycle behavior, but only realized-PnL events contribute to summary.pnl.

PnL-affecting lifecycle events:
- successful MM_EVENT_SCALE_OUT
- mandatory MM_EVENT_CLOSE

Non-PnL lifecycle events:
- MM_EVENT_ENTRY
- MM_EVENT_BE
- MM_EVENT_TRAIL
- MM_EVENT_EXIT

A BE or TRAIL event may influence the eventual close condition, but it does not directly contribute close_profit and must not be added to summary.pnl.

---

### 4.5 Broker Close Evidence Fields

#### close_reason

Broker-confirmed close reason.

Must match Event CLOSE `close_reason`.

Validated values include:

- `TP_HIT`
- `SL_HIT`
- `MM_EXPERT: Exit Signal`
- `UNKNOWN`

Allowed values are defined by `MM_Event_Log_Schema.md`.

#### close_volume

Total lifecycle closed volume.

Definition:
Aggregated volume closed across all lifecycle closing events.

Calculation:
```
close_volume = 
SUM(Event.close_volume where event_type = MM_EVENT_SCALE_OUT) + Event.close_volume where event_type = MM_EVENT_CLOSE
```

Rules:
- MUST include all broker-confirmed partial close volumes (MM_EVENT_SCALE_OUT).
- MUST include the final broker-confirmed close volume (MM_EVENT_CLOSE).
- MUST represent the full lifecycle executed volume.
- MUST be equal to the total opened position size for a completed lifecycle.

Note:
This field is an aggregation and no longer represents only the final CLOSE deal.

#### deal_id

Broker-confirmed close deal identifier.

Must match Event CLOSE `deal_id`.

---

### 4.6 Lifecycle Status

#### lifecycle_status

Status of the lifecycle represented by the row.

Current allowed value:

- `CLOSED`

Future allowed value may include:

- `OPEN_AT_TEST_END`

Current v2.1 runtime emits only completed lifecycle rows with:

```text
lifecycle_status = CLOSED
```

---

## 5. Emission Rules

- One Cycle Summary row MUST be emitted for each completed lifecycle.
- A completed lifecycle MUST have exactly one `MM_EVENT_CLOSE`.
- Cycle Summary MUST be emitted after broker-confirmed CLOSE evidence is available.
- No Cycle Summary row should be emitted for failed ENTRY attempts.
- No Cycle Summary row should be emitted for skipped or failed MM management attempts.
- No Cycle Summary row should be emitted for open cycles unless a future schema version introduces an explicit open-cycle status.

---

## 6. Reconciliation Rules

Cycle Summary rows MUST reconcile with the completed lifecycle Event rows for the same cycle_id.

For each completed cycle_id, broker close evidence MUST reconcile with the mandatory MM_EVENT_CLOSE row:

- summary.ticket == Event CLOSE.ticket
- summary.position_type == Event CLOSE.position_type
- summary.exit_time == Event CLOSE.event_time
- summary.exit_price == Event CLOSE.close_price
- summary.close_reason == Event CLOSE.close_reason
- summary.close_volume == Event CLOSE.close_volume
- summary.deal_id == Event CLOSE.deal_id

Lifecycle pnl MUST reconcile against realized-PnL Event rows:

```text
summary.pnl =
  SUM(Event.close_profit where event_type = MM_EVENT_SCALE_OUT)
+ SUM(Event.close_profit where event_type = MM_EVENT_CLOSE)
```

Lifecycle volume MUST reconcile against Event rows:

```text
close_volume =
SUM(Event.close_volume where event_type = MM_EVENT_SCALE_OUT)
+ Event.close_volume where event_type = MM_EVENT_CLOSE
```

---

## 7. Runtime Validation Evidence — v2.1

Runtime validation passed for the Cycle Summary log under v2.1.

Validated rules:

- 20-column schema matched exactly.
- No missing columns.
- No extra columns.
- No blank required fields.
- One Cycle Summary row existed for every Event CLOSE row.
- No extra Summary rows existed without Event CLOSE.
- `internal_trade_id == cycle_id`.
- `trade_id == ticket`.
- `position_type` matched Event CLOSE.
- `exit_time` matched Event CLOSE `event_time`.
- `exit_price` matched Event CLOSE `close_price`.
- pnl matched total realized lifecycle PnL aggregated from successful MM_EVENT_SCALE_OUT close_profit values plus the mandatory MM_EVENT_CLOSE close_profit value.
- For close-only cycles without SCALE_OUT, pnl matched Event CLOSE close_profit.
- For cycles with successful SCALE_OUT events, pnl included partial realized PnL plus final CLOSE realized PnL.
- `close_reason` matched Event CLOSE `close_reason`.
- `close_volume` matched sum of SCALE_OUT + CLOSE close_volume values.
- `deal_id` matched Event CLOSE `deal_id`.
- `scale_count` matched successful SCALE_OUT Event count.
- `trail_count` matched successful TRAIL Event count.
- `be_triggered` matched successful BE Event existence.
- `duration_sec` matched `exit_time - entry_time`.
- `lifecycle_status` was `CLOSED`.
- Open cycle `309` was correctly excluded from completed lifecycle summary output.

---

## 8. Versioning Rules

- Any Cycle Summary structural schema change requires a new schema version.
- Historical versions must be archived under:

```text
/docs/02_Specs/00_Core/_archive/
```

- This active SSOT file defines only the latest Cycle Summary schema.

---

## 9. Change Log

#### v2.2 (P5-FIX-05 — Volume Model Simplification)
- Removed total_traded_volume field from Cycle Summary schema.
- Redefined close_volume as total lifecycle closed volume.
- Updated reconciliation rules:
  - close_volume now aggregates SCALE_OUT and CLOSE event volumes.
- Removed ambiguity between final close vs lifecycle volume.
- Aligned Cycle Summary with event-driven volume model (single source of truth).
- Eliminated redundant volume representation.
- 
#### v2.1 (2026-05-12)

- Introduced 20-column Cycle Summary schema.
- Added explicit identity fields:
  - `internal_trade_id`
  - `trade_id`
  - `ticket`
  - `position_id`
  - `position_type`
- Added lifecycle timing field:
  - `duration_sec`
- Added broker close evidence fields:
  - `close_reason`
  - `close_volume`
  - `deal_id`
- Added lifecycle status field:
  - `lifecycle_status`
- Validated one Cycle Summary row per Event CLOSE.
- Validated Cycle Summary reconciliation against Event CLOSE evidence.
- Validated lifecycle aggregate fields:
  - `scale_count`
  - `trail_count`
  - `be_triggered`
- P5-FIX-03 documentation alignment:
  - Clarified Cycle Summary pnl as total realized lifecycle PnL.
  - Replaced outdated rule that pnl must equal only Event CLOSE close_profit.
  - Documented pnl aggregation rule:
    - include successful MM_EVENT_SCALE_OUT close_profit values
    - include mandatory MM_EVENT_CLOSE close_profit value
    - exclude ENTRY, BE, TRAIL, and EXIT events from pnl aggregation
  - Clarified that Event CLOSE remains the reconciliation source for broker close evidence fields:
    - exit_time
    - exit_price
    - close_reason
    - close_volume
    - deal_id
  - Clarified that Cycle Summary uses cycle_id for lifecycle aggregation and does not define `correlation_id` ownership.
  - P5-FIX-04:
    - Added total_traded_volume field to Cycle Summary schema.
    - Defined lifecycle volume aggregation rule:
      - include MM_EVENT_SCALE_OUT close_volume
      - include MM_EVENT_CLOSE close_volume
    - Clarified difference between close_volume (final CLOSE only) and total_traded_volume (lifecycle volume).

##### End of Document — MM_Cycle_Summary_Schema v2.1
