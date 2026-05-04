

## ⚠️ Status: SUPERSEDED

This document has been replaced by:

👉 Phase 5  Architecture - Trade Lifecycle Orchestrator_v1.2.md

Reason:
- Schema v1.2 alignment
- Execution outcome integration
- Lifecycle flow update


# 🏗️ Phase 5 Architecture — Trade Lifecycle Orchestrator

**Project:** Public-TradeEngine-Bria

**Phase:** 5 (Architecture)

**Status:** 📐 Architecture ✅ Approved

**Based On:** Phase 5 — Trade Lifecycle Orchestration Specification (✅ Approved)

---

## 📌 1. Architectural Objective
This document defines how the approved Phase 5 specification will be realized in the codebase **without changing Phase 4 behavior**.

The architecture introduces a **Trade Lifecycle Orchestrator** that governs trade state transitions, while existing engines (Entry, MM, Exit) remain focused on their single responsibilities.

---
## 🧠 2. Design Principles
The Phase 5 architecture adheres to the following principles:

- **Single Authority** — one component owns lifecycle state
- **Non‑Intrusive Integration** — Phase 4 engines remain intact
- **Compile‑Safe Evolution** — minimal, incremental changes
- **Request‑Based Interaction** — engines request actions, never assume state

---
## 🧩 3. Orchestrator Placement
### ✅ Selected Model: Embedded Orchestrator (Recommended)
The Trade Lifecycle Orchestrator will be embedded inside `CTradeEngine` as a dedicated internal component.

```
CTradeEngine
 ├─ Entry logic
 ├─ Money Management logic
 ├─ Exit logic
 └─ TradeLifecycleController   ← Phase 5 addition
```

### Rationale

- `CTradeEngine` already owns the trade execution flow
- Avoids introducing a global singleton
- Simplifies access to `TradeContext`
- Minimizes cross‑module coupling

---

## 🧱 4. TradeLifecycleController Responsibilities
The `TradeLifecycleController` is responsible for:

- Creating and owning `trade_id`
- Tracking lifecycle state per trade
- Validating requested actions against lifecycle rules
- Advancing lifecycle state explicitly
- Enforcing snapshot timing guarantees

It does not:

- Execute orders
- Compute indicators
- Apply Money Management logic

--- 

## 🔁 5. Engine Interaction Model
Engines interact with the orchestrator using a request/approve pattern.
### 5.1 Conceptual Flow

```
Engine → Request(Action)
        → Orchestrator validates lifecycle
        → Orchestrator approves / rejects
        → Engine proceeds or aborts
        → Logger records outcome
```

### 5.2 Engine Roles

|   | Engine | 	Interaction with Orchestrator |
| --- | --- | --- |
| 1 | Entry Engine |	Requests CREATE → ENTER |
| 2 | MM Engines |	Request MM actions (MANAGED only) |
| 3 | Exit Engine |	Requests EXIT |

Engines never mutate lifecycle state directly.

---

## 🆔 6. Trade ID Flow
### Creation

- `trade_id` is generated once during CREATE request approval
- Stored within `TradeContext`

### Propagation

- Passed implicitly via `TradeContext`
- Referenced by all log events

### Retirement

- Marked inactive when lifecycle reaches CLOSED

---

## 📸 7. Snapshot Enforcement Architecture
The orchestrator enforces snapshot guarantees by:

- Identifying lifecycle boundary crossings
- Requiring a populated `TradeContext` before approval
- Triggering snapshot logging after approved actions

The orchestrator does not inspect field values, only presence and timing.

---

## 🔄 8. Lifecycle State Storage
Lifecycle state will be stored:

- Per active trade
- Within `TradeLifecycleController`
- Indexed by `trade_id`

This avoids polluting engine logic with state bookkeeping.

---


## 🚨 9. Invalid Request Handling
If an engine submits an invalid request:

- Orchestrator rejects deterministically
- Rejection reason is returned
- Logger records rejection with context

No silent failures are allowed.

---


## 🔒 10. Phase 4 Protection Rules
This architecture explicitly guarantees:

- No changes to Phase 4 logging contracts
- No restructuring of existing engines
- No recalculation of MM values

Phase 5 wraps Phase 4 — it does not rewrite it.

---

## ✅ 11. Architecture Acceptance Criteria
This architecture is accepted when:

- Orchestrator can enforce lifecycle transitions
- Engines compile with minimal changes
- All lifecycle snapshots are guaranteed
- Phase 4 behavior remains unchanged

---

## ➡️ Next Step
#### Phase 5.2 — Interface & Method Design
Next, we define:

- Exact request types
- Method signatures
- Compile‑safe insertion points

📌 No implementation until interfaces are locked.
