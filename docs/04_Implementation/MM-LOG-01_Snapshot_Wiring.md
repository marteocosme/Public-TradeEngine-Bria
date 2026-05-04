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
    
    -   Snapshot Builder (implementation-defined)

- Source Data:
  - Position data (PositionGet*)
  - Symbol data (SymbolInfo*)
  - Indicator values (ATR)
  - Trade context (if applicable)


- Notes:

  This represents the logical construction of a snapshot.
  The actual implementation may vary across phases.


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


1. Capture BEFORE snapshot
2. Execute MM action (via handler)
3. Capture AFTER snapshot
4. Log via:
   `m_logger.LogMMEventBase(...)`


---

# ⚠️ Rules

- MUST capture BOTH BEFORE and AFTER snapshots
- MUST follow schema v1.2
- MUST NOT redefine fields


---

### 🔹 Lifecycle Association Rule

All snapshots MUST include `cycle_id` corresponding to the active trade lifecycle.

---

### Requirements

- BEFORE and AFTER snapshots MUST share the same cycle_id
- cycle_id MUST match the associated MM event
- cycle_id MUST remain constant from ENTRY → EXIT

---

### Purpose

- Ensures snapshots can be grouped into a complete lifecycle
- Enables correct pairing of MM actions and state transitions


---