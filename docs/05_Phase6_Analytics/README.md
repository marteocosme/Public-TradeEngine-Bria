# Phase 6 — Analytics Layer

Phase 6 turns validated runtime logs into:
- dashboards & metrics
- lifecycle attribution (scale-out vs final-close)
- replay tooling
…and is gated by data quality checks.

## Start Here (Gate)
1) Data Quality Checks Checklist (Phase 6 entry gate)
- `02_Data_Quality/PHASE-6_Data_Quality_Checks_Checklist.md`

## Phase Goals (What “Done” means)
- A repeatable ingestion pipeline (CSV → structured dataset)
- A reproducible DQ report per run (summary + details)
- At least one dashboard/report MVP using validated logs
- All interpretation follows the MM logging contract semantics (not schema-only interpretation)

## Folder Guide
- `01_Data_Model/`
  - Analytics interpretation rules (joins, mappings, version compatibility notes)
- `02_Data_Quality/`
  - Checklist, join failure taxonomy, DQ outputs format, sample results
- `03_Tools_and_Runners/`
  - Scripts and tooling notes (Power BI / Excel / Python)
- `04_Dashboards_and_KPIs/`
  - KPI definitions, attribution logic, dashboard spec

## SSOT vs Artifacts (Important)
✅ Commit to repo:
- MD docs (checklists/specs/definitions)
- scripts/runners (if you choose to version them)
- dashboard specifications (not necessarily PBIX binaries)

🚫 Do NOT commit (recommended):
- raw backtest exports
- generated DQ output CSVs (dq_summary/dq_details)
- large PBIX/Excel binaries (unless using Git LFS)

Suggested local-only (gitignored) folder:
- `artifacts/phase6_runs/<run_id>/`

## Next Action (Phase 6 MVP order)
1) Run DQ checklist on one real log set
2) Produce DQ Summary + DQ Details outputs
3) Build Dashboard MVP only after DQ passes (0 FATAL findings)