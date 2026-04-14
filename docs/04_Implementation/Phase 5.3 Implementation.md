
# 🛠️ Phase 5.3 — Implementation Plan (Incremental & Compile‑Safe)
**Project:** Public-TradeEngine-Bria

**Phase:** 5.3 (Implementation Planning)

**Status:** 📋 Plan Draft (Pre‑Implementation)

**Prerequisites:**

- Phase 5 Spec ✅ Approved
- Phase 5 Architecture ✅ Approved
- Phase 5.2 Interfaces ✅ Approved

---

## 📌 1. Purpose of Phase 5.3
This document defines a step‑by‑step, compile‑safe implementation plan for Phase 5 (Trade Lifecycle Orchestration).

The goal is to:

- Introduce the Trade Lifecycle Orchestrator without breaking Phase 4
- Maintain continuous compile success
- Provide clear rollback points
- Ensure logging and snapshot guarantees can be verified at each step

No step in this plan introduces speculative refactors or behavioral changes.

---

## 🧠 2. Guiding Rules (Non‑Negotiable)
All implementation steps must:

- ✅ Compile after each step
- ✅ Preserve Phase 4 behavior and logging contracts
- ✅ Introduce changes additively
- ✅ Be reversible without cascading changes

If a step fails these criteria, it must be rolled back.

---

## 🧩 3. High‑Level Execution Strategy
Implementation proceeds in five controlled layers:

1. Scaffolding (no logic)
2. State tracking (isolated, unused)
3. Validation wiring (pass‑through)
4. Enforcement (reject invalid actions)
5. Snapshot enforcement hooks

Each layer ends with a compile + backtest sanity check.

---

## 🔨 4. Step‑by‑Step Implementation Plan
### 🔹 Step 1 — Introduce Lifecycle Types (Scaffolding Only)
**Objective:** Add lifecycle enums and data types with zero usage.

Actions:

- Define `LifecycleState` enum
- Define `LifecycleAction` enum
- Define `RejectionReason` enum

Rules:

- No logic
- No engine references
- No behavioral change

✅ Checkpoint: Project compiles. No behavior change.

---
### 🔹 Step 2 — Add TradeLifecycleController Skeleton
**Objective:** Introduce the orchestrator class without integrating it.

Actions:

- Create `TradeLifecycleController` class
- Add internal storage for `trade_id → LifecycleState`
- Add empty `RequestAction(...)` method returning `true`

Rules:

- Controller is not invoked anywhere
- No validation logic yet

✅ Checkpoint: Project compiles exactly as before.

---
### 🔹 Step 3 — Embed Controller into `CTradeEngine`
**Objective:** Make the orchestrator available without affecting flow.

Actions:

- Add `TradeLifecycleController` as a private member of `CTradeEngine`
- Initialize controller in constructor/init

Rules:

- No engine calls yet
- No requests issued

✅ Checkpoint: Compile + backtest produces identical logs.

---
### 🔹 Step 4 — Wire CREATE / ENTER Pass‑Through Requests
**Objective:** Begin using the interface without enforcement.

Actions:

- Call `RequestAction(CREATE)` before entry execution
- Call `RequestAction(ENTER)` after successful entry
- Always accept (`true`) internally for now

Rules:

- Returned value ignored for now
- No rejection paths

✅ Checkpoint: Compile + verify entry logs unchanged.

---

### 🔹 Step 5 — Wire MM_ACTION Pass‑Through Requests
**Objective:** Extend wiring into ManageOpenPosition safely.

Actions:

- Wrap BE / scale‑out / trailing calls with `RequestAction(MM_ACTION)`
- Always allow internally

Rules:

- No enforcement yet
- No short‑circuiting

✅ Checkpoint: MM behavior unchanged; logs identical.

---

### 🔹 Step 6 — Wire EXIT / CLOSE Pass‑Through Requests
**Objective:** Complete lifecycle coverage.

Actions:

- Call `RequestAction(EXIT)` before exit execution
- Call `RequestAction(CLOSE)` after exit completion

Rules:

- Always allow internally

✅ Checkpoint: Exit behavior and logs unchanged.

---

### 🔹 Step 7 — Introduce Lifecycle State Tracking
**Objective:** Begin tracking state without rejecting anything.

Actions:

- Implement lifecycle state changes inside `RequestAction`
- Populate state map using transition table
- Do not reject invalid transitions yet (only log internally)

✅ Checkpoint: State transitions visible via debug logging only.

---
### 🔹 Step 8 — Enable Rejection for Invalid Transitions
**Objective:** Enforce lifecycle correctness.

Actions:

- Reject invalid transitions per lifecycle table
- Populate `RejectionReason`
- Engines must abort on rejection

✅ Checkpoint: Invalid flows are blocked deterministically.

---
### 🔹 Step 9 — Enforce Snapshot Presence at Boundaries
**Objective:** Activate snapshot guarantees.

Actions:

- Validate `TradeContext` presence at required lifecycle points
- Reject action if context missing
- Log rejection explicitly

✅ Checkpoint: Snapshot‑less flows rejected safely.

---
### 🔹 Step 10 — Final Validation & Cleanup

Actions:

- Remove any temporary debug traces
- Confirm no Phase 4 contracts changed
- Run representative backtests

✅ Exit Criteria: Phase 5 considered implemented.


## 🔄 5. Rollback Strategy
At any step:

- Revert the most recent commit
- Re‑run compile + backtest
- Never stack unverified changes

---

## ✅ 6. Phase 5 Completion Criteria
Phase 5 implementation is complete when:

- Lifecycle rules are enforced
- Snapshot guarantees are active
- Engines behave identically for valid flows
- Invalid flows are deterministically rejected
- No Phase 4 regressions exist

---

📌 Only proceed to code when this plan is explicitly approved.
