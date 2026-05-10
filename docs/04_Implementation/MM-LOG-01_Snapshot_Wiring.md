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
→ /docs/02_Specs/00_Core/MM_Snapshot_Schema.md

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

## 🔄 Snapshot Flow (Runtime)
- Begin MM cycle tracking (INF-3 enforcement state)
- Capture BEFORE snapshot via `EmitSnapshotBefore(...)`
- Execute MM action (execution layer / handler)
- Capture AFTER snapshot via `EmitSnapshotAfter(...)`
- Enforce pairing integrity (INF-3): both BEFORE and AFTER must exist for each MM event
- Log snapshots via:
  - `m_logger.LogMMSnapshotBefore(...)`
  - `m_logger.LogMMSnapshotAfter(...)`


---

# ⚠️ Rules

- MUST capture BOTH BEFORE and AFTER snapshots
- MUST follow Snapshot Schema v1.3
- MUST NOT redefine fields


---

### 🔹 Lifecycle Association Rule

All snapshots MUST include `cycle_id` corresponding to the active trade lifecycle.

---

### Requirements

- BEFORE and AFTER snapshots MUST share the same cycle_id
- cycle_id MUST match the associated MM event
- cycle_id MUST remain constant from ENTRY → CLOSE

---

### Purpose

- Ensures snapshots can be grouped into a complete lifecycle
- Enables correct pairing of MM actions and state transitions

---

## 🧠 Implementation Notes (Post-Sweep)
- ENTRY snapshots must not rely on PositionGetInteger(POSITION_TYPE) before a position exists.
  ENTRY current_price should be based on intended entry direction (entry bias → ask/bid selection).
- EXIT snapshots should use the entry ATR anchor (from ATR entry tracker) so atr_value and stoploss_points remain meaningful during EXIT validation.

