
# 📘 Phase 5 — Trade Lifecycle Orchestration Specification
**Project:** Public-TradeEngine-Bria

**Phase:** 5 (Trade Lifecycle Orchestration)

**Status:** ✅ Spec Approved (Implementation Pending)

**Depends On:** Phase 4 — Execution & Money Management Logging (✅ Complete)

---

## 📌 1. Purpose of Phase 5
Phase 5 introduces a single authoritative orchestration layer responsible for governing the entire lifecycle of a trade.
While Phase 4 ensured that all execution and Money Management actions are observable and logged, Phase 5 ensures that these actions are:

- Deterministic
- Valid within the trade lifecycle
- Coordinated under one controlling authority
### Problem Being Solved
Prior phases exposed the following systemic risks:

- Ambiguous ownership of `trade_id`
- Engines implicitly advancing trade state
- Money Management actions executing without lifecycle validation
- Difficulty answering: _“Where exactly is this trade in its life?”_

Phase 5 resolves these issues by **separating orchestration from execution.**

---

## 🎯 2. Phase 5 Goals
At the end of Phase 5:

- ✅ Every trade has exactly one lifecycle owner
- ✅ Trade state transitions are explicit and validated
- ✅ Engines act only within approved lifecycle windows
- ✅ Trade replay is deterministic and auditable

---

## 🔁 3. Trade Lifecycle Model
### 3.1 Conceptual Lifecycle States
A trade progresses through the following logical lifecycle states:

#### 1. CREATED
- Trade intent exists
- `trade_id` is created
- No market exposure yet
#### 2. ENTERED
- Entry execution succeeded
- Position exists in the market
####  3. MANAGED
- Trade is eligible for Money Management actions
- BE, Scale-Out, Trailing Stop engines may act
#### 4. EXITED
- Exit execution has occurred
- Position is being closed or is fully closed
#### 5. CLOSED
- Trade lifecycle is complete
- No further actions or events are permitted

⚠️ These are lifecycle states, not logging phases.

--- 


## 🧠 4. Phase vs Lifecycle vs Event (Canonical Definitions)

|  | Concept |	Definition	| Owner |
| --- | --- | --- | --- |
| 1 | Lifecycle State | Overall trade status | Orchestrator |
| 2 | Phase | Logging classification | Logger contract |
| 3 | Event	| Concrete action | Engine |

### Canonical Rule

    Engines emit events

    The Orchestrator controls lifecycle state.


Engines must never:

- Create lifecycle states
- Advance lifecycle states
- Infer lifecycle state implicitly

---

## 🧩 5. Trade Lifecycle Orchestrator
### 5.1 Role & Authority
The Trade Lifecycle Orchestrator is the single authority that:

- ✅ Creates and owns `trade_id`
- ✅ Tracks lifecycle state per trade
- ✅ Validates whether requested actions are allowed
- ✅ Advances lifecycle state explicitly

It does not:

- Calculate indicators
- Apply Money Management logic
- Place orders directly


### 5.2 Interaction Model

| | Component | Responsibility |
| --- | --- | --- |
| 1 | Entry Engine | Requests trade entry |
| 2 | MM Engines | React to MANAGED state |
| 3 | Exit Engine | Requests trade exit |
| 4 | Orchestrator | Approves actions and transitions state |

All engines interact with the orchestrator via requests, never assumptions.

---

## 🆔 6. Trade ID Ownership Rules
Phase 5 formally locks the following rules:

- `trade_id` is created once, at lifecycle state **CREATED**
- `trade_id` is immutable for the life of the trade
- All events across Entry, MM, and Exit reference the same `trade_id`
- `trade_id` is retired at lifecycle state **CLOSED**

No engine may generate or mutate a `trade_id`.

--- 

## 📝 7. Logging Alignment Rules
Lifecycle transitions must emit deterministic logs:

| | Lifecycle Transition |	Required Log |
| --- | --- | --- |
| 1 | CREATED → ENTERED	| Entry execution event |
| 2 | ENTERED → MANAGED |	Lifecycle transition event |
| 3 | MANAGED → EXITED	| Exit execution event |
| 4 | EXITED → CLOSED	| Trade completion event |

Money Management engines may only emit events while lifecycle state is **MANAGED**.

