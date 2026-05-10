
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
- EXIT (optional; intent only)
- CLOSE (mandatory lifecycle terminator)

---

## 🔗 Dependencies

### Snapshot Schema
→ /docs/02_Specs/00_Core/MM_Snapshot_Schema.md

⚠️ This file does NOT define schema fields.

---

# 🧩 Event Mapping


## 🔧 Event Payload Standardization (Post-Sweep)

### InitMMEvent(...) — Canonical Event Initialization
All MM event records are initialized using a shared initializer:
- `InitMMEvent(evt, type, phase, symbol, ticket, when)`

This initializer:
- sets common identity fields (event_time, event_type, phase, symbol, timeframe, cycle_id, trade_id, ticket)
- applies safe defaults:
  - close_* fields default to neutral values (blank/0) and deal_id defaults to 0
  - scale_* fields default to 0
  - action_summary defaults blank

Event producers then set only event-specific fields:
- action_summary
- scale_steps / scale_fraction_total
- close_* fields when applicable (CLOSE always; SCALE_OUT optionally when deal matched)


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


**Broker Evidence (E2 close fields):**
- MM_EVENT_SCALE_OUT MAY populate close_reason, close_price, close_profit, close_volume, deal_id
  when a broker partial-close deal is matched.
- If no matching deal is found, these fields remain neutral defaults.

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

## CLOSE

- Trigger Location:
  
  `CTradeEngine::UpdateCloseDetection(symbol)` detects transition (was open → now closed) and calls   `EmitCloseEvent(symbol)`.

- Handler:
  
  `CTradeEngine::EmitCloseEvent(symbol)` performs broker/deal matching using position lifecycle id (`POSITION_IDENTIFIER`) and emits MM_EVENT_CLOSE as the broker-confirmed lifecycle terminator.
   
- Logger Call:

  `m_logger.LogMMEventBase(evt)` after populating close_reason/close_price/close_profit/close_volume/deal_id.

**Notes**
- MM_EVENT_CLOSE is emitted only when closure is broker-confirmed (deal-derived).
- close_* and deal_id MUST be populated for CLOSE.

---
## 🔎 trade_id vs ticket (Current Implementation)
- `ticket` is the broker identifier.
- `trade_id` currently mirrors `ticket` as a placeholder mapping (assigned by InitMMEvent).
- cycle_id remains the primary lifecycle grouping key across ENTRY → ... → CLOSE.
