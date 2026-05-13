# Logging Architecture

## 🔒 Document Status

**Version:** v1.5

**Status:** ✅ ACTIVE (SSOT)

**Last Updated:** 2026-05-12 (UTC+8)


### 📂 Location Note

This file is part of the Core Architecture layer.

Path:
docs/03_Architecture/00_Core/

---

## 🔗 Traceability

This document is aligned with:

- MM_Snapshot_Schema.md (SSOT)
- MM_Event_Log_Schema.md (SSOT)
- MM_Cycle_Summary_Schema.md (SSOT)
- MM-LOG-01_Logging_Schema_Contract.md (SSOT)
- MM-LOG-01_Runtime_Validation_Checklist.md (SSOT)

---

# ✅ 🎯 Purpose

Defines the logging system responsible for:

- Writing MM snapshots to file
- Enforcing schema consistency
- Ensuring auditability
- Managing log file structure

---

# ✅ 🧩 Logging Responsibilities

| Component | Responsibility |
|----------|--------------|
| TradeEngine | Emits snapshot data |
| Logger | Writes logs to file |
| Schema | Defines fields |
| Validation | Defines correctness rules |

---

# ✅ 🔄 Logging Pipeline
## Snapshot Pipeline (State)
```
TradeEngine
↓
Snapshot (BEFORE / AFTER)
↓
Logger (Snapshot Writer)
↓
File Output (CSV)
```

## Event Pipeline (Lifecycle / Intent / Outcome)
``` 
TradeEngine
↓
MM Event (ENTRY / SCALE_OUT / BE / TRAIL / EXIT / CLOSE)
↓
Logger (Event Writer)
↓
File Output (CSV / JSON)
```

## Cycle Summary Pipeline (Completed Lifecycle Aggregate)
```
TradeEngine
↓
Lifecycle CLOSE detected (MM_EVENT_CLOSE)
↓
Cycle Summary constructed from completed lifecycle state and realized-PnL events
↓
Logger (Cycle Summary Writer)
↓
File Output (CSV)
```
Cycle Summary is the completed-lifecycle aggregate layer. It uses cycle_id as the lifecycle grouping key.

Cycle Summary broker close evidence is reconciled against the mandatory MM_EVENT_CLOSE row.

Cycle Summary pnl is total realized lifecycle PnL and is aggregated from:
- successful MM_EVENT_SCALE_OUT close_profit values
- mandatory MM_EVENT_CLOSE close_profit value

Cycle Summary pnl is not limited to the final MM_EVENT_CLOSE close_profit when scale-out events occurred.

---

## ✅ 🧱 Event Payload Standardization (Post-Sweep)

To prevent data corruption and reduce producer-side boilerplate, MM event records are initialized using a common initializer (`InitMMEvent(...)`).

### InitMMEvent(...) Responsibilities
- Sets common identity fields:
  - event_time, event_type, phase, symbol, timeframe, cycle_id, trade_id, ticket
- Applies safe defaults to non-applicable fields:
  - close_* fields default to neutral values (blank/0) and deal_id defaults to 0
  - scale_* fields default to 0
  - action_summary defaults blank

Event producers then populate only event-specific fields (e.g., action_summary, scale_steps/scale_fraction_total, broker evidence fields where applicable).


## 🔭 Observability Layer — Lifecycle Grouping

### Overview

To improve traceability and auditability, the logging system introduces **lifecycle grouping** using `cycle_id`.

This enables reconstruction of full trade lifecycles across MM events and snapshots.

---


### 🆔 Identity & Correlation Model (v2.0)

#### Deprecation Notice
- `trade_context_id` is **deprecated/removed** in Snapshot schema v2.0.
- Logging MUST use explicit identity fields instead.

#### Required Identity Fields (Snapshots & Events)
- `cycle_id` — lifecycle grouping id (generated at ENTRY; reused for all subsequent actions)
- `internal_trade_id` — deterministic engine id (stable identifier independent of broker ticket)
- `ticket` — broker ticket (0 pre-entry; populated after entry when available)
- `position_id` — POSITION_IDENTIFIER (critical for hedging/netting deal matching)
- `correlation_id` — action-level trace identifier:
  - binds MM Event ↔ Snapshot BEFORE ↔ Snapshot AFTER for the same non-CLOSE MM action attempt
  - groups one logical MM action/evaluation chain inside a `cycle_id`
  - differs from `cycle_id`, which groups the full trade lifecycle
  - differs from `debug_event_id`, which identifies one physical log row


