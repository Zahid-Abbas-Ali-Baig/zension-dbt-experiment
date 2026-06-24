# AI Execution Log — Zension

Track every phase run. Documenting AI reliability is part of the deliverable.

| Phase | Skill(s) Used | Output | Hallucinations Found | Manual Corrections |
| ----- | ------------- | ------ | -------------------- | ------------------ |
| 0 | analytics-eng + run-commands | Minimal bootstrap (`config.md`, `dbt_project.yml`, `profiles.yml`, `dbt deps`) | — | — |
| 1 | analytics-eng + run-commands | `design_brief.md` (approved); schema discovery on `zension.source` (322 tables, 29 in scope) | — | — |
| 2 | run-commands + analytics-eng | `models/staging/_sources.yml` (29 sources) | — | — |
| 3 | run-commands + analytics-eng | 29 staging SQL models + `_stg_models.yml` | — | — |
| 4 | analytics-eng | 20 intermediate models + `_int_models.yml` | — | — |
| 5 | analytics-eng | 25 marts (`fct_*`, `dim_*`, `bridge_cp_skus`) | — | — |
| 6 | semantic-layer + run-commands + analytics-eng | `semantic_models.yml` (24 semantic models, 41 metrics), `_marts__models.yml`, `README.md`, `fct_refunds` | — | — |
| 7 | run-commands + analytics-eng | **`dbt build --select staging+` PASS** — 456 nodes (74 models + 382 tests), all `success`, ~9.5s elapsed. Grain checks: `fct_subscriptions` 826 rows = 826 distinct `subscription_id` (1 row/subscription); `dim_customers` 2697 rows = 2697 distinct `customer_id` (1 row/customer). Semantic layer compiles: `semantic_manifest.json` has 24 semantic models + 41 metrics. | (1) `enrich_marts_yml.py` added column-level `unique` on both `subscription_id` and `snapshot_month` for `fct_subscription_monthly_snapshots` despite composite grain (sub × month). (2) Unconditional `relationships` tests on `fct_subscriptions.order_id` and `fct_payment_attempts.payment_id` — failed on known orphans (5 soft-deleted orders, 12 payment-history rows without CRM payment match). | Removed erroneous `unique` tests on snapshot columns; added `where: has_valid_order = true` / `where: has_valid_payment = true` on relationships tests; exposed `has_valid_order` on `fct_subscriptions`; fixed `enrich_marts_yml.py` to skip per-column `unique` when PK is composite. |
| 8 | Power BI modeling MCP | Connected to `powerbi/zension.pbix` (Desktop port 50962). Created hidden `_KPIs` table with **28 DAX measures** mapped to `design_brief.md` §9 KPIs (Sales, Subscriptions, Finance, Payments, Customers, Operations). DAX validation: GMV 220,310 SAR / 781 orders / MRR 43,219 / 235 active subs — matches discovery. Report layout script `scripts/build_pbi_report_layout.py` adds 5 pages (30+ visuals). | Power BI modeling MCP cannot create report visuals directly; layout patched via pbix zip. | User must **Save** in Desktop to persist measures, then run layout script (or use `zension_reports.pbix` after close). |

## Phase 7 Detail (2026-06-22)

### Build command

```powershell
.venv\Scripts\dbt.exe build --select staging+ --profiles-dir . --quiet
```

### Initial failures (4 tests)

| Test | Failures | Root cause |
| ---- | -------- | ---------- |
| `unique_fct_subscription_monthly_snapshots_subscription_id` | 712 | Wrong test — grain is subscription × month, not subscription alone |
| `unique_fct_subscription_monthly_snapshots_snapshot_month` | 39 | Wrong test — multiple subs share a month |
| `relationships_fct_subscriptions_order_id__order_id__ref_fct_orders_` | 5 | Subscriptions reference soft-deleted orders (`stg_crm__tos_orders` filters `deleted = false`) |
| `relationships_fct_payment_attempts_payment_id__payment_id__ref_fct_payments_` | 12 | Payment-history rows with `has_valid_payment = false` (no CRM payment match) |

### Post-fix build

