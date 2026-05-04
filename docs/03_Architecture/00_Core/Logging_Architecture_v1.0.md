# Logging Architecture

## 🔒 Document Status

Version: v1.1 
Status: ✅ ACTIVE  
Last Updated: 2026-05-05  

### 📂 Location Note

This file is part of the Core Architecture layer.

Path:
docs/03_Architecture/00_Core/

---

## 🔗 Traceability

This document is aligned with:

- MM_Snapshot_Schema_v1.2.md
- MM-LOG-01_Logging_Schema_Contract.md
- MM-LOG-01_Logging_Completion_and_Validation.md

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
→ EXIT

---

### cycle_id Behavior

- A new `cycle_id` is generated at ENTRY
- The same `cycle_id` is reused for all subsequent MM actions
- The lifecycle ends at EXIT

---

### Integration into Logging Pipeline

TradeEngine detects ENTRY  
→ cycle_id is incremented  
→ BEFORE snapshot emitted with cycle_id  
→ Execution performed  
→ AFTER snapshot emitted with cycle_id  

During MM management:

- SCALE_OUT / BE / TRAIL reuse the same cycle_id
- All logs (events and snapshots) are tagged with cycle_id

At EXIT:

- Final BEFORE and AFTER snapshots are emitted
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