#### internal_trade_id (v2.0) — Current Implementation
For v2.0, the engine sets:
- `internal_trade_id == cycle_id`

This preserves a stable deterministic identity while the system operates in a
one-entry-per-lifecycle mode. The field is reserved for future divergence when
trade identity must be stable across multi-ticket or multi-position structures.

#### Join Rules (Analytics & Validation)
- Primary lifecycle grouping: `cycle_id`
- Broker evidence linkage (CLOSE/SCALE_OUT deals): `position_id`
- Action correlation linkage: `correlation_id`

#### MM_EVENT_CLOSE correlation behavior (P5-FIX-02A)

`MM_EVENT_CLOSE` is emitted by close detection after the engine observes that a previously open position is no longer open. Under the current v2.1 runtime model, CLOSE is Event-only broker confirmation and does not require a Snapshot BEFORE/AFTER pair.

Because CLOSE may originate from either an explicit engine exit request or a broker-side close condition, CLOSE correlation behavior is conditional.

Valid shared correlation pattern:

```text
MM_EVENT_EXIT → MM_EVENT_CLOSE
close_reason = MM_EXPERT: Exit Signal
same correlation_id = valid
```

### Lifecycle Definition

A trade lifecycle consists of:

ENTRY
→ MM actions (SCALE_OUT / BREAK_EVEN / TRAIL)
→ (optional EXIT intent)
→ CLOSE (broker-confirmed outcome)

---

### Broker Evidence Fields (close_* / deal_id) — Applicability
- MM_EVENT_CLOSE:
  - MUST populate close_reason, close_price, close_profit, close_volume, deal_id (final broker-confirmed closure).
- MM_EVENT_SCALE_OUT:
  - MAY populate close_reason, close_price, close_profit, close_volume, deal_id when a broker partial-close deal is matched.
  - If no matching deal is found, emit neutral defaults.
- ENTRY / BE / TRAIL / EXIT:
  - close_* fields MUST remain neutral defaults (blank/0), by design.

This prevents contamination of final outcome analytics while still preserving broker-confirmed evidence for partial closures.

---


#### close_reason Canonical Values (Analytics-Friendly)
close_reason is normalized into canonical strings for analytics and audit:
- CLOSE (EXPERT): "MM_EXPERT: Exit Signal"
- SCALE_OUT (EXPERT): "MM_EXPERT: Scale Out"
- Manual closures: MANUAL_DESKTOP_TERMINAL / MANUAL_MOBILE_APP / MANUAL_WEB_PLATFORM
- Broker outcomes: TP_HIT / SL_HIT / STOP_OUT Event / UNKNOWN / etc.

Exact allowed values are defined in MM_Event_Log_Schema.md (SSOT).

---

### Two‑Phase Termination (EXIT vs CLOSE)

To prevent lifecycle gaps in real execution:
- `MM_EVENT_EXIT` represents engine intent to close (signal/manual request). It is optional.
- `MM_EVENT_CLOSE` represents broker/deal-confirmed closure (TP/SL/STOP_OUT/SIGNAL/MANUAL). It is mandatory.

**Architectural rule:**
- EXIT and CLOSE are different sources of truth:
  - EXIT originates from the engine decision path
  - CLOSE originates from broker/deal confirmation
- Validation and Cycle Summary MUST use CLOSE as the lifecycle terminator.

**Correlation rule:**
- Engine-driven EXIT → CLOSE may share correlation_id when close_reason = "MM_EXPERT: Exit Signal".
- Broker-driven CLOSE events such as TP_HIT, SL_HIT, STOP_OUT Event, UNKNOWN, or manual/external closes must receive a dedicated CLOSE correlation_id.
- Broker-driven CLOSE must not inherit correlation_id from prior ENTRY, SCALE_OUT, BE, or TRAIL events.



