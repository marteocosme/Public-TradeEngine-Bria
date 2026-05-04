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

#### Logging Requirement

This action MUST be logged with:

- previous_stoploss (before change)
- new_stoploss (after change)
- action_executed (true/false)
- execution_reason (if not executed)

### 3. Trailing Stop (TRAIL)

#### Objective

To dynamically lock in profits as price moves in favor of the position, while allowing the trade to continue capturing trend movement.

#### Trigger Condition

Trailing stop is evaluated when:

- Price has moved sufficiently in profit (based on ATR threshold)
- Break-even has already been applied (if required by system logic)
- Trailing conditions meet defined ATR-based rules

#### Behavior

- The stop loss is adjusted incrementally based on ATR movement
- Stop loss MUST only move in the direction of profit
- Stop loss MUST NOT move backward

#### Constraints

- Trailing stop must NOT be applied before break-even (if BE dependency enforced)
- Trailing must not override a better existing SL
- Trailing must not reduce locked-in profit

#### Logging Requirement

This action MUST be logged according to MM-LOG-01:

- action_executed (true/false)
- previous_stoploss (before modification)
- new_stoploss (after modification)
- execution_reason (if not executed)

Logs must conform to:

→ MM_Snapshot_Schema_v1.2.md

#### Parameters

- inpTrailStartATR → threshold before trailing activates
- inpTrailATR → trailing step distance

### 4. Scaling Out (Partial Close) Module
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

#### Logging Requirement

This action MUST be logged with:

- action_executed (true/false)
- closed_lots (volume reduced)
- execution_reason (if not executed)


### 5. Exit Management Module
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


## Logging and Observability Requirements

All Money Management actions MUST comply with MM-LOG-01 logging contract.

For every MM action (ENTRY, SCALE_OUT, BREAK-EVEN, TRAILING, EXIT):

The system MUST emit:

1. BEFORE snapshot  
2. Execution Outcome  
3. AFTER snapshot  

These must conform to:

→ MM_Snapshot_Schema_v1.2.md

---

### Execution Outcome Requirements

Each MM action MUST define:

- Whether the action was executed
- The resulting change applied
- The reason if not executed

Examples:

- SCALE_OUT → closed_lots
- BREAK-EVEN → previous_stoploss → new_stoploss
- TRAILING → previous_stoploss → new_stoploss


## Traceability Requirement

All MM operations MUST be fully traceable.

This requires:

- State BEFORE action  
- Action Outcome  
- State AFTER action  

These three components MUST be sufficient to reconstruct:

- Position state changes
- Risk exposure changes
- Stop-loss behavior


## Non-Functional Requirement — Logging Integrity

The MM system MUST ensure:

- No silent failures in execution
- All decisions are logged
- All logs are schema-compliant
- Logging errors are detectable at runtime


## Logging Contract Reference

This specification integrates with:

- MM-LOG-01_Logging_Schema_Contract.md
- MM_Snapshot_Schema_v1.2.md

Any MM behavior MUST produce logs compliant with these contracts.


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


## Terminology Alignment (Schema Integration)

To ensure consistency between Money Management logic and logging schema (MM-LOG-01), the following standardized terms are used in implementation and logs.

This specification may describe concepts in general terms, while the logging system uses canonical field names defined in:

→ MM_Snapshot_Schema_v1.2.md

### 

| Concept | Schema Field | Description |
|--------|-------------|------------|
| Position Size | current_position_lots | Actual position volume at snapshot time |
| Risk Exposure | current_risk_exposure | ENTRY-anchored risk value used for MM |
| Stop Loss Modification | previous_stoploss → new_stoploss | SL change applied during BE or TRAIL |
| Scale-Out Volume | closed_lots | Volume reduced during scaling |

### Notes

- The Money Management logic defines behavior, while the schema defines how results are recorded.
- All logging MUST use schema-defined field names.
- No alternate naming is allowed in logs.


## Versioning Notes
- v1.0 — Initial risk and sizing definition
- v1.1 — Added Break Even, Scaling Out, and Exit Management formalization
    - UPDATE 05/04/2026
        - Update 1 — ADD LOGGING REQUIREMENT SECTION
        - Update 2 — ADD TRACEABILITY REQUIREMENT
        - Update 3 — ADD SPEC ↔ LOG LINK
        - Update 4 — ADD Terminology Alignment (Schema Integration) & Standardized Terms
        - Update 5 — ADD NON-FUNCTIONAL REQUIREMENT
        - Update 6 — ADD TRAIL Section under the Core Modules.

