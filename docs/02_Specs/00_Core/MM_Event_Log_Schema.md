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
- MM_EVENT_EXIT   (Intent — engine close request)
- MM_EVENT_CLOSE  (Outcome — broker-confirmed closure)

---

## 3) CSV Schema (Column Order is Fixed)

### 3.1 Column List (in order)

**Base columns (always present):**
1. debug_event_id (ulong) — debug sequence id (non-contractual but stable column)
2. trade_id (long) — internal trade identifier
3. ticket (ulong) — broker ticket (0 if unavailable)
4. event_time (string datetime) — formatted time string
5. symbol (string)
6. cycle_id (int) — lifecycle grouping id
7. action_summary (string)
8. scale_steps (int)
9. scale_fraction_total (double)
10. event_type (string enum) — canonical identifier
11. phase (string enum) — MM phase classification
12. timeframe (string enum)

**E2 CLOSE columns (required for MM_EVENT_CLOSE, otherwise empty):**

13. close_reason (string enum)
14. close_price (double)
15. close_profit (double)
16. close_volume (double)
17. deal_id (long)

> Note: Columns 1–12 reflect the current implementation’s event writer fields and ordering. New CLOSE columns are appended to preserve backward compatibility for older parsers.  

---

## 4) Field Rules (Strict)

### 4.1 Required vs Optional
- Columns 1–12: MUST exist for every row.
- Columns 13–17:
  - MUST be populated when event_type = MM_EVENT_CLOSE
  - MUST be empty for all other event types (ENTRY/SCALE/BE/TRAIL/EXIT)

### 4.2 close_reason (required for CLOSE)
close_reason MUST be one of:
- SIGNAL
- MANUAL
- TP_HIT
- SL_HIT
- STOP_OUT
- UNKNOWN

### 4.3 Two-phase termination rules (MM-LOG-01 alignment)
- MM_EVENT_EXIT is optional per cycle (0..1)
- MM_EVENT_CLOSE is mandatory per cycle (exactly 1) and terminates lifecycle

---

## 5) JSON Event Object Schema
Each JSON line/object must provide keys matching the CSV schema field names.

### 5.1 Required keys (all events)
- debug_event_id
- trade_id
- ticket
- event_time
- symbol
- cycle_id
- action_summary
- scale_steps
- scale_fraction_total
- event_type
- phase
- timeframe

### 5.2 Required keys for MM_EVENT_CLOSE only
- close_reason
- close_price
- close_profit
- close_volume
- deal_id

---

## 6) Versioning / Archive Rules
- SSOT file is stable: `MM_Event_Log_Schema.md`
- Archived versions live in `/00_Core/_archive/` as:
  - `MM_Event_Log_Schema_vX.Y.md`
- Before any structural schema change:
  1) archive current SSOT copy
  2) bump version in SSOT header
  3) update Change Log
  4) update MM-LOG-01 contract dependencies if needed

---

## 7) Change Log
### v1.0
- Initial SSOT definition for MM event logs
- Added CLOSE outcome fields (E2): close_reason, close_price, close_profit, close_volume, deal_id

✅ End of MM Event Log Schema
