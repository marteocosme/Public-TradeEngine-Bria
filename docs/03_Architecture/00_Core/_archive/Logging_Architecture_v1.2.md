## 🗄️ Document Status (Archived)

**Version:** v1.2

**Status:** 🗄️ ARCHIVED (SUPERSEDED) —  HISTORICAL REFERENCE

**Superseded By:** Logging_Architecture.md

**Last Updated:** 2026-05-07 (UTC+8)

**Archived On:** 2026-05-10 (UTC+8)
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
```
TradeEngine
↓
Snapshot (BEFORE / AFTER)
↓
Logger
↓
File Output (CSV)
```

---

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

---

Logger ONLY:

- Formats data
- Writes to file
- Enforces structure

---

# ✅ 📌 Version Notes

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