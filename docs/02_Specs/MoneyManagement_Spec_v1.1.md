# **📘 NNFX Money Management Specification v1.1**

## Purpose

The Money Management module defines how trade risk, position sizing, trade protection, and position unwinding are managed after a trade has been approved for entry.

Its objective is to ensure:
- Controlled downside risk
- Systematic profit protection
- Deterministic position management logic

This specification governs how a trade is managed over its lifecycle, not when a trade is entered.

## Scope
This specification covers:
- Initial risk and position sizing
- Break-even management
- Scaling out (partial profit taking)
- Exit coordination and final liquidation

It explicitly does not define entry signals or market bias.

## Inputs

The Money Management system consumes the following inputs:
### Account & Symbol Inputs
- Account balance or equity (configurable)
- Symbol specifications:
    - Tick size
    - Tick value
    - Minimum lot size
    - Maximum lot size
    - Lot step

### Risk Configuration
- Risk percentage per trade (e.g., 2%)
- Maximum allowed concurrent risk
- Risk allocation across multiple positions (if applicable)

 ### Volatility & Distance Inputs
- ATR value
- ATR period and timeframe (defined externally)
- Stop‑loss distance expressed in ATR multiples or price points

### Trade State Inputs
- Entry price
- Current price
- Current unrealized profit in R and/or price units
- Active position set (one or more orders)

### Exit & Management Signals
- Strategy‑provided exit signals (directional or neutral)
- Internal state flags (e.g., break‑even reached, scale‑out completed)

## Outputs

The Money Management module produces the following outputs:

### Initial Trade Outputs
- Normalized lot size
- Initial stop‑loss level
- Risked amount (absolute currency value)
- Trade validity flag

### Ongoing Management Outputs
- Break‑even stop‑loss adjustments
- Partial close (scale‑out) instructions
- Trailing or adjusted stop‑loss levels
- Final exit instruction

These outputs are consumed exclusively by the trade execution layer.

## Core Modules
### 1. Risk & Position Sizing Module
**Responsibility**

Determines the allowable position size based on:
- Configured risk percentage
- Stop‑loss distance
- Symbol constraints

**Notes**
- Executed once at trade initialization
- Independent of trade direction or strategy type


### 2. Break Even Module
**Responsibility**

Protects capital by removing downside risk once predefined profit conditions are met.

**Behavioral Rules**

Break even may only activate after a predefined initial profit threshold is reached (expressed in R-multiple or price distance). 

Stop‑loss is moved to:

Entry price, or
Entry price plus an optional buffer (configurable)


Once triggered, break even must not be reverted

**Intent** Capital preservation and emotional risk reduction.

### 3. Scaling Out (Partial Close) Module
**Responsibility**

Manages partial profit realization while allowing a portion of the trade to continue.

**Behavioral Rules**
- Scaling out is based on predefined R‑multiples or price levels
- Each scale‑out operation:
    - Reduces position size
- Scale‑out events are finite and ordered

**Constraints**
- Scaling out must not violate minimum lot constraints
- Remaining position must remain valid and manageable


### 4. Exit Management Module
**Responsibility**

Determines when and how an open trade is fully closed.

**Exit Triggers**
- Strategy‑provided exit signal
- Stop‑loss hit (initial, break‑even, or trailed)
- Final scale‑out completion
- Risk invalidation or safety condition

**Behavioral Rules**
- Exit management has final authority over trade termination
- Once an exit is issued, no further management actions are allowed


## Invariants
The following rules must always hold true:
- Risked capital must never exceed configured limits
- Lot sizes must comply with broker constraints at all times
- A trade with invalid stop‑loss distance must be rejected
- Break‑even, scaling‑out, and exit logic must be deterministic
- Trade management decisions must be idempotent per candle/tick
- Money Management must not generate entry signals
- Exit decisions are terminal and irreversible

These invariants ensure safety, auditability, and repeatable backtesting results.

## Explicit Non‑Responsibilities
The Money Management module does not:
- Decide market direction
- Evaluate entry conditions
- Select indicators
- Interpret indicator values

Those responsibilities belong to the Entry Strategy system.

## Versioning Notes
- v1.0 — Initial risk and sizing definition
- v1.1 — Added Break Even, Scaling Out, and Exit Management formalization

