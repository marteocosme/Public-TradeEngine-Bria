# ✅ Implementation Plan & Progress Management

 ⚠️ **Superseded Notice**  
> Money Management Phases MM‑01 to MM‑04 are structurally addressed via Phase 4 and Phase 5,  
> with remaining logging and validation obligations formally closed in  
> **ROADMAP_Implementation_Plan_and_Progress_v2.md**.

This document defines the incremental implementation plan for the NNFX TradeEngine project.

It also serves as a living progress tracker to ensure all changes are spec‑aligned, compile‑safe, and backtest‑validated.


## 1. Purpose
The purpose of this document is to:

- Provide a step‑by‑step implementation roadmap
- Enforce incremental, low‑risk patches
- Track implementation progress transparently
- Prevent scope creep and unsafe refactors
- Ensure continuous alignment between:

    - Specifications
    - Architecture
    - Code
    - Backtesting behavior

This document is operational, not conceptual.

## 2. Guiding Principles
All implementation work must follow these rules:

- ✅ Patches must be small and compile‑safe
- ✅ One functional concern per patch
- ✅ No architectural rewrites without spec change
- ✅ Each phase must be observable via logs
- ✅ Backtests are mandatory after each phase
- ✅ Later phases may not begin until earlier phases are validated


## 3. Current Project State
### Documentation

- ✅ Money Management Spec v1.1 — Locked
- ✅ Entry Strategy Spec v1.0 — Locked
- ✅ Architecture Docs — Locked

### Code

- ✅ Core NNFX modules exist
- ⚠️ Limited observability for Money Management
- ❌ Entry Strategy behavior not yet validated via logs


## 4. Implementation Phases (Authoritative Plan)
### 🔹 Phase MM‑01 — Risk Calculation Logging
**Goal**

Make initial risk and position sizing decisions fully observable.

**Scope**

- Money Management risk calculation only
- No trade execution changes

** Logging Requirements **

- Account capital used
- Risk percentage
- ATR value
- Stop loss distance
- Raw lot size
- Normalized lot size
- Trade allowed / rejected reason

**Status**

⬜ Not Started

**Validation Criteria**

- Logged values match spec math
- Identical setups produce identical results
- No compilation warnings or errors


### 🔹 Phase MM‑02 — Break Even Logging
**Goal**

Validate when and why break‑even is triggered.

**Scope**

- Break‑even logic only
- No scale‑out or exit logic

**Logging Requirements**

- Trade ID
- Trigger condition
- R multiple
- SL before / after adjustment

**Status**

⬜ Not Started

**Validation Criteria**

- BE triggers exactly at spec‑defined thresholds
- No repeated BE events
- No BE reversion


### 🔹 Phase MM‑03 — Scaling Out Logging
**Goal**

Validate partial close behavior and remaining exposure.

**Scope**


- Scaling‑out logic only

**Logging Requirements**

- Trade ID
- Scale level
- Lots before / closed / remaining
- R multiple at scale‑out

**Status**


⬜ Not Started

**Validation Criteria**

- Scale‑outs align with spec
- Broker constraints respected
- Remaining position remains valid


### 🔹 Phase MM‑04 — Exit Reason Logging
**Goal**

Ensure all trade exits are explainable and auditable.

**Scope**

Exit coordination logic only

**Logging Requirements**

- Trade ID
- Exit reason (SL / BE / Exit Signal / Force)
- Final R multiple
- Trade duration (candles)

**Status**

⬜ Not Started

**Validation Criteria**

- Exactly one terminal exit per trade
- Exit reason matches observed behavior


## 5. Backtesting & Validation Rules
After each phase:

- ✅ Run at least one backtest
- ✅ Inspect logs manually
- ✅ Confirm behavior against specs
- ✅ Fix issues before proceeding

No phase may be marked Complete until validated.

## 6. Entry Strategy Work Policy

- ❌ No Entry Strategy changes during MM‑01 → MM‑04
- ✅ Entry Strategy work resumes only after Money Management is validated
- ✅ Entry Strategy patches will follow a similar phased structure


## 7. Change Log

|Date | Change |
| --- | --- |
| 2026-04-11| Initial implementation plan created |


## 8. Ownership & Usage

- This document is authoritative
- Specs define what
- Architecture defines where
- This document defines how and when
- Code must follow all three


## 9. Working Model & Progress Control

This document is used as the authoritative progress tracker for implementation work.


All development follows this workflow:

1. Select the next unchecked phase in this document
2. Apply a single, compile-safe patch aligned with Specs and Architecture
3. Validate behavior via logs and backtesting
4. Mark the phase as complete before proceeding

No phase may be considered complete until its validation criteria are met.

This model ensures deterministic progress, prevents scope creep, and preserves backtesting integrity.