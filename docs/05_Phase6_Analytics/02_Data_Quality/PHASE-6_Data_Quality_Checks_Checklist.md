# Phase 6 — Data Quality Checks Checklist (SSOT-aligned)

**Last Updated:** 2026-05-19 (UTC+8)

This checklist validates the integrity of the 3-log observability model:
- Snapshot log (v2.1, FULL-STATE BEFORE/AFTER)
- Event log (v2.2)
- Cycle Summary log (v2.2)

## 0) Run Context (always record)
- [ ] BaseName / run identifier:
- [ ] Date range:
- [ ] Broker / account mode (if known):
- [ ] Schema versions: Snapshot v2.1, Event v2.2, Cycle Summary v2.2
- [ ] Ingestion tool and parsing settings (delimiter, encoding, datetime parsing)
- [ ] Determinism mode (repeated backtest? yes/no)

## 1) File Presence & Basic Integrity (FATAL if fail)
- [ ] Snapshots CSV exists and is parseable
- [ ] Events CSV exists and is parseable
- [ ] Cycle Summary CSV exists and is parseable
- [ ] No shifted columns / parse anomalies

## 2) Schema Compliance — Column Count + Column Order (FATAL if fail)
### 2A) Event Log (MM_Events.csv) — v2.2
- [ ] Exactly 19 columns; exact SSOT order
- [ ] Required identity/classification populated for every row
- [ ] position_type only LONG/SHORT/NA

### 2B) Snapshot Log (MM_Snapshots.csv) — v2.1
- [ ] Exactly 36 columns; exact SSOT order
- [ ] FULL-STATE: numeric N/A=0, string N/A=""; no blanks-as-missing
- [ ] position_type only LONG/SHORT/NA

### 2C) Cycle Summary (MM_Cycle_Summary.csv) — v2.2
- [ ] Exactly 20 columns; exact SSOT order
- [ ] One row per completed lifecycle only

## 3) Controlled Enum & Formatting (ERROR if fail)
### 3A) Event
- [ ] event_type ∈ ENTRY/SCALE_OUT/BE/TRAIL/EXIT/CLOSE
- [ ] timeframe uses EnumToString form (e.g., PERIOD_M15)
- [ ] phase uses canonical MM phase strings

### 3B) Snapshot
- [ ] record_type ∈ MM_SNAPSHOT_BEFORE/MM_SNAPSHOT_AFTER
- [ ] AFTER event_outcome ∈ SUCCESS/FAIL/SKIP
- [ ] BEFORE event_outcome is neutral ""
- [ ] ENTRY AFTER is SUCCESS/FAIL only (not SKIP)

## 4) Snapshot Pairing Checks (correlation_id)
- [ ] JF-SNAP-01 Missing AFTER
- [ ] JF-SNAP-02 Missing BEFORE
- [ ] JF-SNAP-03 Duplicate BEFORE/AFTER
- [ ] JF-SNAP-04 BEFORE outcome not neutral
- [ ] JF-SNAP-05 AFTER outcome invalid or missing reason when action_executed=false

## 5) Snapshot ↔ Event Join Checks (correlation_id)
- [ ] JF-JOIN-01 Snapshot success but missing non-CLOSE Event
- [ ] JF-JOIN-02 Non-CLOSE Event exists but Snapshot pair missing
- [ ] JF-JOIN-03 Event.event_type != Snapshot.mm_event
- [ ] JF-JOIN-04 ticket/position_type mismatch between Event and Snapshot
- [ ] JF-JOIN-05 Unexpected Snapshot CLOSE rows

## 6) Event CLOSE & Lifecycle Completeness
- [ ] For each cycle_id: exactly 1 Event CLOSE
- [ ] EXIT optionality: 0..1 EXIT per cycle
- [ ] CLOSE correlation_id rule: engine EXIT→CLOSE may share correlation_id only for engine-driven exit signal close

## 7) Event Close Evidence Applicability (v2.2)
- [ ] CLOSE rows: close_reason/price/profit/volume/deal_id populated
- [ ] ENTRY/BE/TRAIL/EXIT rows: close_* fields neutral
- [ ] SCALE_OUT rows: evidence conditional when partial-close deal matched
- [ ] close_volume semantics: >0 for SCALE_OUT executed and CLOSE; 0/empty for non-applicable

## 8) Cycle Summary ↔ Event Reconciliation (cycle_id)
- [ ] JF-CYCLE-01 Summary without Event CLOSE
- [ ] JF-CYCLE-02 Event CLOSE without Summary
- [ ] JF-CYCLE-03 Duplicate Event CLOSE
- [ ] JF-CYCLE-04 CLOSE evidence mismatch (exit_time/exit_price/close_reason/deal_id/ticket/position_type)
- [ ] JF-CYCLE-05 pnl mismatch: SUM(scale_out close_profit) + close close_profit
- [ ] JF-CYCLE-06 close_volume mismatch: SUM(scale_out close_volume) + close close_volume

## 9) Snapshot Evidence Applicability (v2.1)
- [ ] Scale fields 0 for non-SCALE_OUT
- [ ] Stoploss fields 0 for non-BE/TRAIL
- [ ] closed_lots 0 for non-SCALE_OUT
- [ ] atr_value is not DBL_MAX / invalid sentinel

## 10) Determinism & Replay Completeness
- [ ] Repeated backtests produce identical outputs (counts + key aggregates)
- [ ] Reconstruct lifecycles from logs alone (ENTRY→actions→CLOSE)

## 11) Reporting Output
- [ ] Data Quality Summary table produced (counts by JF-code and severity)
- [ ] Failure Details table produced (code, key, expected vs actual, recommended action)
- [ ] Gate policy: any FATAL -> mark analytics output INVALID
