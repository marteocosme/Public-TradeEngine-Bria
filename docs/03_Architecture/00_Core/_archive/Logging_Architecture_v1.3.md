## 🗄️ Document Status (Archived)

**Version:** v1.3

**Status:** 🗄️ ARCHIVED (SUPERSEDED) —  HISTORICAL REFERENCE

**Superseded By:** Logging_Architecture.md

**Last Updated:** 2026-05-10 (UTC+8)

**Archived On:** 2026-05-11 (UTC+8)
- ⚠️ This file is retained for historical reference and legacy log parsing only.
- ⚠️ Do not edit content. Any changes must be made in the SSOT file.
 
# Logging Architecture

### 📂 Location Note

This file is part of the Core Architecture layer.

Path:
docs/03_Architecture/00_Core/

---

## 🔗 Traceability

This document is aligned with:

- MM_Snapshot_Schema.md (SSOT)
- MM_Event_Log_Schema.md (SSOT)
- MM-LOG-01_Logging_Schema_Contract.md (SSOT)
- MM-LOG-01_Runtime_Validation_Checklist.md (SSOT)

---

# ✅ 🎯 Purpose

Defines the logging system responsible for:

- Writing MM snapshots to file
- Enforcing schema consistency
- Ensuring auditability
- Managing log file structure

---

# ✅ 🧩 Logging Responsibilities

| Component | Responsibility |
|----------|--------------|
| TradeEngine | Emits snapshot data |
| Logger | Writes logs to file |
| Schema | Defines fields |
| Validation | Defines correctness rules |

---

# ✅ 🔄 Logging Pipeline
## Snapshot Pipeline (State)
```
TradeEngine
↓
Snapshot (BEFORE / AFTER)
↓
Logger (Snapshot Writer)
↓
File Output (CSV)
```

## Event Pipeline (Lifecycle / Intent / Outcome)
``` 
TradeEngine
↓
MM Event (ENTRY / SCALE_OUT / BE / TRAIL / EXIT / CLOSE)
↓
Logger (Event Writer)
↓
File Output (CSV / JSON)
```

---

## ✅ 🧱 Event Payload Standardization (Post-Sweep)

To prevent data corruption and reduce producer-side boilerplate, MM event records are initialized using a common initializer (`InitMMEvent(...)`).

### InitMMEvent(...) Responsibilities
- Sets common identity fields:
  - event_time, event_type, phase, symbol, timeframe, cycle_id, trade_id, ticket
- Applies safe defaults to non-applicable fields:
  - close_* fields default to neutral values (blank/0) and deal_id defaults to 0
  - scale_* fields default to 0
  - action_summary defaults blank

Event producers then populate only event-specific fields (e.g., action_summary, scale_steps/scale_fraction_total, broker evidence fields where applicable).


## 🔭 Observability Layer — Lifecycle Grouping

### Overview

To improve traceability and auditability, the logging system introduces **lifecycle grouping** using `cycle_id`.

This enables reconstruction of full trade lifecycles across MM events and snapshots.

---

### Lifecycle Definition

A trade lifecycle consists of:

ENTRY
→ MM actions (SCALE_OUT / BREAK_EVEN / TRAIL)
→ (optional EXIT intent)
→ CLOSE (broker-confirmed outcome)

---

### Broker Evidence Fields (close_* / deal_id) — Applicability
- MM_EVENT_CLOSE:
  - MUST populate close_reason, close_price, close_profit, close_volume, deal_id (final broker-confirmed closure).
- MM_EVENT_SCALE_OUT:
  - MAY populate close_reason, close_price, close_profit, close_volume, deal_id when a broker partial-close deal is matched.
  - If no matching deal is found, emit neutral defaults.
- ENTRY / BE / TRAIL / EXIT:
  - close_* fields MUST remain neutral defaults (blank/0), by design.

This prevents contamination of final outcome analytics while still preserving broker-confirmed evidence for partial closures.

---


#### close_reason Canonical Values (Analytics-Friendly)
close_reason is normalized into canonical strings for analytics and audit:
- CLOSE (EXPERT): "MM_EXPERT: Exit Signal"
- SCALE_OUT (EXPERT): "MM_EXPERT: Scale Out"
- Manual closures: MANUAL_DESKTOP_TERMINAL / MANUAL_MOBILE_APP / MANUAL_WEB_PLATFORM
- Broker outcomes: TP_HIT / SL_HIT / STOP_OUT Event / UNKNOWN / etc.

Exact allowed values are defined in MM_Event_Log_Schema.md (SSOT).

---

### Two‑Phase Termination (EXIT vs CLOSE)

To prevent lifecycle gaps in real execution:
- `MM_EVENT_EXIT` represents engine intent to close (signal/manual request). It is optional.
- `MM_EVENT_CLOSE` represents broker/deal-confirmed closure (TP/SL/STOP_OUT/SIGNAL/MANUAL). It is mandatory.

