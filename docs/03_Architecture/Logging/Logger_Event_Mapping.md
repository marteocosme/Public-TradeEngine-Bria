# Logger Event Mapping (MM-LOG-01)

Status: ACTIVE  
Layer: Architecture  

Related Spec:
- MM-LOG-01_Logging_Schema_Contract.md

Related Implementation:
- Logger_Implementation.md
- SnapshotEmitter_Implementation.md

---

## 1. Overview

This document defines the mapping between trade lifecycle events and logging requirements under MM-LOG-01.

It ensures that all Money Management actions emit consistent, auditable logs.

---

## 2. Event → Logging Mapping

| Event | Module | BEFORE Snapshot | AFTER Snapshot |
|------|--------|----------------|---------------|
| ENTRY_EXECUTED | MM_Entry | ✅ Required | ✅ Required |
| SCALE_OUT_EXECUTED | MM_ScaleOut | ✅ Required | ✅ Required |
| BREAK_EVEN_TRIGGERED | MM_BE | ✅ Required | ✅ Required |
| TRAILING_STOP_MOVED | MM_Trail | ✅ Required | ✅ Required |
| EXIT_EXECUTED | MM_Exit | ✅ Required | ✅ Required |

---

## 3. Logging Sequence (CRITICAL)

All logging must follow strict order:

```plaintext
[1] Event detected
[2] Emit BEFORE snapshot
[3] Apply execution (SL/TP/position change)
[4] Emit AFTER snapshot
```
Violation of this sequence breaks audit traceability.


4. Timing Rules




