# MM-LOG-01 Runtime Validation Checklist

## 🔒 Document Status

Version: v1.5

Status: ✅ ACTIVE (SSOT) — RUNTIME VALIDATION PASSED (v2.2)

Last Updated: 2026-05-19 (UTC+8)

Runtime Schema Version: v2.2

---

## 🎯 Purpose

This document is the active runtime validation checklist for MM-LOG-01.

It validates that the Money Management logging system is:

- lifecycle-aware
- snapshot-complete
- schema-compliant
- event-consistent
- analytically usable
- ready for production validation

---


### 🔗 Dependencies (SSOT)

- /docs/02_Specs/00_Core/MM_Snapshot_Schema.md
- /docs/02_Specs/00_Core/MM_Event_Log_Schema.md
- /docs/02_Specs/00_Core/MM-LOG-01_Logging_Schema_Contract.md
- /docs/03_Architecture/00_Core/Logging_Architecture.md
- /docs/04_Implementation/MM-LOG-01_Event_Wiring.md
- /docs/04_Implementation/MM-LOG-01_Snapshot_Wiring.md
- /docs/04_Implementation/MM-LOG-01_Lifecycle_Grouping.md

⚠️ This checklist does NOT define or override schema fields.
Snapshot fields are defined by:
→ /docs/02_Specs/00_Core/MM_Snapshot_Schema.md

Event fields are defined by:
→ /docs/02_Specs/00_Core/MM_Event_Log_Schema.md


## Current Phase Status

MM-LOG-01 Observability Upgrade is code-complete.
Runtime validation PASSED under v2.1 and is PASSED re-validation under v2.2 due to Cycle Summary volume model changes (P5-FIX-05).


Validated runtime outputs:

- `NNFX_TradeEvents_MM_Snapshots.csv`
- `NNFX_TradeEvents_MM_Events.csv`
- `NNFX_TradeEvents_MM_Cycle_Summary.csv`

Validation status:

- Snapshot Log v2.1: PASSED
- Event Log v2.1: PASSED
- Cycle Summary Log v2.1: PASSED
- v2.2 re-validation: PASSED (Cycle Summary volume semantics update)

### Implemented upgrades:

- cycle_id lifecycle grouping
- Snapshot integrity hardening
- SCALE_OUT event consolidation
- action_summary support
- Cycle summary logging via MM_LogCycleSummary
- Cycle summary CSV output
- MM_EVENT_CLOSE implemented (broker-confirmed closure)
- Cycle Summary emission moved to CLOSE (lifecycle terminator)
- Event Log Schema (E2 fields) implemented and populated
- Cycle Summary PnL aggregation corrected to include successful SCALE_OUT close_profit values plus final CLOSE close_profit.
- Conditional MM_EVENT_CLOSE correlation behavior implemented:
  - engine-driven EXIT → CLOSE may share correlation_id
  - broker-driven TP/SL/manual/unknown CLOSE receives a dedicated CLOSE correlation_id



### Recent Changes / Validation Notes (Patch Notes)

- ✅ P5-FIX-05: Volume model simplification:
  - Removed total_traded_volume from Cycle Summary schema.
  - Cycle Summary close_volume now represents total lifecycle closed volume (SUM of SCALE_OUT + CLOSE event close_volume).
- ✅ “MM_EVENT_SCALE_OUT writes deal_id and close_* fields (price/profit/volume/reason) when partial close succeeds.”
- ✅ Fixed event log data corruption by ensuring all `MM_LogEventBase` instances are zero-initialized before write.
- ✅ Updated E2 close outcome field applicability:
  - MM_EVENT_CLOSE MUST populate close_* and deal_id (broker-confirmed final closure)
  - MM_EVENT_SCALE_OUT MAY populate close_* and deal_id when a partial-close deal is matched
  - Other non-CLOSE events keep neutral defaults
- ✅ Improved `MM_EVENT_EXIT` semantics: intent-only with descriptive `action_summary` (e.g., `Exit signal: RVI (EXIT_MODE_CROSS)`).
- ✅ Fixed timeframe corruption in event logs; now consistently logs valid `PERIOD_*` values (e.g., `PERIOD_M15`).
- ✅ Expanded deal close reason mapping; CLOSE reasons now include `TP_HIT`, `SL_HIT`, and EA-driven closes like `MM_EXPERT: Exit Signal`.
- ✅ P5-FIX-01: Cycle Summary pnl now represents total realized lifecycle PnL:
  - successful MM_EVENT_SCALE_OUT close_profit values
  - plus mandatory MM_EVENT_CLOSE close_profit value
