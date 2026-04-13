
# 📘 Phase 4.1 — Logger Mapping Review

> ✅ Status: COMPLETED  
> ✅ Precondition: Phase 3 Logging Contract APPROVED  
> ✅ Scope: Mapping & alignment only (no code changes)


## 1. Purpose

This document records the **mapping and alignment decisions** between the **approved Phase 3 Trade Lifecycle Logging Contract** and the existing implementation of:
Include/MyInclude/NNFX/libCUnifiedTradeLogger.h

The goal of Phase 4.1 is to:
- Identify gaps between the logging contract and current code
- Explicitly document what must be added, renamed, or introduced
- Prevent ambiguity before Phase 4.2 (implementation)

This document is **not a specification** and **does not introduce new behavior**.

---

## 2. Files Reviewed

- `libCUnifiedTradeLogger.h`
- `libEnum.mqh` (for existing enums referenced by the logger)

---
## 3. Phase 3 Base Field Mapping

### 3.1 Required Base Fields (from Phase 3 Contract)

| Contract Field | Present | Status | Notes |
|---------------|--------|--------|------|
| `event_time` | ✅ | 🟡 | Uses `TimeCurrent()`; must switch to strategy bar/tick time |
| `event_type` | ✅ | 🟡 | Uses `enum_tradeEvent`; not compatible with MM lifecycle events |
| `symbol` | ✅ | ✅ | Already logged |
| `timeframe` | ❌ | ❌ | Not present in logger |
| `trade_id` | ❌ | ❌ | No internal trade identifier exists |
| `ticket` | ✅ | ✅ | Already logged |
| `phase` | ❌ | ❌ | No lifecycle phase concept exists |

---

## 4. Enum Alignment Decisions

### 4.1 Existing Enum (Not Reused for MM)

```cpp
enum enum_tradeEvent
{
  EVT_SIGNAL,
  EVT_ENTRY,
  EVT_RISK,
  EVT_BE,
  EVT_TRAIL,
  EVT_SCALE,
  EVT_EXIT,
  EVT_SUMMARY
};

```
Decision:

enum_tradeEvent is NOT reused for Money Management lifecycle logging
It represents high‑level semantic categories, not lifecycle events

---

### 4.2 New Enums Required (Phase 4.2)
The following enums will be introduced to comply with Phase 3:


```cpp
enum ENUM_MM_EVENT_TYPE
{
  MM_TradeValidated,
  MM_TradeRejected,
  MM_TradeOpened,
  MM_BreakEvenTriggered,
  MM_StopLossAdjusted,
  MM_PartialCloseExecuted,
  MM_ExitSignalReceived,
  MM_TradeClosed,
  MM_SafetyTriggered
};
```
```cpp
enum ENUM_MM_PHASE
{
  MM_PreTrade,
  MM_Init,
  MM_Active,
  MM_Terminal,
  MM_Safety
};

```
---
## 5. Trade Identity Decision
### 5.1 Required by Contract

| Identifier | Meaning |
| --- | --- |
| trade_id | Internal, deterministic, never reused | 
| ticket | Broker‑assigned, may be unavailable pre‑open |
---

### 5.2 Current State

- ✅ ticket exists
- ❌ trade_id does not exist
- ❌ eventSeq and event_id are not valid substitutes

**Decision:**

- trade_id will be introduced (likely sourced from TradeContext)
- event_id remains a logging sequence identifier only

---

## 6. Time Source Alignment
###Current Behavior

- Uses TimeCurrent() for event timestamps

## Contract Requirement

- Must use strategy bar or tick time

**Decision:**

- Logger will accept event_time as an explicit input
- Logger will not call TimeCurrent() internally for MM events

---

## 7. Logger Responsibility Boundary
### Confirmed Allowed Responsibilities

- CSV writing
- JSON writing
- Event sequencing
- File management

### Explicit Non‑Responsibilities

- Risk calculations
- Strategy decisions
- Entry/exit logic
- MM rule evaluation

**Decision:**

- CUnifiedTradeLogger remains a passive sink
- MM‑specific logging will be exposed via MM‑specific log methods
- Existing SIGNAL logging remains intact and unaffected

---

## 8. Non‑Goals (Explicit)
The following are out of scope for Phase 4.1 and Phase 4.2:

- ❌ Behavioral changes to Money Management
- ❌ Refactoring existing signal logging
- ❌ Removal of existing CSV/JSON outputs
- ❌ Analytics or reporting logic
- ❌ Backtest logic changes


## 9. Phase 4.1 Completion Statement

✅ All gaps between Phase 3 Logging Contract and existing logger have been identified

✅ Required enums, fields, and concepts are explicitly documented

✅ No ambiguity remains before implementation

Phase 4.1 is formally CLOSED.

---
### 10. Next Phase
➡️ Phase 4.2 — Base Logger Structs & Enums
This phase will:

- Introduce new enums
- Introduce base MM log structures
- Remain compile‑safe and behavior‑neutral