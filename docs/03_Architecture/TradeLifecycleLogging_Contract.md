> ⚠️ **DRAFT — NOT YET APPROVED**
> This document defines the proposed logging contract for Money Management lifecycle events.  
> It is under review and **must not be used as an implementation contract** until explicitly approved.

✅ APPROVED — Logging Contract v1.0
Effective immediately for all Money Management lifecycle 

---

# 📘 Trade Lifecycle Logging Contract — Phase 3 (Draft)

## 1. Purpose

This document defines the **logging contract** for all Money Management (MM) trade lifecycle events approved in **Phase 2**.

Its purpose is to ensure that:

- Every Money Management action is observable
- Backtest behavior is explainable and reproducible
- Trade behavior can be audited, replayed, and analyzed
- Logging remains deterministic, append-only, and execution-safe

This contract governs **what must be logged and when**, not how logs are stored or consumed.

---

## 2. Scope

This contract applies to:

- All Money Management lifecycle events
- All backtest and forward-test executions
- All environments (strategy tester, demo, live)

It does **not** define:

- Entry strategy logic
- Indicator calculations
- Broker execution mechanics
- Analytics or reporting logic

---

## 3. Core Logging Principles (Hard Rules)

The logging system **must** obey the following rules at all times:

1. **One Event → One Log Record**  
   Every lifecycle event emits exactly one log entry.

2. **Append-Only**  
   Logged records must never be modified or deleted.

3. **Deterministic & Idempotent**  
   The same event occurring on the same candle/tick must produce an identical payload.

4. **Backtest-Safe**  
   Logging must not depend on:
   - Wall-clock time
   - UI state
   - External systems

5. **Execution-Agnostic**  
   Logs record *intent and outcome*, not broker-specific side effects.

Violation of any rule above is considered an **engineering defect**.

---

## 4. Base Event Schema (Required for All Events)

Every logged event **must** include the following base fields:

```
   event_time        // Strategy bar or tick time
   event_type        // Lifecycle event identifier (e.g., MM_BreakEvenTriggered)
   symbol            // Trading symbol
   timeframe         // Strategy timeframe
   trade_id          // Internal trade identifier
   ticket            // Broker ticket (NULL if not yet available)
   phase             // PreTrade | Init | Active | Terminal | Safety
```

These fields establish:
- Temporal ordering
- Trade grouping
- Lifecycle phase boundaries


## 5. Event Identity & Idempotency
Each log entry is uniquely identified by:

```
(event_type, trade_id, event_time)
```

Rules:

- Duplicate events on the same candle/tick must not produce duplicate records
- Legitimate re-occurrence on later candles produces a new log entry

 This enforces the Money Management invariant:

    Trade management decisions must be idempotent per candle/tick.


## 6. Per-Event Payload Schemas
The following fields are mandatory per event unless stated otherwise.


### 6.1 MM_TradeValidated
**Phase:** PreTrade
```
risk_percent
sl_distance
calculated_lot
risk_amount
validation_result     // PASS | FAIL
```


If validation fails:
```
rejection_reason
failed_invariant
```



### 6.2 MM_TradeRejected (Terminal)
**Phase:** PreTrade
```
rejection_reason
failed_invariant
risk_percent
sl_distance
```

### 6.3 MM_TradeOpened
**Phase:** Init
```entry_price
initial_sl
initial_lot
initial_risk_amount
initial_risk_R
```

This event establishes the baseline trade snapshot.


### 6.4 MM_BreakEvenTriggered
**Phase:** Active
```
trigger_type          // R | PRICE | ATR
trigger_value
old_sl
new_sl
buffer_applied        // 0 if none
```

Rules:

- Must occur at most once per trade
- Must never increase risk


### 6.5 MM_StopLossAdjusted
**Phase:** Active
```
adjustment_reason     // TRAIL | STRUCTURE | OTHER
old_sl
new_sl
```

This event must not be used for break-even logic.


### 6.6 MM_PartialCloseExecuted
**Phase:** Active
```
execution_price
closed_lot
remaining_lot
scale_index           // 1, 2, 3, ...
```



### 6.7 MM_ExitSignalReceived
**Phase:** Active
```
exit_source           // EntryStrategy | Safety | Other
exit_reason
```

This event represents acknowledged exit intent, not execution.


### 6.8 MM_TradeClosed (Terminal)
**Phase:** Terminal
```
close_price
close_reason          // SL | EXIT_SIGNAL | FINAL_SCALE
total_profit
total_R
```

No further lifecycle events are permitted after this event.


### 6.9 MM_SafetyTriggered
**Phase:** Safety
```
safety_reason
affected_module
forced_action         // EXIT | HALT | IGNORE
```


This event is terminal in most cases.


## 7. Logging Output Formats
The logging system may emit one or both of the following:
### CSV

- Flat structure
- One row per event
- Optimized for Excel / Power BI

### JSON (newline-delimited)

- One JSON object per event
- Full payload retention
- Suitable for parsers and replay tools
- Both formats must retain identical semantic meaning.


## 8. Logging Invariants
The following invariants apply to all logging behavior:

- No Money Management action may occur without a corresponding log event
- Logging must never trigger or alter trading logic
- Terminal events forbid subsequent lifecycle events
- Missing broker data must be logged as NULL, not omitted


## 9. Approval Status
✅ APPROVED — Logging Contract v1.0

This document is now a binding contract for Money Management logging.


