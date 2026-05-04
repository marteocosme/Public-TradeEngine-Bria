
# MM-LOG-01 Event Wiring

## ✅ STATUS: ACTIVE

---

## 🎯 Purpose

Defines where MM lifecycle events are triggered and logged.

Scope:
- ENTRY
- SCALE_OUT
- BREAK_EVEN
- TRAIL
- EXIT

---

## 🔗 Dependencies

### Snapshot Schema
→ /docs/02_Specs/00_Core/MM_Snapshot_Schema_v1.2.md

⚠️ This file does NOT define schema fields.

---

# 🧩 Event Mapping

## ENTRY

- Trigger Location: 

    `CTradeEngine::ManageEntry(...)`

- Handler:

    `CTradeExecution::ExecuteEntry(...)`   

- Logger Call:

    `EmitSnapshotBefore(..)`
    
    `EmitSnapshotAfter(...)`

    `m_logger.LogMMEventBase(...)`


---

## SCALE_OUT

- Trigger Location:

    `CTradeEngine::ManageOpenPosition(...)`

- Handler:

    `CPartialCloseEngine::PartialClose(...)`
- Logger Call:

    `EmitSnapshotBefore(..)`
    
    `EmitSnapshotAfter(...)`

    `m_logger.LogMMEventBase(...)`
---

## BREAK_EVEN

- Trigger Location:

    `CTradeEngine::ManageOpenPosition(...)`

- Handler:

    `CTradeExecution::ModifyStopLoss(...)`

- Logger Call:

    `EmitSnapshotBefore(..)`
    
    `EmitSnapshotAfter(...)`

    `m_logger.LogMMEventBase(...)`


---

## TRAIL

- Trigger Location:

    `CTradeEngine::ManageOpenPosition(...)`
- Handler:

    `CTradeExecution::ModifyStopLoss(...)`

- Logger Call:

    `EmitSnapshotBefore(..)`
    
    `EmitSnapshotAfter(...)`

    `m_logger.LogMMEventBase(...)`
---

## EXIT

- Trigger Location:

    `CTradeEngine::ManageExit(...)`

- Handler:

    `CExitSignal::Update(...)`

- Logger Call:

    `EmitSnapshotBefore(..)`
    
    `EmitSnapshotAfter(...)`

    `m_logger.LogMMEventBase(...)`
