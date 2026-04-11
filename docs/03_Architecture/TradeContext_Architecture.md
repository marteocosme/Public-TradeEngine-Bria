## Purpose
The TradeContext is the immutable, per‑candle data structure that represents the complete decision state required to evaluate entry eligibility and trade management actions.

It acts as the single source of truth for strategy evaluation and logging.

## Responsibility
TradeContext is responsible for:

- Aggregating indicator states
- Capturing market conditions at a specific candle
- Providing read‑only inputs to decision engines
- Persisting decision snapshots for logging and replay

TradeContext does not perform decision logic itself.

## Lifecycle

1. Created once per closed candle
2. Populated with:
    - Indicator states
    - Volatility metrics
    - Temporal counters
3. Passed to:
    - Entry Strategy Engine
    - Money Management Engine
4. Logged once per candle
5. Discarded after evaluation

## Owned Data
TradeContext owns state, not behavior.
Typical contents include:

- Symbol & timeframe
- Candle timestamp
- Baseline state
- Confirmation states (C1, C2)
- Volume state
- ATR value
- Distance calculations
- Temporal counters (candles since signal)
- Derived flags (e.g., within ATR range)


## Design Constraints

- TradeContext is immutable after construction
- No module may mutate TradeContext
- All consumers treat TradeContext as read‑only
- A new TradeContext must be built for each candle


## Invariants

- One TradeContext per candle
- Identical market conditions must produce identical TradeContext
- TradeContext construction must be deterministic
- TradeContext does not persist across candles


## Rationale
This design enables:

- Backtest determinism
- Signal replay and auditability
- Debugging without hidden state
- Clear separation of data and decision logic