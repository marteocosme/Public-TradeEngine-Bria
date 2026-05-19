# DQ Output Format (SSOT)

## Purpose
Defines the standard output structure, naming conventions, and field-level requirements for Phase 6 Data Quality (DQ) runs.

---

## Run Identification

All outputs must be grouped under a unique `run_id`:

```
YYYYMMDD_HHMMSS_<env>_<symbol>_<timeframe>[_<tag>]
```

Examples:
- 20260520_040812_bt_EURUSD_M15
- 20260520_211030_live_USDJPY_M5

**Rule:**
The `run_id` must:
- Match the parent folder name
- Be present in all output files

---

## Folder Structure (Local / Gitignored)

```
artifacts/phase6_runs/<run_id>/
  inputs/
  outputs/
  logs/
  manifest.json
```

---

## Required Output Files

### 1) dq_summary.csv
One row per check.

**Columns:**
- run_id
- severity (FATAL | WARN | INFO)
- check_id
- check_name
- passed (true/false)
- fail_count
- total_rows
- notes

---

### 2) dq_details.csv
One row per failed record.

**Columns:**
- run_id
- severity
- check_id
- entity (event | snapshot | cycle | derived)
- primary_key
- field
- message
- raw_value (optional)
- expected (optional)

---

## Severity Definitions

| Severity | Meaning | Action |
|----------|--------|--------|
| FATAL    | Critical data issue | BLOCK dashboard work |
| WARN     | Non-critical inconsistency | Review required |
| INFO     | Informational observation | No action required |

---

## Gate Rule

Dashboard development is allowed only if:

```
FATAL findings = 0
```

---

## Manifest (Recommended)

`manifest.json` should include:
- run_id
- timestamp
- env
- symbol
- timeframe
- source files
- row counts
- contract/schema version

---

## Design Principles

- Deterministic outputs (same input = same result)
- Auditability (every failure traceable to row/key)
- Tool-agnostic (usable in Python, Excel, Power BI)
- Strict alignment with MM logging contract semantics

---

## Status

Version: v1.0
Status: ✅ ACTIVE (Phase 6 SSOT)
