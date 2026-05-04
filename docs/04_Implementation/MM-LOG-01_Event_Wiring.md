
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

    `CTradeEngine::ManageEntry(...)` → `CEntryStrategyEngine::Evaluate(...)` (entry strategy decision)

- Handler:

    `CTradeExecution::ExecuteEntry(...)`   

- Logger Call:

    `m_logger.LogMMEventBase(...)`

    (Includes cycle_id for lifecycle grouping as required by MM-LOG-01 v1.3)


---

## SCALE_OUT

- Trigger Location:

    `CTradeEngine::ManageOpenPosition(...)` → `CPartialCloseEngine::Evaluate(...)` (evaluate scaling-out condition)

- Handler:

    `CPartialCloseEngine::PartialClose(...)`
- Logger Call:

    `m_logger.LogMMEventBase(...)`
---

## BREAK_EVEN

- Trigger Location:

    `CTradeEngine::ManageOpenPosition(...)` → `CBreakEvenEngine::Evaluate(...)` (evaluate Break-Even condition)

- Handler:

    `CTradeExecution::ModifyStopLoss(...)`

- Logger Call:

    `m_logger.LogMMEventBase(...)`


---

## TRAIL

- Trigger Location:

    `CTradeEngine::ManageOpenPosition(...)` → `CTrailingStopEngine::Evaluate(...)`  (evaluate trailing stop condition)
- Handler:

    `CTradeExecution::ModifyStopLoss(...)`

- Logger Call:

    `m_logger.LogMMEventBase(...)`
---

## EXIT

- Trigger Location:

    `CTradeEngine::ManageExit(...)` →  `CExitSignal::Update(...)` (evaluate exit condition)

- Handler:
    
    `CTradeExecution::ExecuteExit(...)`

- Logger Call:

    `m_logger.LogMMEventBase(...)`
