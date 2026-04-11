
# 📘 Entry Strategy Specification v1.0

## Purpose
The Entry Strategy module determines whether market conditions permit the opening of a new trade based on predefined NNFX entry rules.

Its sole responsibility is to evaluate trade eligibility.
It does not manage risk, position sizing, trade exits, or profit protection.

## Scope
This specification governs:

- Trade qualification logic
- Indicator agreement rules
- Temporal and distance‑based filters

It explicitly excludes:

- Money management
- Order execution
- Trade management after entry

## Evaluation Model

- Evaluated once per closed candle
- All conditions are evaluated using historical, closed‑bar data
- The result is deterministic per candle


## Inputs
### Indicator State Inputs

- Baseline indicator state
- Primary confirmation indicator state (C1)
- Secondary confirmation indicator state (C2)
- Volume indicator state (V1)

### Volatility & Distance Inputs

- ATR value
- ATR period and timeframe (defined externally)
- Price distance relative to baseline

### Temporal Inputs

- Number of candles since last indicator signal
- Candle index used for rule evaluation


## Core Components
### 1. Baseline Agreement Module
**Responsibility**

Determines directional bias and validates price position relative to the baseline.

**Behavioral Rules**
- Baseline direction must agree with trade direction
- Price must satisfy baseline proximity rules


### 2. Confirmation Module(s)
**Responsibility**

Validates momentum and trend agreement.

**Behavioral Rules**

- At least one primary confirmation must agree
- Secondary confirmation must not contradict
- Confirmation signals must obey candle‑based timing rules


### 3. Volume Filter Module
**Responsibility**

Filters trades lacking sufficient market participation.

**Behavioral Rules**

- Volume indicator must agree with trade direction
- Volume contradiction invalidates entry


### 4. Distance & Volatility Rules Module
**Responsibility**

Prevents entries in overextended or unstable conditions.

**Behavioral Rules**

- Price must be within defined ATR multiples of baseline
- Specific entry types may require price to be beyond ATR thresholds
- Distance rules are evaluated after indicator agreement


### 5. Temporal Rules Module
**Responsibility**
Constrains entry timing to maintain rule consistency.
Rules

- 7‑candle rule
- 1‑candle watch rule
- Entry opportunity expiration rules

Temporal violations result in entry rejection.

## Output
The Entry Strategy module produces a single output:

- **entryAllowed (boolean)**

    - true → trade may proceed to Money Management evaluation
    - false → trade must not be opened

No additional metadata or signals are produced.

## Invariants
The following rules must always hold:

- Entry decisions are deterministic per candle
- All conditions must be independently evaluable
- The same inputs must always produce the same output
- Entry Strategy must not:
    - Calculate lot size
    - Adjust risk
    - Manage trades post‑entry
- Entry Strategy does not override Money Management constraints


## Explicit Non‑Responsibilities
The Entry Strategy module does not:

- Manage stop losses
- Set break‑even logic
- Perform scaling out
- Close trades

These responsibilities belong to the Money Management system.

## Versioning Notes

v1.0 — Formalized NNFX entry qualification logic


