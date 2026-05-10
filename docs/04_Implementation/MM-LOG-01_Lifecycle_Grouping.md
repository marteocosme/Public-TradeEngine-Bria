# MM-LOG-01 Lifecycle Grouping

## ✅ 🔒 Document Status

Version: v1.1  
Status: ✅ ACTIVE  
Last Updated: 2026-05-10 (UTC+8) 

---

## 🎯 Purpose

Defines how trade lifecycles are grouped using `cycle_id` across MM-LOG-01 logging.

---

## 🧩 Lifecycle Definition

A trade lifecycle is defined as:

ENTRY  
→ SCALE_OUT / BREAK_EVEN / TRAIL (0..n times) /EXIT (intent only)
→ CLOSE

---

## 🔢 cycle_id Behavior

- A new cycle_id is generated at ENTRY
- The same cycle_id is reused for all subsequent MM actions
- The lifecycle ends at CLOSE

---

## 🔄 Lifecycle Flow

Example:

cycle_id = 5

→ ENTRY  
→ SCALE_OUT  
→ BREAK_EVEN  
→ TRAIL  
→ EXIT  (optional; intent only)
→ CLOSE (mandatory lifecycle terminator)

---

## 📊 Logging Requirement

All logs MUST include cycle_id:

- MM events
- BEFORE snapshots
- AFTER snapshots

---

## ✅ Objective

Provide full traceability and grouping of all logs belonging to a single trade lifecycle.

---

## 🔗 Dependencies

- MM-LOG-01_Logging_Schema_Contract.md (SSOT filename)
- Logging_Architecture.md
- MM_Event_Log_Schema.md (SSOT filename)



## 🧪 Implementation Status — Logging Observability Upgrade

Status: ✅ CODE IMPLEMENTED — PENDING LOG VALIDATION

The following MM-LOG-01 observability upgrades have been implemented in code:

- `cycle_id` lifecycle grouping
- Snapshot integrity hardening
- SCALE_OUT event consolidation
- `action_summary` support
- Cycle summary logging via `MM_LogCycleSummary`
- Cycle summary CSV output

Pending validation:

- Confirm one lifecycle summary is emitted per completed CLOSE (lifecycle terminator)
- Confirm cycle_id remains consistent across ENTRY → MANAGE → (optional EXIT) → CLOSE
- Confirm no duplicate SCALE_OUT logs are emitted
- Confirm summary values are accurate:
  - entry_time
  - exit_time
  - entry_price
  - exit_price
  - pnl
  - scale_count
  - trail_count
  - be_triggered
- Confirm CSV output has no undeclared/runtime issues
- Confirm no garbage/uninitialized values appear in logs

Next validation step:

Run a backtest and review the generated MM event, snapshot, and cycle summary logs.


### Change Log
#### v1.1 (2026-05-09)
- Updated validation notes to confirm cycle summary emitted per CLOSE (not EXIT).
- Updated dependency references to SSOT filenames.
- Clarified lifecycle flow includes optional EXIT and mandatory CLOSE.


