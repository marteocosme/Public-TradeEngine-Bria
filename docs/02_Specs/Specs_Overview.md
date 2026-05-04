# Specifications Overview


## 🔒 Status

Version: v1.1  
Last Updated: 2026-05-04  


## 🎯 Purpose

Defines all system specifications, including:

- Data schema
- Event definitions
- Contracts
- Validation rules
- Behavior specifications

---


## ✅ 🔒 Single Source of Truth (SSOT)

Each type of system knowledge must exist in ONLY ONE place:

| Concern | Source of Truth |
|--------|---------------|
| Data structure | MM_Snapshot_Schema |
| Event definitions | TradeLifecycleEvents |
| Logging mapping | Logging Schema Contract |
| MM behavior | MoneyManagement_Spec |
| Signal logic | EntryStrategy_Spec |
| Validation rules | Validation Specs |

---


## ✅ 🔗 Spec to Architecture Relationship

All specification documents must map directly to Architecture documents.

| Spec | Architecture |
|------|-------------|
| Snapshot Schema | Snapshot_DataFlow_Architecture |
| Logging Contract | Logging_Architecture |
| MM Spec | MM_Architecture |
| Signal Spec | Signal Architecture (future) |
| Events | Lifecycle Orchestrator |

---



## ⚠️ Rule

Architecture MUST NOT define behavior not present in Specs.


## ✅ 🧠 Specification Layers

### ✅ 1. Core Specifications

Location: `/00_Core/`

#### Includes:
- Snapshot Schema
- Event Definitions
- Logging Contract

#### Responsibility:
- Defines system-wide data and contracts
- Acts as Single Source of Truth (SSOT)


    ### 1.1 📚 Schema Version Archive

    Location: `/00_Core/_archive/`

    #### Includes:
    - Previous schema versions (v1.0, v1.1, etc.)

    #### Purpose:
    - Preserve schema evolution history
    - Support debugging and backtesting audits
    - Enable version comparison

#### ⚠️ Important Rule

Only ONE schema version is ACTIVE at a time.

All previous versions must be archived and must NOT be used for:
- Implementation
- Logging
- Validation

---

### ✅ 2. Money Management

Location: `/01_MM/`

#### Includes:
- Money Management behavior specification

#### Responsibility:
- Defines trade management logic
- Controls lifecycle actions:
  - SCALE_OUT
  - BREAK_EVEN
  - TRAIL
  - EXIT

---

### ✅ 3. Signal Specifications (Future Phase)

Location: `/02_Signal/`

#### Includes:
- EntryStrategy_Spec

#### Responsibility:
- Defines entry signal generation
- Evaluates indicators and conditions
- Produces trade entry intent

#### ⚠️ Status

Signal module is not currently active.

System currently operates using:
- Lifecycle Orchestrator
- MM Modules



### ✅ 4. Validation

Location: `/02_Validation/`


#### ✅ 4.1 Pre-Execution Validation

 Location: `/02_Validation/01_PreExecution/`

#### Includes:
- Entry Parameter Validation
- Any future MM action pre-checks

#### Responsibility:
- Validates inputs BEFORE execution
- Ensures trade constraints are satisfied

#### ✅ 4.2 Post-Execution Validation

Location: `/02_Validation/02_PostExecution/`

#### Includes:
- MM-LOG-01 logging validation
- Snapshot/log correctness verification

### ✅ Responsibility Separation

- Pre-Execution → validates inputs BEFORE execution
- Post-Execution → validates outputs AFTER execution


### 🔁 Validation Separation Model

Validation is divided into two layers:

1. Pre-Execution Validation
   - Ensures correctness BEFORE any trade action
   - Prevents invalid executions

2. Post-Execution Validation
   - Ensures logs and snapshots are correct
   - Enforces auditability (MM-LOG-01)

This separation ensures:
- Cleaner debugging
- Stronger system guarantees
- No mixing of responsibilities

---

# ✅ 💻 Spec to Implementation Rule

All implemented logic must originate from a spec.

---

## ✅ Requirements

- No hardcoded logic outside specs
- No hidden rules in code
- All constants (events, fields) must be defined in specs

---

## ❌ Violations

- Adding logic directly in code
- Using undefined fields
- Logging fields not in schema

---


# ✅ 🔗 Traceability Note

All specifications must map to:

- Architecture (`/03_Architecture`)
- Implementation (code)
- Logging output
- Validation rules

No behavior should exist in code that is not defined in this folder.

---

## ✅ Design Principles

- Single Source of Truth (SSOT)
- Schema-first design
- Contract-driven logging
- Strict contract enforcement
- Version-controlled updates

---

## ✅ Change Policy

All changes must follow:

1. Update Schema (if applicable)
2. Update Contract
3. Update Validation
4. Update Architecture
5. Then update implementation

---

# ✅ 📌 Notes

- Signal module is currently planned (Phase 6)
- Execution system is already active and validated
- Logging and snapshot system must remain consistent at all times

---


# ✅ 🔁 Versioning Policy

Each spec category must follow version control rules.

---

## ✅ Rules

- Only ONE active version per spec
- Older versions must be archived
- Archived versions must not be used in implementation

---

## ✅ Locations

- Active specs → main folder
- Historical versions → `_archive/`

---

## ✅ Example

MM_Snapshot_Schema:
- v1.2 → ACTIVE
- v1.1 → ARCHIVED
- v1.0 → ARCHIVED

---

# ✅ 🔄 Specification Dependency Flow

```
Signal Spec (EntryStrategy)
        ↓
Lifecycle (uses Events)
        ↓
Money Management Spec
        ↓
Execution Layer
        ↓
Snapshot Schema
        ↓
Logging Contract
        ↓
Validation (MM-LOG-01)
```

# ⚠️ Common Pitfalls

- Mixing signal logic with MM logic
- Duplicating schema fields in contracts
- Writing logging rules inside lifecycle specs
- Adding behavior without updating specs

---

## ✅ Resolution Rule

If unsure:
→ Always update Specs FIRST before coding