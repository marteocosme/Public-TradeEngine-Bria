# MM-LOG-01 Snapshot Wiring

## ✅ STATUS: ACTIVE

---

## 🎯 Purpose

Defines how position snapshots are constructed and used during logging.

Scope:
- Snapshot creation
- BEFORE/AFTER capture
- Data sourcing from system components

---

## 🔗 Dependencies

### Snapshot Schema
→ /docs/02_Specs/00_Core/MM_Snapshot_Schema_v1.2.md

⚠️ This file does NOT define schema fields.

---

# 🧩 Snapshot Construction

## Snapshot Builder

- Function Name:
    - `BuildTradeContext(...)`
    - `BuildPositionSnapshot(...)`
    - `BeginMMCycle(...)`
    - `EndMMCycleCheck(...)`

- Source Data:
  - Position data (PositionGet*)
  - Symbol data (SymbolInfo*)
  - Indicator values (ATR)
  - Trade context (if applicable)


- Notes:

  Aggregates all required data into a snapshot struct conforming to schema v1.2.

---

## BEFORE Snapshot

- When captured: 
  Immediately before executing MM action

- Source:

    `EmitSnapshotBefore(...)`

- Notes:

  Captures current state prior to modification (ENTRY, BE, TRAIL, etc.)


---

## AFTER Snapshot

- When captured:
Immediately after executing MM action
- Source:

    `EmitSnapshotAfter(...)`

- Notes:

    Captures resulting state after modification

---

# 🔄 Snapshot Flow

1. Build BEFORE snapshot
2. Execute MM action
3. Build AFTER snapshot
4. Emit to logger

---

# ⚠️ Rules

- MUST capture BOTH BEFORE and AFTER snapshots
- MUST follow schema v1.2
- MUST NOT redefine fields

---