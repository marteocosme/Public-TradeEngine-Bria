# How to Read This Repository
## Purpose of This Document
This repository follows a spec‑first, phase‑driven engineering approach.

It is not organized like a typical “EA + indicators” MQL5 project.

This document explains:

- How the repository is structured
- How to navigate specs, architecture, and implementation
- How to understand the current project state
- How to verify completed work safely

---
## What This Repository Is
This repository is a modular trading engine for MetaTrader 5, inspired by NNFX principles, with a strong focus on:

- Deterministic trade execution
- Explicit trade lifecycle control
- Money‑management‑first design
- Full logging and replay capability
- Incremental, compile‑safe development

The engine is designed to be *strategy‑agnostic*.
Entry logic, confirmations, filters, and exits are *plug‑ins*, not hard‑coded assumptions.

---
## What This Repository Is Not

- ❌ Not a ready‑to‑run EA for retail users
- ❌ Not a signal strategy or indicator pack
- ❌ Not optimized for live trading yet
- ❌ Not for commercial use without permission

This repo intentionally prioritizes correctness, traceability, and testability over speed or convenience.

---
## High‑Level Repository Structure

```
/docs
 ├── 00_Overview           ← How to navigate the project (this file)
 ├── 01_Algorithm          ← Trading logic & mathematical definitions
 ├── 02_Specs              ← Functional specifications (WHAT the system must do)
 ├── 03_Architecture       ← Design & structure (HOW it is built)
 ├── 04_Implementation     ← Step‑by‑step implementation plans
 ├── Phase-*-Completion.md ← Phase completion markers & validation notes

/Include
 ├── Core libraries (.mqh)
 ├── Execution, Context, Lifecycle, MM modules

/Experts
 ├── Main EA entry points (thin orchestration only)
```
## How This Repository Is Designed to Be Read
#### ⚠️ Do not start with code.
This repo is intentionally documentation‑driven.

### Recommended Reading Order


#### 1. Algorithm
- /docs/01_Algorithm
- Defines pure trading logic (NNFX rules, math, constraints)
- No implementation assumptions

#### 2. Specifications
- /docs/02_Specs
- Translates algorithms into formal system requirements
- Defines validations, responsibilities, and scope

#### 3. Architecture
- /docs/03_Architecture
- Explains class boundaries, data flow, contracts, and interfaces
- No step-by-step coding yet

#### 4. Implementation
- /docs/04_Implementation
- Incremental, compile‑safe implementation steps
- Each file represents work that actually happened

#### 5. Phase Completion Marker
- Phase-X-Completion.md
- Confirms that:
    - Scope is closed
    - Validation rules are enforced
    - Backtesting evidence exists

---

## The Role of Each Documentation Layer
### 01_Algorithm — Trading Truth
- Pure NNFX logic
- Mathematical definitions
- Platform‑agnostic
- Should change rarely

    _“Algorithms explain what trading logic is, not how it is coded.”_


### 02_Specs — System Contracts
- Converts algorithm into enforceable behavior
- Defines:
    - Inputs
    - Outputs
    - Validation rules
    - Failure cases

    Specs answer: **“What must this system guarantee?”**

### 03_Architecture — Structural Design
- Class responsibilities
- Execution flow
- Trade context ownership
- Lifecycle & logging contracts

    Architecture answers: **“Where does this logic live?”**

### 04_Implementation — Historical Execution
- Actual work done
- Ordered, incremental steps
- Compile‑safe changes only

#### Important:
- Files here are chronological
- Not all future phases are implemented yet
- A file existing ≠ full feature completed

---

## Understanding Phases
Each phase represents a closed engineering scope.

A phase is considered complete only when:
- A completion marker exists
- Validation is confirmed
- No implicit assumptions remain

Example:
```
Phase-5-Completion.md ✅
```
Anything after that is explicitly out of scope.

---

## How to Read the Code Safely
### Start Here

1. Read the latest Phase Completion Marker
2. Confirm what is officially implemented
3. Reference:
    - Lifecycle rules
    - Logging contracts
    - Interface design
4. Then review code

This avoids:
- Assuming future behavior
- Misreading scaffolding as final logic
- Breaking lifecycle guarantees

---

## Money Management & Lifecycle Philosophy
This engine treats money management as first‑class logic, not a side effect.

Key principles:

- Every trade has an explicit lifecycle
- Lifecycle transitions are validated
- Money management actions occur within lifecycle constraints
- Lifecycle transitions are validated


This makes:

- Strategy Tester behavior deterministic
- Trade logs replayable
- Bugs traceable to exact lifecycle events

---

## Logging, Validation, and Testing Philosophy
The engine assumes:

“If it wasn’t logged, it didn’t happen.”

Therefore:

- All critical actions emit logs
- Validation rules are explicit (e.g., ATR multiplier ≠ 0)
- Strategy Tester is the primary test harness
- Test expectations are documented in Phase Completion files


## Licensing & Usage Reminder
This project is licensed under the PolyForm Noncommercial License.

- ✅ Personal & educational use allowed
- ❌ Commercial use prohibited without permission
- See 
    - `LICENSE.md`
    - `COMMERCIAL-LICENSE.md`

If you are unsure whether your use is commercial, assume it is and request permission.

## Final Note
This repository is intentionally slow‑moving.

That is by design.

The goal is **long‑term correctness, auditability, and confidence**—not quick profits or flashy results.

✅ End of document