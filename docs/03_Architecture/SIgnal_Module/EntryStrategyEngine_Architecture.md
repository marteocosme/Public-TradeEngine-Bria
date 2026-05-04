
## ⚠️ Status: RESERVED FOR SIGNAL MODULE

This document is NOT part of the current execution architecture.

---

## 📌 Purpose (Reclassified)

This document defines the Entry Strategy Engine, responsible for:

- Generating trade entry signals
- Evaluating indicators and conditions
- Producing signal outputs for lifecycle consumption

---

## 🚧 Current Status

This component is NOT currently implemented in the system.

The system currently operates using:

- Trade Lifecycle Orchestrator (v1.2)
- Money Management (MM) modules
- Snapshot-based execution

---

## ✅ Future Use

This document will be used in:

👉 Phase 6+ — Signal Engine Implementation

---

## 🔗 Future Integration Flow

Signal Engine
    ↓
Lifecycle Controller
    ↓
MM Modules
    ↓
Execution Layer

## Purpose
The Entry Strategy Engine evaluates whether a trade is eligible for entry based on the Entry Strategy Specification v1.0.

It consumes a TradeContext and produces a single boolean outcome.

## Responsibility
The Entry Strategy Engine is responsible for:

- Evaluating NNFX entry rules
- Enforcing gate‑based decision order
- Applying temporal and distance filters
- Producing the entryAllowed decision

It does not manage trades or risk.

## Inputs

- A fully constructed TradeContext
- Static configuration parameters (initialized at EA start)


## Output

- entryAllowed (boolean)

No additional metadata, signals, or scores are produced.

## Internal Structure
The Entry Strategy Engine is logically composed of ordered evaluators:

1. Baseline Agreement Evaluator
2. Confirmation Evaluator(s)
3. Volume Filter Evaluator
4. Distance & ATR Rules Evaluator
5. Temporal Rules Evaluator

Each evaluator:

- Receives TradeContext
- Returns pass/fail
- Cannot override previous failures


## Evaluation Flow

    IF Baseline fails → reject
    IF Confirmation fails → reject
    IF Volume fails → reject
    IF Distance rules fail → reject
    IF Temporal rules fail → reject
    ELSE → entryAllowed = true
This order is fixed and deterministic.

## Design Constraints

- Evaluated once per closed candle
- No persistent state stored between candles
- No evaluator may modify TradeContext
- Evaluation order must not be altered


## Invariants

- Same TradeContext → same decision
- Entry Strategy cannot bypass Money Management
- Entry Strategy cannot open or close trades


## Rationale
This architecture ensures:

- Clear traceability between rules and outcomes
- Easy rule enable/disable for testing
- Modular extension without behavioral drift
- Faithful implementation of NNFX principles