- ✅ P5-FIX-02A: MM_EVENT_CLOSE correlation_id behavior is now conditional:
  - MM_EVENT_EXIT → MM_EVENT_CLOSE may share correlation_id when close_reason = MM_EXPERT: Exit Signal
  - broker-driven CLOSE rows such as TP_HIT, SL_HIT, STOP_OUT, UNKNOWN, or manual/external close receive a dedicated CLOSE correlation_id
  - broker-driven CLOSE must not inherit correlation_id from ENTRY, SCALE_OUT, BE, or TRAIL


#### Runtime Validation Result:
- ✅ `cycle_id` lifecycle consistency validated
- ✅ BEFORE / AFTER snapshot integrity validated
- ✅ `correlation_id` pairing validated for non-CLOSE actions and conditional CLOSE correlation behavior validated.
- ✅ position_type validated across Snapshot, Event, and Cycle Summary logs
- ✅ SCALE_OUT event evidence validated
- ✅ action_summary correctness validated
- ✅ one Cycle Summary row per CLOSE validated
- ✅ Cycle Summary PnL aggregation validated against realized-PnL lifecycle events:
  - successful MM_EVENT_SCALE_OUT close_profit values
  - mandatory MM_EVENT_CLOSE close_profit value
- ✅ no DBL_MAX / garbage / uninitialized values detected
- ✅ Event ↔ Snapshot correlation validated
- ✅ Cycle Summary broker close evidence reconciled against Event CLOSE fields.

---

## 🧪 Runtime Validation Checklist

### 1. Event Coverage

- [x] ENTRY events are logged
  [x] SCALE_OUT events are logged
- [x] BREAK_EVEN events are logged
- [x] TRAIL events are logged
- [x] EXIT events are logged (optional; intent only)
- [x] CLOSE events are logged (mandatory lifecycle terminator)


---

### 2. Lifecycle Grouping Validation

- [x] Every event log includes cycle_id
- [x] Every snapshot log includes cycle_id
- [x] cycle_id increments only on ENTRY
- [x] cycle_id remains constant from ENTRY to CLOSE
- [x] No event appears with an incorrect cycle_id
- [x] All lifecycle rows can be grouped by cycle_id
- [x] Each cycle_id has exactly one CLOSE event
- [x] EXIT may be absent for TP/SL/STOP_OUT closures (allowed)
- [x] If EXIT exists, it must occur before CLOSE


---

### 3. Snapshot Integrity Validation

- [x] Every MM event has a BEFORE snapshot
- [x] Every MM event has an AFTER snapshot
- [x] CLOSE is emitted as an Event-only broker-confirmed lifecycle terminator under the current v2.1 runtime model.
- [x] CLOSE does not require a Snapshot BEFORE/AFTER pair unless a future schema version explicitly adds CLOSE snapshots.
- [x] BEFORE and AFTER snapshots share the same cycle_id
- [x] BEFORE mm_event_intent matches AFTER mm_event_result for the same action
- [x] No orphan BEFORE snapshot exists
- [x] No orphan AFTER snapshot exists
- [x] Snapshot rows conform to MM_Snapshot_Schema_v1.2.md
- [x] No garbage or uninitialized numeric values appear

---

### 4. SCALE_OUT Consolidation Validation

- [x] Multiple internal SCALE_OUT steps are consolidated into one logical event
- [x] scale_steps is populated correctly
- [x] scale_fraction_total is populated correctly
- [x] No duplicate SCALE_OUT event spam appears

---

### 5. action_summary Validation

- [x] ENTRY action_summary is populated
- [x] SCALE_OUT action_summary is populated
- [x] BREAK_EVEN action_summary is populated
- [x] TRAIL action_summary is populated
- [x] EXIT action_summary is populated
- [x] CLOSE action_summary is populated
- [x] action_summary is human-readable and matches event intent

---

### 6. CLOSE (E2) Field Validation (MM_Event_Log_Schema)

For every MM_EVENT_CLOSE row:
- [x] close_reason is populated and valid (MM_EXPERT: Exit Signal / MANUAL / TP_HIT / SL_HIT / STOP_OUT / UNKNOWN)
- [x] close_price is populated and numeric
- [x] close_profit is populated and numeric
- [x] close_volume is populated and numeric
- [x] deal_id is populated and numeric

For MM_EVENT_SCALE_OUT rows:
- [x] close_reason / close_price / close_profit / close_volume / deal_id MAY be populated when a broker partial-close deal is matched.
- [x] If no matching deal is found, these fields should remain neutral defaults (empty/0).

For other non-CLOSE events (ENTRY / BE / TRAIL / EXIT):
- [x] close_reason = ""
- [x] close_price = 0.0
- [x] close_profit = 0.0
- [x] close_volume = 0.0
- [x] deal_id = 0