- **456 / 456 nodes succeeded** (`target/run_results.json`)
- **382 data tests** (down from 384 after removing 2 erroneous `unique` tests)

### Grain validation (`dbt show`)

| Mart | Design brief grain | Observed |
| ---- | ------------------ | -------- |
| `fct_subscriptions` | 1 row / subscription | 826 rows, 826 distinct `subscription_id`, 0 duplicates |
| `dim_customers` | 1 row / customer | 2697 rows, 2697 distinct `customer_id`, 0 duplicates |

Row counts are below source totals (900 subs, 2956 accounts) because staging excludes soft-deleted CRM rows — expected per design brief §5.

### Semantic layer (`ENABLE_SEMANTIC_LAYER: true`)

```powershell
.venv\Scripts\dbt.exe compile --profiles-dir .
.venv\Scripts\dbt.exe parse --profiles-dir .
```

- `target/semantic_manifest.json`: **24 semantic models**, **41 metrics** — compiles without errors.

### Blockers

None. All compile and test failures resolved within validation scope (no new models, `design_brief.md` unchanged).

---

## Feedback Cycle 2 — Pass 2 (2026-06-24)

**Trigger:** `client_feedback.md` cycle 2; `design_brief.md` approved; phases 3–8.

### dbt models touched

| Layer | Models |
| ----- | ------ |
| Staging | `stg_crm__tos_subscriptions` (`is_kifed`), `stg_crm__tos_payments` (`paid_at`, `is_recurring_payment`) |
| Intermediate | `int_finance_reconciliation` (collected `coalesce(payment_timestamp, created_at)`; invoiced `coalesce(invoice_date, settlement_date, created_at)`), `int_refunds` (CRM only), `int_subscription_snapshots_monthly` (quarter flags, churn denominator excludes waiting-for-delivery), `int_payment_attempts` (`is_recurring_installment` via parent payment), `int_subscriptions` (`is_kifed`, `is_upgraded_or_kifed`), `int_orders` (`first_paid_at`) |
| Marts | `fct_subscription_monthly_snapshots`, `fct_subscriptions`, `fct_payment_attempts`, `fct_payments` (`paid_at`), `fct_orders` (`first_paid_at`) |
| Semantic | `semantic_models.yml` — churn quarter-scoped, recurring payment failure, CRM-only refunds, upgrade includes KIFed |

### Build command

```powershell
.venv\Scripts\dbt.exe build --select stg_crm__tos_subscriptions+ stg_crm__tos_payments+ int_refunds+ int_finance_reconciliation+ int_subscription_snapshots_monthly+ int_payment_attempts+ int_orders+ --profiles-dir . --quiet
```

**Result:** PASS (exit 0).

### Warehouse validation (`dbt show`)

| KPI | Expected | Observed |
| --- | -------- | -------- |
| Finance variance (all-time) | ~27,821 SAR | collected 901,936 − invoiced 874,115 = **27,821** |
| Refund amount (CRM) | ~64,697 SAR | **64,697** (81 rows) |
| Payment failure rate (recurring only) | << 80% | **40.4%** (1,052 recurring attempts) |

### Power BI (`powerbi/zension.pbix`, Desktop port 62938)

- Refreshed partitions: `fct_finance_reconciliation_monthly`, `fct_refunds`, `fct_subscription_monthly_snapshots`, `fct_orders`, `fct_payment_attempts`, `fct_subscriptions`
- Removed stale model columns (`is_active_at_month_start`, `is_quarter_start_month`, `year_quarter`, `days_payment_to_delivery`); updated M partitions to explicit `NativeQuery` for snapshot/orders/attempts tables
- Recreated **Churn Rate** measure (quarter-scoped via `is_active_at_quarter_start`)
- Relationships per `report_build_guide.txt` already active: `fct_orders[program_id]`, `fct_orders[customer_id]`, `fct_subscriptions[program_id]`; `fct_subscription_monthly_snapshots[program_id]` left inactive (ambiguous path via `dim_channel_partners`)

### DAX spot-check (`dax_query_operations`)

