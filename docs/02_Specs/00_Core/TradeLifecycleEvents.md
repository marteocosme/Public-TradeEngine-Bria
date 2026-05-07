
## 🔒 Document Status

**Version:** v1.1

**Status:** ✅ ACTIVE (SSOT)

**Last Updated:** 2026-05-07 (UTC+8)

---

## 🔗 Purpose

Defines all standardized lifecycle and MM event identifiers used across the system.

This file serves as the single source of truth for:

- Event naming
- Event definitions
- Cross-module consistency

## Supersedes
- v1.0

---

## 1. Canonical MM-LOG-01 Event Types (Enum-style)

These are the canonical **MM-LOG-01 event_type identifiers** used for event logs and snapshot intent/result mapping.  
They align with the MM-LOG-01 contract’s two-phase termination model:
- `MM_EVENT_EXIT` = engine intent to close (optional)
- `MM_EVENT_CLOSE` = broker-confirmed closure outcome (mandatory lifecycle terminator)

### Canonical Event Types
- MM_EVENT_ENTRY
- MM_EVENT_SCALE_OUT
- MM_EVENT_BE
- MM_EVENT_TRAIL
- MM_EVENT_EXIT      (Intent — engine close request)
- MM_EVENT_CLOSE     (Outcome — broker-confirmed closure)

> Note: `close_reason` is carried by the Event Log Schema (MM_Event_Log_Schema.md) for MM_EVENT_CLOSE.

---

## 2. Lifecycle Semantic Events (Legacy String IDs)

These legacy identifiers represent semantic lifecycle moments (validation, open confirmation, etc.).  
They remain useful as conceptual events, but **must not conflict** with canonical MM-LOG-01 event_type identifiers.

### Mapping Rule
If a legacy semantic event overlaps with a canonical MM-LOG-01 event, the canonical event type is the authoritative identifier.

---

## 3. Pre‑Trade Semantic Events (Legacy)

### ✅ MM_TradeValidated

**When**
- MM confirms that risk, SL distance, and lot sizing are valid

**Emitted by**
- Risk & Position Sizing Module

**Required Data**
- Symbol
- Intended entry price
- Stop‑loss distance
- Risk %
- Calculated lot size
- Validation result (pass/fail)

📌 If this event does not occur, the trade must not open.

### ❌ MM_TradeRejected
**When**

- Trade fails MM validation (invalid SL distance, lot < min, risk exceeded)

**Terminal**

- Yes (trade never existed)

**Required Data**

- Rejection reason (enum/string)
- Failed invariant

---
## 4. Trade Initialization Semantic Events (Legacy)

✅ MM_TradeOpened
**When**

Broker confirms trade is open and MM accepts responsibility

**Required Data**

- Ticket
- Entry price
- Initial SL
- Initial risk (currency + R)
- Lot size

✅ This event marks the true start of the MM lifecycle.

---
## 5. Active Management Semantic Events (Legacy)

### 🔁 MM_BreakEvenTriggered
**When**

- Profit threshold is met
- BE conditions satisfied
- BE not yet applied

**Rules**

- Emits once per trade
- Irreversible

**Required Data**

- Trigger condition (R / price / ATR)
- Old SL
- New SL
- Buffer amount (if any)


**Canonical Mapping**
- MM_BreakEvenTriggered → MM_EVENT_BE

### 🔁 MM_StopLossAdjusted
**When**

- Stop‑loss is modified for reasons other than BE
(e.g., trailing logic if/when enabled)

**Rules**

- Must never increase risk
- Must move in a favorable direction only

**Required Data**

- Adjustment reason
- Old SL
- New SL

📌 This keeps BE and trailing conceptually separate.

**Canonical Mapping**
- MM_StopLossAdjusted → MM_EVENT_TRAIL

### 🔁 MM_PartialCloseExecuted
**When**

- A scale‑out condition is met
- Partial close is executed successfully

**Rules**

- Finite
- Ordered
- Must respect lot constraints

**Required Data**

- Closed lot size
- Remaining lot size
- Scale‑out level / index
- Execution price

**Canonical Mapping**
- MM_PartialCloseExecuted → MM_EVENT_SCALE_OUT

---

## 6. Trade Termination Semantic Events (Legacy)

### ✅ MM_ExitSignalReceived
**When**

- Entry Strategy emits an exit signal
- MM acknowledges and prepares exit

**Required Data**

- Exit signal source
- Exit reason (enum)
- Market context snapshot (optional)

📌 Useful for diagnosing why an exit happened.

**Canonical Mapping**
- MM_ExitSignalReceived → MM_EVENT_EXIT (Intent)


### 🛑 MM_TradeClosed
**When**

- Trade is fully closed and confirmed by broker

**Terminal**

- Yes

**Required Data**

- Close price
- Close reason (SL / exit signal / final scale‑out)
- Total R result
- Total P/L

📌 This event ends all MM actions.

**Canonical Mapping**
- MM_TradeClosed → MM_EVENT_CLOSE (Outcome)

---

## 7. Safety & Exceptional Events (Legacy)

### ⚠️ MM_SafetyTriggered
**When**

- Any invariant is threatened or violated
- Emergency exit or halt required

**Examples**

- Risk breach
- Inconsistent trade state
- Broker rejection loop

**Terminal**

- Usually yes

---


## 8. Event Authority & Ownership Matrix (Normalized)

This matrix prevents responsibility leakage and clarifies ownership boundaries.

- MM_EVENT_* entries are canonical MM-LOG-01 events.
- Legacy semantic events are preserved but map to canonical events where applicable.

**Ownership Summary**
- Risk module owns validation decisions (TradeValidated/Rejected)
- MM engines own management actions (BE/TRAIL/SCALE_OUT)
- Strategy owns signal generation, not broker closure
- Broker/deal confirmation terminates lifecycle via MM_EVENT_CLOSE

---

## 9. Change Log

### v1.1
- Removed duplicate Document Status / Purpose blocks
- Introduced canonical MM-LOG-01 event_type identifiers (MM_EVENT_*), including two-phase termination:
  - MM_EVENT_EXIT (intent) and MM_EVENT_CLOSE (outcome)
- Reclassified prior names as legacy semantic events and added canonical mappings
- Normalized ownership/authority guidance for cross-module consistency

### v1.0
- Initial version

---
✅ End of TradeLifecycleEvents SSOT