---

### cycle_id Behavior

- A new `cycle_id` is generated at ENTRY
- The same `cycle_id` is reused for all subsequent MM actions
- The lifecycle ends at `MM_EVENT_CLOSE` (broker-confirmed outcome)
- `MM_EVENT_EXIT` is optional (intent only) and may not appear for TP/SL/STOP_OUT closures




---

### Integration into Logging Pipeline

TradeEngine detects ENTRY  
→ `cycle_id` is incremented  
→ BEFORE snapshot emitted with `cycle_id`  
→ Execution performed  
→ AFTER snapshot emitted with `cycle_id`  

During MM management:

- `SCALE_OUT` / `BE` / `TRAIL` reuse the same `cycle_id`
- All logs (events and snapshots) are tagged with `cycle_id`

At CLOSE (`MM_EVENT_CLOSE`):

- Closure is confirmed (broker/deal outcome)
- MM_EVENT_CLOSE is emitted as Event-only broker confirmation
- Cycle Summary is emitted (one row per completed lifecycle)
- Cycle Summary broker close evidence is reconciled against MM_EVENT_CLOSE
- Cycle Summary pnl is aggregated across realized-PnL lifecycle events:
  - successful MM_EVENT_SCALE_OUT close_profit values
  - mandatory MM_EVENT_CLOSE close_profit value
- No Snapshot BEFORE/AFTER pair is required for CLOSE under the current v2.1 model
- Lifecycle completes


---

### Result

All log records can be grouped by `cycle_id` to reconstruct:

- Full trade lifecycle
- State transitions (Snapshot log)
- MM decisions and execution outcomes (Snapshot log)
- Lifecycle events and broker-confirmed outcomes (Event log)
- Completed lifecycle aggregates (Cycle Summary log)


---

### Benefits

- Enables end-to-end trade traceability
- Simplifies debugging and validation
- Provides structured grouping for analysis and backtesting


# ✅ 📄 File Structure

## ✅ File Type

- CSV format
- Machine-readable
- Consistent column order

---

## ✅ Header Handling

### Rule:

- If file is new → ✅ write header
- If file exists → ❌ do not rewrite header

---

### Implementation Logic

- Use the centralized Header Dispatcher (CLogHeaderDispatcher) as the canonical mechanism
- Must prevent duplicate headers across all log files
- Producers (TradeEngine) MUST NOT manage header logic directly

---

# ✅ 📊 Column Enforcement

## ✅ Rules

- Column count must match schema definition
- All fields must be present
- Missing values must use defaults
- Extra fields NOT allowed

---

## ✅ Validation Source

- Enforced under MM-LOG-01
- Verified via column validation tests

---

# ✅ 🔁 Snapshot Pair Logging

## ✅ Rule

Each BEFORE snapshot must be followed by AFTER snapshot.

---

## ✅ Guarantees

- No orphan entries
- Strict ordering preserved


## ✅ 🧾 Snapshot Full‑State Policy (v2.0)

### Rule
MM Snapshots are **FULL‑STATE** for BOTH BEFORE and AFTER.

### Meaning
- BEFORE snapshot captures the complete relevant state immediately before an MM action attempt.
- AFTER snapshot captures the complete relevant state immediately after the MM action attempt.
- AFTER snapshots MUST NOT omit core fields (no blanks-as-missing).

### N/A Normalization (Strict)
When a field is not applicable for an event:
- Numeric fields MUST be `0`
- String fields MUST be `""` (empty string)

This prevents uninitialized/denormal artifacts and enables deterministic parsing and delta analysis.

### Core Fields Required in BOTH BEFORE and AFTER
- Account: balance, equity, free_margin
- Exposure: current_position_lots, current_risk_exposure
- Market context: current_price, atr_value
- Execution state: take_profit, floating_pnl, realized_pnl
- Risk geometry: stoploss_points, value_per_point
- Scale context: scale_atr_multiple, scale_fraction (0 when N/A)
- Execution outcome: action_executed, execution_reason, previous_stoploss, new_stoploss, closed_lots, event_outcome


---

# ✅ 🚀 Execution Outcome Logging

