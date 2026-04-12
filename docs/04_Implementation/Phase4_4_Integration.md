
# Phase 4.4 – Unified Trade Logger Integration
Status: 🔓 In Progress (Integration Phase)

Depends on: Phase 4.3.1 (Resolved) + Phase 4.3.x (Code Alignment Complete)

---


## 1. Purpose of Phase 4.4
Phase 4.4 defines how and where the Unified Trade Logger is invoked by the rest of the trading system.
This phase answers a single question:

    Which components emit which logging events, and at what lifecycle boundaries?

Phase 4.4 is strictly about integration points. It does not introduce:

- New trading logic
- New money management rules
- Behavioral changes

---

## 2. Integration Principles (Locked)
The following rules apply system‑wide:

1. The logger is callee‑only
    - Engines call the logger
    - The logger never calls engines

2. Event producers own semantics
    - Engines determine what happened and when
    - The logger only records snapshots
3. One event = one log call
    - No batching inside engines
    - No deferred reconstruction inside the logger
4. All MM logging flows through ``LogMMEventBase()``
    - CSV / JSON writers are internal only

---
## 3. Canonical Integration Map
The table below defines exactly who logs what. This is the authoritative contract for Phase 4.4.
### 3.1 Signal Phase (Pre‑Trade)
**Producer:** Entry Strategy Engine

**Lifecycle:** Before any order placement

- Event Type: `SIGNAL`
- Payload: `SignalSnapshot`
- Logger Call:
    ```cpp
    CUnifiedTradeLogger::LogSignal(const SignalSnapshot &s);
    ```

    Notes:
    - Signal logging is intentionally separate from MM lifecycle
    - No `trade_id` or `ticket` exists yet


### 3.2 Entry Phase
**Producer:** Trade Execution / Entry Engine

**When to Log:** Immediately after a position is successfully opened

- `MM_LogEventBase.event_type = MM_EVT_ENTRY`
- `phase = MM_PHASE_ENTRY`
- `trade_id` assigned
- `ticket` known

**Call:**
```cpp
logger.LogMMEventBase(evt);
```

### 3.3 Risk Initialization Phase
**Producer:** Money Management Engine

**When to Log:** After SL / risk sizing is finalized and applied

- `event_type = MM_EVT_RISK`
- `phase = MM_PHASE_RISK`

This event represents the first fully defined trade state.


### 3.4 Break‑Even Phase
**Producer:** Money Management Engine

**When to Log:** When SL is moved to BE (once per trade unless reset by design)

- `event_type = MM_EVT_BE`
- `phase = MM_PHASE_MANAGE`


### 3.5 Trailing Stop Phase
**Producer:** Money Management Engine

**When to Log:** On each discrete trailing stop update

- `event_type = MM_EVT_TRAIL`
- `phase = MM_PHASE_MANAGE`

Important:

- Each trailing adjustment is a new event
- No aggregation inside logger


### 3.6 Scale‑Out Phase
**Producer:** Money Management Engine

**When to Log:** On every partial close

- `event_type = MM_EVT_SCALE_OUT`
- `phase = MM_PHASE_MANAGE`

Each scale‑out event must be logged independently.


### 3.7 Exit Phase
**Producer:** Trade Exit / Execution Engine

**When to Log:** Immediately after the final position close

- `event_type = MM_EVT_EXIT`
- `phase = MM_PHASE_EXIT`

This is the terminal lifecycle event for a trade.

---

## 4. Event Timing Rules (Enforced)

- `event_time` is supplied by the producer
- Use the bar or tick time that triggered the event
- Do not use `TimeCurrent()` for semantic events

---

## 5. trade_id and Ticket Ownership

- `trade_id` is assigned once, at entry
- It remains stable across the entire lifecycle
- Broker `ticket` may change (split fills, partials) but `trade_id` must not

---

## 6. Error Handling and Edge Cases

- If logging fails, trading logic must not be blocked
- Logger errors are non‑fatal
- Missing logging must never alter EA behavior

---
## 7. What Phase 4.4 Does NOT Do
- ❌ Does not define payload enrichment
- ❌ Does not define analytics schemas
- ❌ Does not define replay visualization

Those belong to future phases (Phase 5+).

---

## 8. Phase 4.4 Exit Criteria
Phase 4.4 is considered complete when:

- All engines call the logger at the boundaries defined above
- No engine writes directly to files
- Logger dependency direction is one‑way only
- Backtests produce complete, ordered lifecycle logs

---

## 9. Next Phase Preview
Phase 5 – Money Management Behavioral Validation will:

- Replay trade logs
- Validate MM behavior against specs
- Enable analytics pipelines
No further logger design changes are expected.
