## Purpose
This document defines the end‑to‑end execution flow of the trading system per candle, ensuring consistent behavior across live trading, backtesting, and replay.

## High‑Level Flow
For each closed candle:

1. Market data update
2. TradeContext construction
3. Entry Strategy evaluation
4. Money Management evaluation (if entry allowed)
5. Trade execution and/or management
6. Unified logging


## Detailed Execution Sequence
```
OnNewClosedCandle():
  ctx = BuildTradeContext()
  
  entryAllowed = EntryStrategyEngine.Evaluate(ctx)
  
  IF entryAllowed:
      mmDecision = MoneyManagementEngine.EvaluateEntry(ctx)
      IF mmDecision.valid:
          ExecuteTrade()
  
  MoneyManagementEngine.ManageOpenTrades(ctx)
  
  Logger.Log(ctx)
  ```

## Separation of Phases
The system enforces strict phase separation:

| Phase | Responsibility |
| --- | --- |
| Context Build| Data aggregation |
| Strategy | Eligibility decision | 
| Money Management | Risk & lifecycle control| 
| Execution | Broker interaction |
| Logging | Observability |

No phase may leak responsibility into another.

## Backtesting Guarantees
This flow guarantees:

- Candle‑based determinism
- Replayable decisions
- Identical behavior in backtest vs live mode
- Full traceability from decision → execution


## Invariants

- Exactly one evaluation per closed candle
- No trade actions on partially formed candles
- All decisions are logged
- Execution follows strategy, not vice versa


## Rationale
This architecture is designed to:

- Eliminate hidden side effects
- Prevent logic duplication
- Make failures explainable
- Support future visualization (trade replay)