Invalid action attempts must:

- Be rejected
- Be logged explicitly
- Never fail silently

--- 

## 📸 7.1 Lifecycle Context Snapshot Requirements
In addition to event-specific data, Phase 5 mandates full context snapshots at key lifecycle boundaries to ensure deterministic replay and analytics.

### Required Snapshot Moments
A complete trade context snapshot must be logged at the following lifecycle points:

- ✅ After ENTRY execution (ENTERED)
- ✅ On each Money Management action (within MANAGED)
- ✅ On EXIT execution (EXITED)
- ✅ On lifecycle termination (CLOSED)

### Snapshot Contents (Non-Exhaustive)
Each snapshot must include, when applicable:

- Entry price
- Current market price
- Stop Loss (SL)
- Take Profit (TP)
- Position size / volume
- Floating profit & loss
- Realized profit & loss
- Symbol, timeframe, and execution timestamp

### Ownership & Responsibilities

- Engines populate context values they compute
- The Orchestrator enforces when snapshots are required
- The Logger persists snapshots without transformation

Phase 5 does not introduce new calculations. It guarantees snapshot timing and completeness.

---


## 🔄 7.2 Lifecycle State Transition Table
The following table defines allowed and forbidden lifecycle transitions. Any invalid transition must be rejected and logged.


| | Current State |	Requested Action |	Next State | Allowed | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | — | Create trade | CREATED | ✅	| Trade intent established |
| 2 | CREATED |	Execute entry | ENTERED | ✅ | Entry must succeed |
| 3 | CREATED |	Exit request | — | ❌ | Cannot exit before entry |
| 4 | ENTERED |	Begin management | MANAGED | ✅	| Automatic or explicit |
| 5 | ENTERED |	Exit request	| EXITED |	✅ |	Early/manual exit |
| 6 | MANAGED |	MM action |	MANAGED |	✅ |	BE, scale-out, trail |
| 7 | MANAGED |	Exit request |	EXITED |	✅ |	Normal exit path |
| 8 | EXITED  |	Finalize trade | 	CLOSED |	✅ |	Position fully closed |
| 9 | CLOSED |	Any action | 	— |	❌ |	Lifecycle terminated |

---


## 📎 7.3 TradeContext Reference (Non-Normative)
This phase does not redefine the `TradeContext` structure introduced in earlier phases.

The purpose of this reference is to clarify expectations, not impose field-level contracts.

- `TradeContext` is the carrier of snapshot data required by Phase 5
- Snapshot requirements defined in Section 7.1 must be satisfiable using `TradeContext`
- Field naming, typing, and storage layout are implementation concerns

Any gaps discovered between snapshot requirements and the existing `TradeContext`:

- Must be addressed via non-breaking extensions
- Should be documented in Phase 5 architecture or implementation notes, not here


>  📌 This keeps Phase 5 focused on orchestration guarantees, while preserving Phase 4 stability.


--- 

## 🚨 8. Guardrails & Failure Scenarios
Phase 5 defines explicit behavior for:

- Exit requested before ENTRY
- MM event requested outside MANAGED state
- Duplicate EXIT requests
- Events emitted after CLOSED
- Orphaned trade contexts

All scenarios must be:

- Deterministically handled
- Logged with sufficient context

---

## 🚫 9. Non‑Goals (Explicitly Out of Scope)
Phase 5 will not:

- Modify Phase 4 logging contracts
- Optimize strategies or parameters
- Introduce new indicators or signals
- Alter Money Management algorithms
- This phase is orchestration-only.

---

## 📦 10. Phase 5 Deliverables
Phase 5 is considered complete when:

- ✅ Trade Lifecycle Orchestrator exists
- ✅ Lifecycle states are explicit and enforced
- ✅ All engines respect lifecycle boundaries
- ✅ Phase 4 behavior remains unchanged

---

## ➡️ 11. Next Phase Preview
**Phase 6 — Strategy Stabilization & Replay Analysis** (tentative)

Phase 6 will leverage the deterministic lifecycle introduced in Phase 5 to:

- Analyze trade behavior
- Validate Money Management effectiveness
- Enable higher-confidence optimizations

---

📌 **Note:** Implementation must not begin until this specification is reviewed and approved.
