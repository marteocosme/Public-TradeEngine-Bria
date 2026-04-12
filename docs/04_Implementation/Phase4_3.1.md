**Event ID Generation Note**

A global monotonic event counter is currently used for logging convenience.
This value is not part of the behavioral contract and must not be relied upon
for replay determinism or lifecycle sequencing.
Future phases may replace this with producer‑supplied sequence identifiers.

That preserves:

- Historical correctness
- Design intent
- Reviewer trust


# Phase 4.3.1 – Unified Trade Logger Implementation
Status: ✅ Resolved and Approved (with constraints below)

Applies to: `libCUnifiedTradeLogger.mqh`

---
## 1. Purpose of Phase 4.3.1

Phase 4.3.1 covers the initial concrete implementation of the Unified Trade Logger, whose sole responsibility is to record trade and money‑management lifecycle events as defined in the Phase 3 Logging Contract.

This phase explicitly does not:

- Make trading decisions
- Calculate risk or R‑multiple
- Alter trade state
- Enforce ordering or causality
- The logger is strictly passive and event‑driven.

---
## 2. Scope and Responsibilities
### 2.1 What the Logger Owns

- Serialization of logging payloads (CSV / JSON)
- Mapping enums and fields to persistent records
- File IO safety (open / append / close)
- Capturing event snapshots exactly as supplied

### 2.2 What the Logger Does NOT Own

- Trade execution
- Money management logic
- Signal generation
- Stop‑loss / take‑profit logic
- Event sequencing or causal ordering
- All semantic meaning belongs to the event producer (EA / Engine).

--- 
## 3. Event Identity and Sequencing — Clarified
### 3.1 Global Event ID (s_globalEventId)
The current implementation includes a global monotonic counter:

```cpp
static ulong s_globalEventId;
```

with a single definition in the EA translation unit:
```cpp
ulong CUnifiedTradeLogger::s_globalEventId = 0;
```

✅ This implementation is technically correct from a linkage and lifecycle perspective:

- The value is initialized once per run
- It is shared across all logger instances
- It does not reset unintentionally

### 3.2 Architectural Constraint (Important)
Despite being technically valid, s_globalEventId is explicitly non‑contractual.

**Rules:**

- It is provided for debugging and human traceability only
- It must never be relied upon for: Trade lifecycle ordering
- Replay determinism
- Cross‑run comparison
- Analytics invariants

### 3.3 Source of Truth for Ordering
Authoritative ordering and identity must come from:

- `trade_id`
- `ENUM_MM_PHASE`
- Producer‑supplied event_seq (if applicable)

The logger records these values — it does not create them.
✅ This resolves earlier ambiguity about event ID ownership.


## 4. Event Model Alignment (Critical Resolution)
### 4.1 Single Event Vocabulary
The unified logger must speak only the Phase‑3 contract language.

✅ Authoritative event enums:

- `ENUM_MM_EVENT_TYPE`
- `ENUM_MM_PHASE`
- ❌ Deprecated / forbidden:
- Local or legacy `enum_tradeEvent`

All lifecycle semantics are defined in `libEnum.mqh` and referenced uniformly.

---

## 5. Base Logging Payload (Authoritative)
The canonical payload for money‑management logging is:

```cpp
struct MM_LogEventBase
{
    datetime            event_time;   // Observed event time (not TimeCurrent)
    ENUM_MM_EVENT_TYPE  event_type;   // Contract event
    ENUM_MM_PHASE       phase;        // Lifecycle phase
    string              symbol;
    ENUM_TIMEFRAMES     timeframe;
    long                trade_id;     // Deterministic internal ID
    ulong               ticket;       // Broker ticket (0 if N/A)
};
```

**Invariants:**

- Logger must not modify this payload
- Time is supplied by the producer
- Payload represents an immutable snapshot

---
## 6. Logger Entry Points — Resolved
### 6.1 Required MM Entry Point

```cpp
void LogMMEventBase(const MM_LogEventBase &evt);
```

- ✅ This is the single authoritative Money Management entry point
- ✅ All MM engines must call this function 
- ✅ This function routes internally to CSV / JSON serialization

Direct calls to low‑level CSV / JSON writers from engines are not allowed.

### 6.2 Signal Logging (Exception by Design)
Signal logging (SignalSnapshot) is explicitly allowed to remain separate:

- Signal events are pre‑trade
- They do not belong to the MM lifecycle
- They use a distinct schema intentionally
This separation is approved and intentional.

---
## 7. Timestamp Rule (Resolved)
❌ Forbidden:

- `TimeCurrent()` inside the logger to define event time

✅ Required:

- `event_time` must be supplied by the event producer

The logger records what happened when it happened, not when it was logged.


## 8. Phase 4.3.1 Outcome
- ✅ Logger responsibilities are correctly defined 
- ✅ Event ID ambiguity explicitly resolved 
- ✅ Contract alignment enforced 
- ✅ Replay safety preserved 
- ✅ No scope creep into MM or trading logic

**Phase 4.3.1 is now formally RESOLVED and LOCKED.**

---
## 9. Forward Notes (Non‑Blocking)

- Global event ID may be removed or replaced in future phases
- Analytics tooling must ignore global IDs
- Phase 4.4 will define integration points only
No further changes to Phase 4.3.1 are expected unless the Phase 3 contract changes.


**Note:**
Phase 4.3.x was used to align code with the above constraints. No additional behavioral changes were introduced.

