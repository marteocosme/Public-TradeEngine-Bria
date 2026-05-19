
 ## Phase 6 — Analytics Layer
  
 Phase 6 turns validated runtime logs into:
 - dashboards & metrics
 - lifecycle attribution (scale-out vs final-close)
 - replay tooling
 …and is gated by data quality checks.
 
 ### Start Here (Gate)
 - Data Quality Checks Checklist (Phase 6 entry gate)
 - 02\_Data\_Quality/PHASE-6\_Data\_Quality\_Checks\_Checklist.md
 
 ### Phase Goals (What “Done” means)
 - A repeatable ingestion pipeline (CSV → structured dataset)
 - A reproducible DQ report per run (summary + details)
 - At least one dashboard/report MVP using validated logs
 - All interpretation follows the MM logging contract semantics (not schema-only interpretation)

### DQ Output Convention (Recommended)
Phase 6 runs should produce two standard outputs per run:
- `dq_summary.csv` — one row per check (pass/fail + counts)
- `dq_details.csv` — one row per failing row/key (actionable evidence)

**Local run folder (gitignored):**
`artifacts/phase6_runs/<run_id>/`

**Suggested structure:**
`artifacts/phase6_runs/<run_id>/inputs/`
`artifacts/phase6_runs/<run_id>/outputs/`
`artifacts/phase6_runs/<run_id>/logs/`
`artifacts/phase6_runs/<run_id>/manifest.json`

**Suggested run_id format:**
The run_id is required in all DQ outputs (dq_summary, dq_details) and must match the parent folder name.

`YYYYMMDD_HHMMSS_<env>_<tag>`   
-Example: `20260520_040812_bt_EURUSD_M15`
 
`YYYYMMDD_HHMMSS_<env>_<symbol>_<timeframe>[_<tag>]`

Examples:
- `20260520_040812_bt_EURUSD_M15`
- `20260520_101500_bt_XAUUSD_H1`
- `20260520_211030_live_USDJPY_M5`
- `20260520_220001_bt_GBPUSD_H4_debug`

 ### Folder Guide
 - 01\_Data\_Model/
 - Analytics interpretation rules (joins, mappings, version compatibility notes)
 - 02\_Data\_Quality/
 - Checklist, join failure taxonomy, DQ outputs format, sample results
 - 03\_Tools\_and\_Runners/
 - Scripts and tooling notes (Power BI / Excel / Python)
 - 04\_Dashboards\_and\_KPIs/
 - KPI definitions, attribution logic, dashboard spec
 
 ### SSOT vs Artifacts (Important)
  
 ✅ Commit to repo:
 - MD docs (checklists/specs/definitions)
 - scripts/runners (if you choose to version them)
 - dashboard specifications (not necessarily PBIX binaries) 
 🚫 Do NOT commit (recommended):
 - raw backtest exports
 - generated DQ output CSVs (dq\_summary/dq\_details)
 - large PBIX/Excel binaries (unless using Git LFS) 
 Suggested local-only (gitignored) folder:
 - artifacts/phase6\_runs/\<run\_id\>/

 ### Next Action (Phase 6 MVP order)
 - Run DQ checklist on one real log set
 - Produce DQ Summary + DQ Details outputs
 - Build Dashboard MVP only after DQ passes (0 FATAL findings),