Architectural rule:
- EXIT and CLOSE are different sources of truth:
  - EXIT originates from the engine decision path
  - CLOSE originates from broker/deal confirmation
- Validation and Cycle Summary MUST use CLOSE as the lifecycle terminator.


---

### cycle_id Behavior

- A new `cycle_id` is generated at ENTRY
- The same `cycle_id` is reused for all subsequent MM actions
- The lifecycle ends at `MM_EVENT_CLOSE` (broker-confirmed outcome)
- `MM_EVENT_EXIT` is optional (intent only) and may not appear for TP/SL/STOP_OUT closures




---

### Integration into Logging Pipeline

TradeEngine detects ENTRY  
→ `cycle_id` is incremented  
→ BEFORE snapshot emitted with `cycle_id`  
→ Execution performed  
→ AFTER snapshot emitted with `cycle_id`  

During MM management:

- `SCALE_OUT` / `BE` / `TRAIL` reuse the same `cycle_id`
- All logs (events and snapshots) are tagged with `cycle_id`

At CLOSE (`MM_EVENT_CLOSE`):

- Closure is confirmed (broker/deal outcome)
- Final BEFORE and AFTER snapshots are emitted for closure observation
- Cycle Summary is emitted (one row per closed lifecycle)
- Lifecycle completes


---

### Result

All log records can be grouped by `cycle_id` to reconstruct:

- Full trade lifecycle
- State transitions
- MM decisions and execution outcomes

---

### Benefits

- Enables end-to-end trade traceability
- Simplifies debugging and validation
- Provides structured grouping for analysis and backtesting


# ✅ 📄 File Structure

## ✅ File Type

- CSV format
- Machine-readable
- Consistent column order

---

## ✅ Header Handling

### Rule:

- If file is new → ✅ write header
- If file exists → ❌ do not rewrite header

---

### Implementation Logic

- Use `NeedsHeader()` or equivalent check
- Must prevent duplicate headers

---

# ✅ 📊 Column Enforcement

## ✅ Rules

- Column count must match schema definition
- All fields must be present
- Missing values must use defaults
- Extra fields NOT allowed

---

## ✅ Validation Source

- Enforced under MM-LOG-01
- Verified via column validation tests

---

# ✅ 🔁 Snapshot Pair Logging

## ✅ Rule

Each BEFORE snapshot must be followed by AFTER snapshot.

---

## ✅ Guarantees

- No orphan entries
- Strict ordering preserved

---

# ✅ 🚀 Execution Outcome Logging

## ✅ Requirement

Execution results must be written in AFTER snapshot.

---

### Includes

- Execution success/failure
- Error codes
- Result flags

---

### Reference

- MM_Snapshot_Schema_v1.2 §5.3

---

# ✅ 📌 File Integrity Rules

## ✅ Must Ensure

- File is append-only
- No row corruption
- No partial writes
- Order preserved

---

# ✅ 🧠 Logger Constraints

Logger MUST NOT:

- Modify business logic
- Decide MM actions
- Change schema structure

Logger ONLY:

- Formats data
- Writes to file
- Enforces structure


## ✅ 🔧 Optional Lifecycle Controller Actions
Lifecycle controller actions may be compile-time disabled in some builds to reduce runtime overhead or isolate logging validation.
This does not change logging schema requirements; it only affects whether lifecycle controller hooks execute.

---

# ✅ 📌 Version Notes

##### v1.3 (2026-05-09)
- Documented dual logging pipelines (Snapshots vs Events).
- Documented InitMMEvent(...) as canonical event initializer and defaulting mechanism.
- Updated architecture rules for broker evidence fields: close_* and deal_id are mandatory for CLOSE and allowed for SCALE_OUT when deal-matched.
- Added close_reason canonical vocabulary guidance for analytics.

##### v1.2 (2026-05-07)
- Converted to stable SSOT filename: Logging_Architecture.md (archived old versioned file)
- Aligned lifecycle termination with MM-LOG-01 contract v1.4:
  - EXIT = intent (optional)
  - CLOSE = broker-confirmed outcome (mandatory terminator)
- Updated lifecycle grouping definition to end at MM_EVENT_CLOSE
- Added traceability to MM_Event_Log_Schema.md (SSOT) and TradeLifecycleEvents.md (SSOT)
- Updated lifecycle grouping definition and cycle_id termination rule to end at MM_EVENT_CLOSE

#### v1.1 (2026-05-05)

- Introduced `cycle_id` for lifecycle grouping
- Defined lifecycle-based logging structure (ENTRY → MANAGE → EXIT)
- Added requirement for all logs to include cycle_id
- Enables full trade lifecycle traceability and grouping

### v1.0 (2026-05-04)

- Initial logging architecture definition
- Header control defined
- Column enforcement defined
- Execution outcome integration included

---