
# 🔌 Phase 5.2 — Trade Lifecycle Orchestrator Interface Design
**Project:** Public-TradeEngine-Bria

**Phase:** 5.2 (Interface Design)

**Status:** 📐 Interface ✅ Approved

**Depends On:**
- Phase 5 — Trade Lifecycle Orchestration Specification (✅ Approved)
- Phase 5 Architecture — Trade Lifecycle Orchestrator (✅ Approved)

---

## 📌 1. Purpose of Phase 5.2
This document defines the exact interfaces and interaction contracts between:

- Trade engines (Entry, Money Management, Exit)
- The Trade Lifecycle Orchestrator (`TradeLifecycleController`)

The goal is to **lock method signatures and responsibilities** before any implementation begins, ensuring:

- Compile-safe integration
- Zero ambiguity about ownership
- No behavioral changes to Phase 4 logic


## 🧠 2. Design Constraints
All interfaces defined here must:

- ✅ Preserve Phase 4 logging contracts
- ✅ Avoid refactoring existing engines
- ✅ Require minimal parameter additions
- ✅ Be request/response based (no side effects)

No interface defined here may:

- Mutate engine state directly
- Perform calculations
- Bypass lifecycle validation

---

## 🔁 3. Lifecycle Action Model
All interactions with the orchestrator are expressed as lifecycle actions.
### 3.1 Canonical Lifecycle Actions

| | Action |	Description |	Typical Caller |
| --- | --- | --- | --- |
| 1 | CREATE | 	Create trade intent and `trade_id` |	Entry Engine |
| 2 | ENTER |	Confirm successful entry execution |	Entry Engine |
| 3 | MM_ACTION	| Request Money Management operation |	MM Engines |
| 4 | EXIT |	Request trade exit	| Exit Engine |
| 5 | CLOSE |	Finalize lifecycle |	Trade Engine |

---

## 🧩 4. Core Orchestrator Interface
### 4.1 Conceptual Interface

```cpp
bool RequestAction(
    trade_id,
    LifecycleAction action,
    TradeContext& ctx,
    RejectionReason& reason
)
```

### Semantics

- Returns `true` if action is approved
- Returns `false` if action is rejected
- `trade_id` may be null/invalid only for CREATE
- `ctx` must be populated prior to request
- `reason` must be set on rejection

```
📌 This interface performs validation only, not execution.
```

---

## 🆔 5. Trade ID Handling by Interface
### CREATE

- Caller provides no `trade_id`
- Orchestrator generates and assigns `trade_id`
- `trade_id` is written back into `TradeContext`

### Non-CREATE Actions

- Caller must provide valid `trade_id`
- Orchestrator validates lifecycle eligibility

---

## 📸 6. Snapshot Enforcement Contract
Before approving an action, the orchestrator requires:

- `TradeContext` is present
- Snapshot-required lifecycle points are satisfied

The orchestrator:

- ✅ Enforces presence and timing
- ❌ Does not inspect numeric correctness

Snapshot logging is triggered after approval.

---

## 🚨 7. Rejection Handling Interface
### 7.1 RejectionReason (Conceptual)
Rejection reasons must be:

- Deterministic
- Loggable
- Non-exception based

Examples:

- INVALID_LIFECYCLE_STATE
- MISSING_TRADE_ID
- ACTION_NOT_ALLOWED
- LIFECYCLE_CLOSED

---

## 🔧 8. Engine Integration Points (Compile-Safe)
### Entry Flow

- Before entry execution → `RequestAction(CREATE)`
- After successful execution → `RequestAction(ENTER)`

### ManageOpenPosition()

- Before BE / scale-out / trail → RequestAction(MM_ACTION)
Exit Flow

- Before exit execution → `RequestAction(EXIT)`
- After exit completion → `RequestAction(CLOSE)`

Engines proceed only on approval.

---

# 🔒 9. Phase 4 Protection Rules (Reaffirmed)

- No change to existing engine logic
- No logging schema changes
- No MM algorithm changes

All Phase 5 logic is **additive and validating only.**

---

## ✅ 10. Interface Acceptance Criteria
This interface design is accepted when:

- All lifecycle transitions can be validated
- Engines compile with minimal signature changes
- Snapshot guarantees are enforceable
- No Phase 4 behavior changes

---

## ➡️ Next Step
**Phase 5.3 — Implementation Plan (Incremental & Compile-Safe)**

Next, we will:

- Sequence implementation steps
- Identify smallest safe commits
- Plan validation & rollback points

📌 No code until this interface is approved.
