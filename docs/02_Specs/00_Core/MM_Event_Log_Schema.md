# MM Event Log Schema (MM_Events.csv / JSON)

### 🔒 Document Status
Version: v1.0  
Status: ✅ ACTIVE (SSOT)  
Last Updated: 2026-05-07 (UTC+8)

### 🎯 Purpose
Defines the **authoritative schema** for Money Management Event logs:
- CSV: `<BaseName>_MM_Events.csv`
- JSON: `<BaseName>.json` (event objects)

This schema is the SSOT for:
- Column order
- Field naming
- Field types
- Required/optional rules per event_type

### Supersedes
- None (initial release)

### 🔗 Dependencies (SSOT)
- MM-LOG-01_Logging_Schema_Contract.md (Two-phase termination + close_reason rules)
- TradeLifecycleEvents.md (canonical event identifiers)

---

## 1) Scope
This schema covers **MM event logs** (engine intent + broker-confirmed outcomes):
- ENTRY / SCALE_OUT / BE / TRAIL
- EXIT (intent)
- CLOSE (outcome)

This schema does NOT cover:
- Broker execution telemetry (OrderSend/OrderModify responses, raw trade transaction payloads)
→ Covered by EXEC-LOG-01

---

## 2) Canonical Event Types
Event `event_type` MUST be one of:
- MM_EVENT_ENTRY
- MM_EVENT_SCALE_OUT
- MM_EVENT_BE
- MM_EVENT_TRAIL
- MM_EVENT_EXIT   *(Intent — engine close request; optional per lifecycle)*
- MM_EVENT_CLOSE  *(Outcome — broker-confirmed closure; mandatory lifecycle terminator)*

---

## 3) CSV Schema (Column Order is Fixed)

### 3.1 Column List (in order)


**Core (required for every row):**
1) debug_event_id (ulong)  
   - Monotonic debug sequence ID (logger-generated).  
   - Used for diagnostics only (not a trading identifier).

2) event_time (string datetime)  
   - Time string in the EA’s configured format.

3) symbol (string)  

4) timeframe (string enum)  
   - Example: PERIOD_M15

5) phase (string enum)  
   - Example: MM_PHASE_ENTRY / MM_PHASE_MANAGE / MM_PHASE_EXIT

6) event_type (string enum)  
   - Must match Canonical Event Types (Section 2)

7) cycle_id (int)  
   - Lifecycle grouping ID for ENTRY→…→CLOSE reconstruction

8) trade_id (long)  
   - Internal trade identifier (system-defined)

9) ticket (ulong)  
   - Broker ticket (0 if not applicable/unknown)

10) action_summary (string)  
   - Human-readable action description

11) scale_steps (int)  
   - Number of scale steps applied so far (0 if not applicable)

12) scale_fraction_total (double)  
   - Total fraction of position closed so far (0.0 if not applicable)


**CLOSE-only (E2 fields; mandatory for MM_EVENT_CLOSE, empty otherwise):**

13) close_reason (string enum)  
14) close_price (double)  
15) close_profit (double)  
16) close_volume (double)  
17) deal_id (long)

> Column order is fixed. Any missing/extra columns invalidate the row for schema compliance.

---

## 4) Field Rules (Strict)

### 4.1 Required vs Optional
- Columns 1–12: MUST exist for every row.
- Columns 13–17:
  - MUST be populated when event_type = MM_EVENT_CLOSE
  - MUST be empty for all other event types (ENTRY/SCALE/BE/TRAIL/EXIT)

### 4.2 close_reason (required for CLOSE)
`close_reason` MUST be one of:
- SIGNAL
- MANUAL
- TP_HIT
- SL_HIT
- STOP_OUT
- UNKNOWN

### 4.3 Two-phase termination rules (MM-LOG-01 alignment)
- `MM_EVENT_EXIT` A lifecycle MAY contain 0..1
- `MM_EVENT_CLOSE` A lifecycle MUST contain exactly and terminates lifecycle


### 4.4 Consistency requirements
- `cycle_id` MUST be constant across all events belonging to the same lifecycle.
- `cycle_id` MUST increment on each ENTRY lifecycle start.
- `ticket` and/or `trade_id` MUST allow joining across logs (when available).
- phase and timeframe MUST use `ENUM_STRINGS` (EnumToString output), not custom shortened labels.
---

## 5) JSON Event Object Schema

### 5.1 Required keys (all events)

Each JSON event MUST contain keys matching the CSV field names:
- debug_event_id
- event_time
- symbol
- timeframe
- phase
- event_type
- cycle_id
- trade_id
- ticket
- action_summary
- scale_steps
- scale_fraction_total
- close_reason
- close_price
- close_profit
- close_volume
- deal_id


### 5.2 Required keys for MM_EVENT_CLOSE only

For `MM_EVENT_CLOSE`:
- close_reason / close_price / close_profit / close_volume / deal_id MUST be populated.

For non-CLOSE events:
- close_reason / close_price / close_profit / close_volume / deal_id MUST be null/empty.


---


## 6) Implementation Binding (Code)
The event log producer MUST emit fields consistent with the canonical event payload model:
- `event_time`, `event_type`, `phase`, `symbol`, `timeframe`, `trade_id`, `ticket`, `cycle_id`,
  `scale_steps`, `scale_fraction_total`, `action_summary` (plus `debug_event_id`).

> Note: Existing implementations may require code alignment if the CSV column order differs from this schema.

---

## 7) Versioning / Archive Rules
- SSOT file is stable: `MM_Event_Log_Schema.md`
- Archived versions live in `/00_Core/_archive/` as:
  - `MM_Event_Log_Schema_vX.Y.md`
- Before any structural schema change:
  1) archive current SSOT copy
  2) bump version in SSOT header
  3) update Change Log
  4) update MM-LOG-01 contract dependencies if needed

---

## 8) Change Log
### v1.0
- Initial SSOT definition for MM event logs
- Added CLOSE outcome fields (E2): 
- `close_reason`, `close_price`, `close_profit`, `close_volume`, `deal_id`

✅ End of MM Event Log Schema (SSOT)