| Measure | Value |
| ------- | ----- |
| Finance Variance (SAR) | 27,820.57 |
| Refund Amount (SAR) | 64,697 |
| Payment Failure Rate | 40.4% |
| Customers with Outstanding Payments | 1,210 |
| Active Subscription Count | 235 |

**Manual step:** Save `zension.pbix` in Power BI Desktop to persist MCP changes.

### Build-time doc fix (not Pass 1)

`int_finance_reconciliation` invoiced month bucketing uses `coalesce(invoice_date, settlement_date, created_at)` because paid invoices have null `invoice_date` in CRM (1,664 rows; settlement_date populated).

---

## Feedback Cycle 3 — Pass 2 (2026-06-24)

**Trigger:** `client_feedback.md` cycle 3 (measure audit); `design_brief.md` approved; phases 4, 5, 7, 8.

### dbt models touched

| Layer | Models |
| ----- | ------ |
| Staging | `stg_crm__tos_subscriptions` (removed staging-only `is_mrr_eligible`; eligibility enforced in `int_subscriptions`) |
| Intermediate | `int_subscriptions`, `int_payments_unified`, `int_subscription_snapshots_monthly`, `int_invoices` (verified cycle-3 flags) |
| Marts | `fct_subscriptions`, `fct_subscription_monthly_snapshots`, `fct_payments` (+ `reconciliation_gap_reason`), `fct_invoices`, `fct_payment_attempts` (`is_outstanding_retry_failure`) |

### Build command

```powershell
.venv\Scripts\dbt.exe build --select stg_crm__tos_subscriptions+ stg_crm__aos_invoices+ int_payments_unified+ int_subscription_snapshots_monthly+ int_subscriptions+ fct_subscription_monthly_snapshots+ fct_subscriptions+ fct_payments+ fct_invoices+ fct_payment_attempts+ --profiles-dir . --quiet
```

**Result:** PASS (exit 0, ~40s).

### Warehouse validation (`dbt show`)

| KPI | Expected | Observed |
| --- | -------- | -------- |
| Active subs / MRR-eligible / MRR | 235 / 166 / 43,219 SAR | **235 / 166 / 43,219.27** |
| Invoiced revenue (paid) | ~874,115 SAR | **874,115.43** |
| PSP reconciliation (collected) | no_psp_reference + missing_in_psp | **1,361** + **51** |
| Q4 2026 churn (mart) | ~3.43% (8 / 233) | churned **8**, active at quarter start **233** → **3.43%** |
| Pre-order share | 0% (0 preorders / 781 eligible) | **0 / 781** |

### Power BI (`powerbi/zension.pbix`, Desktop port 62938)

- Refreshed partitions: `fct_subscription_monthly_snapshots`, `fct_orders`, `fct_payment_attempts` (partition SQL updated for `is_outstanding_retry_failure`; removed stale `is_retry_indicator` column)
- Updated `_KPIs` measures: **Churn Rate** (quarter-scoped, defaults to current quarter), **Upgrade Rate** (quarter-scoped from snapshots), **Pre-order Share** (0% not BLANK), **Customers with Outstanding Payments** (unpaid ∪ retry-queue only)
- Unchanged (already correct): MRR, Avg Subscription Term, Invoiced/Collected Revenue, Program Subscription Utilization % (`0.0\x` multiplier format)

### DAX spot-check (`dax_query_operations`)

| Measure | Value |
| ------- | ----- |
| Churn Rate (Q4 2026 slicer) | **3.43%** |
| Pre-order Share | **0%** |
| Customers with Outstanding Payments | **69** (was 1,210) |
| MRR (SAR) | 43,219 |
| Active Subscription Count | 235 |
| Invoiced Revenue (SAR) | 874,115 |
| Collected Revenue (SAR) | 901,936 |
| Finance Variance (SAR) | 27,821 |

**Manual step:** Save `zension.pbix` in Power BI Desktop to persist MCP changes.

### Open decisions (documented; defaults applied)

- MRR: exclude 69 subs without pricing FK (current behavior)
- Upgrade numerator: includes KIFed (`is_kifed_in_month`)
- Outstanding: unpaid invoices ∪ retry-queue failures only
- Program utilization: keep `AVERAGEX` multiplier display






