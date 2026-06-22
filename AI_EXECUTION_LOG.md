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
