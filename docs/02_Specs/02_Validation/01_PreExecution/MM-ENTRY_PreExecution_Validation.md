
# Execution Engine – Entry Parameter Validation Rules

## 🔒 Document Status

Version: v1.0  
Status: ✅ ACTIVE  
Last Updated: 2026-05-04  

---

## 🎯 Purpose
Defines validation rules that must be satisfied BEFORE executing an ENTRY action. It formally defines entry parameter validation rules enforced by `CTradeExecution::ExecuteEntry()` to prevent invalid trade construction and to allow controlled, spec-compliant flexibility for exits.

These rules are mandatory, engine-level guardrails and apply to all strategies and signal sources using the Trade Execution Engine.

---

## ⚠️ Scope

- Occurs BEFORE OrderSend
- Component: `libCTradeExecution.mqh`
- Class: `CTradeExecution`
- Method: `ExecuteEntry()`
- Applies to: Market entries (BUY / SELL)
- Does NOT handle logging validation
- Is separate from MM-LOG-01 validation

## Design Principles

#### 1. Capital Protection First
- A trade must never be opened without a valid Stop Loss.

#### 2. Exit Flexibility
- Take Profit is optional and may be intentionally 
    - disabled to allow: Exit signal–based closes
    - Trailing stop management
    - Break-even logic
    - Partial close engines

#### 3. Fail Fast
- Invalid parameters must abort entry before any order request is sent.

---

## Parameter Validation Rules
### 1. slATRMultiplier (Stop Loss ATR Multiplier)

| Condition	| Behavior |
| --- | --- |
| `slATRMultiplier <= 0` | ❌ Entry is rejected (`ExecuteEntry()` returns `false`)| 
| `slATRMultiplier > 0` | ✅ Stop Loss is calculated and applied |

#### Rationale

- A zero or negative ATR multiplier collapses stop distance
- This can result in: 
    - Invalid price levels
    - Immediate stop-outs
    - Undefined broker behavior

    ✅ Stop Loss is mandatory for all entries


### 2. tpATRMultiplier (Take Profit ATR Multiplier)

| Condition | 	Behavior |
| --- | --- |
| `tpATRMultiplier == 0` | ✅ Take Profit disabled (no TP sent to broker) |
| `tpATRMultiplier > 0` |	✅ Take Profit is calculated and applied |

#### Rationale

- Allows trades to remain open until closed by:
    - Exit Signal Engine
    - Trailing Stop Engine
    - Break-Even Engine
    - Scaling / Partial Close Engine
- Enables NNFX-style runner positions

    ✅ TP is optional by design

---

## Execution Behavior Summary

| Parameter |	Mandatory | Zero Allowed |	Effect |
| --- | --- | --- | --- |
| `slATRMultiplier` | ✅ Yes |	❌ No | Entry rejected |
| `tpATRMultiplier` |	❌ No | ✅ Yes | TP disabled |

---

## Order Request Construction Rules

- Stop Loss (`request.sl`)
    - Always set
    - Derived from ATR × `slATRMultiplier`
- Take Profit (`request.tp`)
    - Set only if `tpATRMultiplier > 0`
    - Otherwise explicitly set to `0.0`

In MQL5, `tp = 0.0` is interpreted as no Take Profit.

---

## Logging Expectations
### Error Logging

- When `slATRMultiplier <= 0`
    - Severity: ERROR
    - Entry aborted

### Informational Logging

- When `tpATRMultiplier == 0`
    - Severity: INFO
    - Explicitly indicate TP is disabled and trade relies on exit management logic


### Non-Goals

- This validation does **not:**
    -  Enforce exit logic
    - Control trailing, BE, or partial close behavior
    - Override strategy-level decisions

Its sole responsibility is safe and valid trade construction.

---

## Status
✅ Approved – Mandatory Validation Rule

This document must remain synchronized with `CTradeExecution::ExecuteEntry()` implementation.