## ✅ Requirement

Execution results must be written in AFTER snapshot.

---

### Includes

- Execution success/failure
- Error codes
- Result flags

---

### Reference

- MM_Snapshot_Schema.md (v2.0 SSOT)

---

# ✅ 📌 File Integrity Rules

## ✅ Must Ensure

- File is append-only
- No row corruption
- No partial writes
- Order preserved

---

# ✅ 🧠 Logger Constraints

Logger MUST NOT:

- Modify business logic
- Decide MM actions
- Change schema structure

Logger ONLY:

- Formats data
- Writes to file
- Enforces structure


## ✅ 🔧 Optional Lifecycle Controller Actions
Lifecycle controller actions may be compile-time disabled in some builds to reduce runtime overhead or isolate logging validation.
This does not change logging schema requirements; it only affects whether lifecycle controller hooks execute.

---

# ✅ 📌 Version Notes

##### v1.5 (2026-05-12)
- Added Cycle Summary pipeline and schema reference.
- Aligned CLOSE lifecycle handling with v2.1 runtime:
  - CLOSE is Event-only broker confirmation.
  - Removed requirement for Snapshot BEFORE/AFTER at CLOSE.
- Documented Cycle Summary as completed lifecycle aggregate layer.
- P5-FIX-03 documentation alignment:
  - Clarified correlation_id as an action-level trace identifier inside a cycle_id.
  - Documented conditional MM_EVENT_CLOSE correlation behavior:
    - MM_EVENT_EXIT → MM_EVENT_CLOSE may share correlation_id when close_reason = "MM_EXPERT: Exit Signal".
    - Broker-driven CLOSE events such as TP_HIT, SL_HIT, STOP_OUT Event, UNKNOWN, or manual/external closes must receive a dedicated CLOSE correlation_id.
    - Broker-driven CLOSE must not inherit correlation_id from prior ENTRY, SCALE_OUT, BE, or TRAIL events.
  - Clarified Cycle Summary pnl as total realized lifecycle PnL aggregated from successful SCALE_OUT close_profit values plus the mandatory CLOSE close_profit value.
  - Clarified that Cycle Summary close evidence reconciles against MM_EVENT_CLOSE, while Cycle Summary pnl reconciles against realized-PnL lifecycle events.


##### v1.4 (2026-05-11)
- Aligned architecture with MM Snapshot Schema v2.0:
  - Full-State snapshots for BEFORE and AFTER (no blanks-as-missing)
  - Deprecated/removed trade_context_id in favor of explicit identity fields
  - Documented correlation_id model for Event ↔ Snapshot BEFORE ↔ Snapshot AFTER
- Clarified header handling to prefer centralized Header Dispatcher mechanism

##### v1.3 (2026-05-09)
- Documented dual logging pipelines (Snapshots vs Events).
- Documented InitMMEvent(...) as canonical event initializer and defaulting mechanism.
- Updated architecture rules for broker evidence fields: close_* and deal_id are mandatory for CLOSE and allowed for SCALE_OUT when deal-matched.
- Added close_reason canonical vocabulary guidance for analytics.

##### v1.2 (2026-05-07)
- Converted to stable SSOT filename: Logging_Architecture.md (archived old versioned file)
- Aligned lifecycle termination with MM-LOG-01 contract v1.4:
  - EXIT = intent (optional)
  - CLOSE = broker-confirmed outcome (mandatory terminator)
- Updated lifecycle grouping definition to end at MM_EVENT_CLOSE
- Added traceability to MM_Event_Log_Schema.md (SSOT) and TradeLifecycleEvents.md (SSOT)
- Updated lifecycle grouping definition and cycle_id termination rule to end at MM_EVENT_CLOSE

#### v1.1 (2026-05-05)

- Introduced `cycle_id` for lifecycle grouping
- Defined lifecycle-based logging structure (ENTRY → MANAGE → EXIT)
- Added requirement for all logs to include cycle_id
- Enables full trade lifecycle traceability and grouping

### v1.0 (2026-05-04)

- Initial logging architecture definition
- Header control defined
- Column enforcement defined
- Execution outcome integration included

---