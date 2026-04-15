# Project Goals and Non‑Goals
## Purpose of This Document
This document defines the true priorities, boundaries, and engineering intent of the TradeEngine‑Bria project.

It exists to:

- Preserve decision‑making context
- Keep development aligned with real goals
- Prevent mis‑prioritization or scope drift
- Serve as an authoritative reference for future phases

If there is ever a conflict between speed and intent, this document defines the correct direction.

---

## Primary Goal (Updated & Explicit)

**Deliver a production‑ready MT5 Expert Advisor as soon as safely possible, with Money Management correctness as the first and highest‑priority milestone, verified through backtesting and forward testing using deterministic logs.**

This EA is built to go to production, not to remain an academic or exploratory system.

## Secondary (Supporting) Goal

Build sufficient determinism, validation, and logging to trust backtest and forward‑test results — especially for Money Management behavior.

Engineering discipline exists to accelerate safe production, not to delay it.

---

## Core Development Priorities (In Order)
### 1. Money Management First (Highest Priority)
Money Management is treated as the most critical algorithm in the system.

- MM can make or break any trading system
- Entry strategies are meaningless without correct MM
- MM must be proven before strategy work continues

#### Required capabilities:

- Deterministic MM behavior
- Lifecycle‑bound MM actions
- Full MM logging (events + state snapshots)
- Backtest & forward‑test validation via logs

No entry strategy work proceeds until MM behavior is trusted.

### 2. Log‑Driven Backtesting & Forward Testing
Logs are not diagnostic artifacts — they are core validation tools.
The system must support:

- Reconstructing MM decisions from logs alone
- Verifying correctness of calculations and values
- Comparing expected vs actual MM behavior
- Identifying edge cases through replay

If MM behavior cannot be trusted through logs, it is not production‑ready.


### 3. Incremental, Compile‑Safe Delivery
All work must be:

- Incremental
- Compile‑safe
- Testable at each step

This ensures:

- Rapid iteration without destabilizing the EA
- Continuous backtesting during development
- Fast feedback loops toward production readiness

Large refactors or speculative changes are explicitly avoided.

### 4. Production Readiness Over Elegance
When forced to choose:

- ✅ Working, testable behavior
- ❌ Perfect architecture but delayed delivery

The project prioritizes validated behavior.

Engineering rigor exists to support speed with safety, not to block progress.

### 5. Trade Entry Strategies Come Later (Intentionally)
Entry logic is not the current focus.

Entry strategies will be worked on only after:

- MM behavior is validated
- Logs prove correctness
- Forward tests match expectations

This avoids false confidence and wasted optimization.

---
## What This Project Is

- ✅ A production‑oriented EA under disciplined development
- ✅ A Money‑Management‑first trading system
- ✅ A log‑driven validation framework
- ✅ A system designed to be backtested and forward tested reliably
- ✅ An engine that can safely accept strategies once MM is proven

---

## Explicit Non‑Goals (At This Stage)
These are deliberately deprioritized, not rejected forever.
### ❌ Strategy Optimization First

- No indicator tweaking
- No curve fitting
- No signal experimentation until MM is stable


### ❌ Premature Feature Expansion

- No UI panels
- No dashboards
- No QoL features unrelated to validation


### ❌ Architectural Purity at the Cost of Progress

- No large rewrites without validation benefit
- No abstraction for its own sake
- No speculative frameworks

---
## Guiding Engineering Principles (Refined)

1. Money Management correctness precedes everything
2. If MM behavior isn’t logged, it isn’t trusted
3. If logs can’t explain it, it’s not production‑ready
4. Incremental progress beats perfect design
5. Entries are worthless without proven MM

---

## Relationship to Other Documents
This document should be read alongside:

- Current_Project_State.md
- Roadmap v2
- Phase completion markers
- Logging contracts and validation specs

In case of conflict:

**Production‑ready MM validation takes precedence.**

---

## Stability Notice
This document may evolve only if production priorities change.

It is expected to remain stable through:

- Phase 6 (Logging & Validation)
- MM‑focused testing and tuning

--- 
## Final Statement
This project exists to achieve one concrete outcome:

**A production‑ready EA whose Money Management behavior is trusted, validated, and provable through logs — before anything else.**

Everything else waits its turn.

---

✅ End of document