#### 7. CLOSE correlation_id Validation

MM_EVENT_CLOSE correlation_id behavior MUST follow close-origin semantics.

Engine-driven EXIT → CLOSE rule:
- [x] If MM_EVENT_CLOSE is the broker-confirmed result of an explicit MM_EVENT_EXIT:
  - [x] close_reason = MM_EXPERT: Exit Signal
  - [x] MM_EVENT_EXIT and MM_EVENT_CLOSE MAY share the same correlation_id
  - [x] This shared correlation_id is valid because CLOSE confirms the same logical exit action chain.

Broker-driven CLOSE rule:
- [x] If MM_EVENT_CLOSE is caused by broker-side closure:
  - [x] TP_HIT
  - [x] SL_HIT
  - [ ] STOP_OUT Event
  - [ ] UNKNOWN
  - [ ] manual / external close reason
- [x] MM_EVENT_CLOSE MUST receive a dedicated CLOSE correlation_id.
- [x] MM_EVENT_CLOSE MUST NOT inherit correlation_id from prior non-exit events:
  - [x] MM_EVENT_ENTRY
  - [x] MM_EVENT_SCALE_OUT
  - [x] MM_EVENT_BE
  - [x] MM_EVENT_TRAIL

Required validation cases:
- [x] EXIT → CLOSE with close_reason = MM_EXPERT: Exit Signal may share correlation_id.
- [x] ENTRY → CLOSE with close_reason = TP_HIT or SL_HIT must not share correlation_id.
- [x] SCALE_OUT → CLOSE with close_reason = TP_HIT or SL_HIT must not share correlation_id.
- [x] BE → CLOSE with close_reason = TP_HIT or SL_HIT must not share correlation_id.
- [x] TRAIL → CLOSE with close_reason = TP_HIT or SL_HIT must not share correlation_id.

BE-to-SL causality note:
- [x] If BE moves SL and the final close is SL_HIT, the close may be causally related to BE.
- [x] This causality MUST be validated through lifecycle/state fields such as be_triggered, previous_stoploss, new_stoploss, and close_reason.
- [x] It MUST NOT be represented by reusing the BE correlation_id for MM_EVENT_CLOSE.


---

### 8. Cycle Summary Validation

- [x] Cycle summary CSV file is generated
- [x] One summary row is emitted after each CLOSE
- [x] Number of cycle summary rows equals number of `MM_EVENT_CLOSE` events
- [x] summary `cycle_id` matches event lifecycle `cycle_id`
- [x] `entry_time` is valid
- [x] `exit_time` is valid
- [x] `entry_price` is valid
- [x] `exit_price` is valid
- [x] pnl is realistic and validated against MT5 result
- [x] pnl equals total realized lifecycle PnL:
  - [x] SUM(successful MM_EVENT_SCALE_OUT close_profit)
  - [x] plus MM_EVENT_CLOSE close_profit
- [ ] For close-only cycles without successful SCALE_OUT:
  - [x] summary.pnl == MM_EVENT_CLOSE.close_profit
- [ ] For cycles with successful SCALE_OUT:
  - [ ] summary.pnl == SUM(SCALE_OUT close_profit) + MM_EVENT_CLOSE.close_profit
  - [ ] summary.pnl may differ from MM_EVENT_CLOSE.close_profit
- [x] `scale_count` is correct
- [x] `trail_count` is correct
- [x] `be_triggered` is correct
- [ ] close_volume equals total lifecycle closed volume:
  - [ ] close_volume == SUM(MM_EVENT_SCALE_OUT close_volume) + MM_EVENT_CLOSE close_volume
- [ ] For close-only cycles:
  - [ ] close_volume == MM_EVENT_CLOSE.close_volume
- [ ] For scale-out cycles:
  - [ ] close_volume == SUM(SCALE_OUT close_volume) + MM_EVENT_CLOSE.close_volume

---

### 9. Replay Completeness Validation

- [x] Full trade lifecycle can be reconstructed using logs only
- [x] ENTRY → MANAGE → (optional EXIT) → CLOSE sequence is visible
- [x] MM actions are observable in order
- [x] SL / size / risk evolution matches snapshot records
- [x] No unexplained timeline gaps exist

---

## ✅ Final Acceptance Criteria

MM-LOG-01 may be marked COMPLETE only when:

- [ ] All MM lifecycle events are logged correctly
- [ ] BEFORE and AFTER snapshots are paired and schema-compliant
- [ ] cycle_id reconstructs each lifecycle correctly
- [ ] SCALE_OUT events are consolidated
- [ ] action_summary is populated and meaningful
- [ ] Cycle summary logs are emitted correctly
- [ ] No garbage or uninitialized values appear
- [ ] Summary PnL and lifecycle metrics are validated against MT5 results
- [ ] Summary PnL represents total realized lifecycle PnL, including successful SCALE_OUT close_profit values plus final CLOSE close_profit
- [ ] Logs alone can reconstruct the full trade lifecycle
- [ ] `MM_EVENT_CLOSE` exists exactly once per cycle and carries E2 close fields
- [ ] `MM_EVENT_CLOSE` correlation_id behavior follows close-origin semantics:
  - [ ] engine-driven EXIT → CLOSE may share correlation_id
  - [ ] broker-driven TP/SL/manual/unknown CLOSE must receive a dedicated CLOSE correlation_id
- [ ] Replace “Cycle summary logs are emitted correctly” with “Cycle summary logs are emitted correctly (one per CLOSE)”
- [ ] SCALE_OUT rows may carry broker partial-close evidence (close_* + deal_id) when deal matching succeeds
- [ ] Cycle Summary close_volume represents total lifecycle closed volume:
  - [ ] close_volume == SUM(SCALE_OUT close_volume) + MM_EVENT_CLOSE.close_volume


Runtime validation criteria are satisfied for the current v2.1 logging model.

✅ MM-LOG-01 status:

RUNTIME VALIDATION PASSED — v2.1
RUNTIME VALIDATION PASSED — v2.2 (Cycle Summary volume semantics update)

## Change Log

### v1.5 (2026-05-19)
- Updated checklist to align with v2.2 Cycle Summary volume model (P5-FIX-05).
- Removed total_traded_volume validation checks.
- Redefined Cycle Summary close_volume validation as lifecycle aggregate:
  - SUM(SCALE_OUT close_volume) + CLOSE close_volume.
- Marked v2.2 runtime validation passed while preserving v2.1 passed status.

### v1.4 (2026-05-12)
- Updated checklist status from CODE COMPLETE / PENDING RUNTIME VALIDATION to RUNTIME VALIDATION PASSED.
- Recorded runtime schema version as v2.1.
- Confirmed Snapshot Log v2.1 validation passed.
- Confirmed Event Log v2.1 validation passed.
- Confirmed Cycle Summary Log v2.1 validation passed.
- Added validation result notes for position_type, correlation_id, internal_trade_id, Cycle Summary v2.1 close evidence, duration_sec, and lifecycle_status.
- Clarified that CLOSE is currently Event-only broker confirmation and does not require Snapshot BEFORE/AFTER pairs under v2.1.  
- P5-FIX-03 documentation alignment:
  - Added validation criteria for Cycle Summary total realized lifecycle PnL aggregation.
  - Clarified that Cycle Summary pnl must include successful MM_EVENT_SCALE_OUT close_profit values plus mandatory MM_EVENT_CLOSE close_profit.
  - Added validation criteria for conditional MM_EVENT_CLOSE correlation_id behavior.
  - Clarified that engine-driven EXIT → CLOSE may share correlation_id when close_reason = MM_EXPERT: Exit Signal.
  - Clarified that broker-driven CLOSE events such as TP_HIT, SL_HIT, STOP_OUT Event, UNKNOWN, or manual/external closes must receive a dedicated CLOSE correlation_id.
  - Clarified that BE-to-SL causality must be validated through lifecycle/state fields, not by reusing the BE correlation_id.
- P5-FIX-04:
  - Added validation rules for total_traded_volume lifecycle aggregation.
  - Clarified distinction between close_volume and total_traded_volume.
 


### v1.3 (2026-05-09)
- Aligned checklist with updated MM_Event_Log_Schema rules:
  - SCALE_OUT may populate close_* + deal_id when partial-close deal is matched.
  - CLOSE remains mandatory terminator and must populate close_* + deal_id.
  - Other non-CLOSE events keep neutral defaults.
- Resolved Patch Notes contradiction regarding E2 close field applicability.

### v1.2 (2026-05-08)
- Added Patch Notes section under Current Phase Status to record validated fixes and logging behavior improvements.
- Updated CLOSE reason validation list to include `MM_EXPERT: Exit Signal` to match current event outputs.
- Minor alignment updates to match MM-LOG-01 contract v1.5.

### v1.1 (2026-05-07)
- Updated checklist to align with MM-LOG-01 contract v1.4 two-phase termination:
  - EXIT optional (intent)
  - CLOSE mandatory (terminator)
- Added validation for E2 CLOSE fields per MM_Event_Log_Schema.md
- Updated lifecycle grouping and cycle summary reconciliation to use CLOSE, not EXIT
- Updated dependencies to SSOT stable filenames

