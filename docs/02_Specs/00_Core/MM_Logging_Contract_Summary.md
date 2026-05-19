# 📜 MM-LOG-01 Logging Contract — Summary (SSOT)

## 🎯 Purpose
The **MM-LOG-01 Logging Contract** defines the **behavioral rules, lifecycle semantics, and cross-log invariants** governing the trading engine’s logging system.

It ensures that all logs are:
- Deterministic  
- Auditable  
- Fully reconstructable without code inspection  

---

## 🧱 Contract Scope

The contract governs:
- Trade lifecycle logging (ENTRY → SCALE → CLOSE)
- Snapshot integrity (BEFORE / AFTER pairing)
- Event outcome semantics (execution vs result)
- Cycle-level aggregation (PnL and volume)

It explicitly excludes:
- Broker execution telemetry (handled by EXEC-LOG-01)

---

## 🔁 Lifecycle Model (Authoritative)

A valid trade lifecycle MUST follow:

ENTRY → (SCALE_OUT / BE / TRAIL)* → (optional EXIT) → CLOSE

### Mandatory Rules:
- Every lifecycle MUST have **exactly one MM_EVENT_CLOSE**  
- MM_EVENT_CLOSE is the **only valid lifecycle terminator**  
- MM_EVENT_EXIT represents **intent only, not closure**

---

## 🔗 Event Outcome Semantics

### CLOSE (Final Outcome)
- Represents **broker-confirmed closure**
- MUST include:
  - close_reason  
  - close_price  
  - close_profit  
  - close_volume  
  - deal_id  

### SCALE_OUT (Partial Outcome)
- MAY include broker-confirmed close fields when matched to a deal  
- Provides **partial lifecycle realization visibility**

### Non-Close Events (ENTRY, EXIT, BE, TRAIL)
- MUST use **neutral defaults** for close-related fields

---

## 📊 Volume & PnL Invariants (v2.2)

### Event-Level Semantics
- close_volume = volume closed **in that specific event**

### Cycle-Level Aggregation
- close_volume = SUM(SCALE_OUT close_volume) + CLOSE close_volume
- Cycle PnL = SUM(SCALE_OUT close_profit) + CLOSE close_profit

### Design Rule
- No redundant lifecycle volume field  
- (total_traded_volume removed in v2.2)

---

## 🧾 Snapshot Contract

For every event:
- MUST produce BEFORE snapshot
- MUST produce AFTER snapshot

### Pairing Rules:
- 1 BEFORE → 1 AFTER  
- No orphan snapshots  
- AFTER must include execution outcome fields

---

## 🔐 Core Invariants

The system MUST guarantee:
- Exactly one CLOSE per lifecycle  
- Full event-to-cycle traceability via cycle_id  
- Schema-compliant column structure  
- Deterministic replay from logs alone  

Violations are considered **system-level failures**.

---

## 🧩 Contract vs Schema (Critical Distinction)

- **Schema** → defines structure (fields, order, types)  
- **Contract** → defines meaning, lifecycle rules, and invariants  

---

## 🔄 Enforcement

The contract is enforced by:
- MM_LogSchema.mqh (SSOT binding)
- CUnifiedTradeLogger (logging engine)
- Runtime validation checklist

---

## ✅ Guarantee

The system guarantees:
- Every MM decision is recorded  
- Every state transition is captured  
- Every trade lifecycle is reconstructable  
- Logs are audit-grade and deterministic
