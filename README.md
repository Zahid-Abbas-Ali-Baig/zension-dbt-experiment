# Zension dbt Analytics Project

B2B device reseller and subscription management analytics for Saudi Arabia (KSA). Channel partners (Jarir, CEP, Axiom, FNF) sell hardware and monthly subscriptions through Zaam-branded channels. This dbt project transforms SuiteCRM and Payment Service data from PostgreSQL into a governed star schema with a MetricFlow semantic layer.

**Design brief status:** `approved` (see [`design_brief.md`](design_brief.md))

**Semantic layer:** `ENABLE_SEMANTIC_LAYER=true` — metrics defined in [`models/semantic/semantic_models.yml`](models/semantic/semantic_models.yml)

---

## Layer Map

```
source (29 tables)
  └── staging/          stg_crm__*, stg_payments__*     (+schema: staging)
        └── intermediate/   int_*                        (+schema: intermediate)
              └── marts/          fct_*, dim_*, bridge_* (+schema: marts)
                    └── semantic/   semantic_models.yml (24 models, 41 metrics)
```

| Layer | Schema | Materialization | Models |
|-------|--------|-----------------|--------|
| Staging | `staging` | view | 29 staging models |
| Intermediate | `intermediate` | view | 20 intermediate models |
| Marts | `marts` | table | 14 facts, 10 dimensions, 1 bridge |
| Semantic | — | YAML (MetricFlow) | 24 semantic models, 41 metrics |

---

## Environment Setup

| Variable | Value |
|----------|-------|
| `PROJECT_ROOT` | `.` (this directory) |
| `PROJECT_NAME` | `zension` |
| `WAREHOUSE_TYPE` | `postgres` |
| `DATABASE_NAME` | `zension` |
| `SOURCE_NAME` / `SCHEMA_NAME` | `source` |
| `STAGING_SCHEMA` | `staging` |
| `INTERMEDIATE_SCHEMA` | `intermediate` |
| `MARTS_SCHEMA` | `marts` |

### Prerequisites

1. Python virtual environment with dbt-core 1.9.4 + postgres adapter (`.venv`)
2. PostgreSQL warehouse with `zension.source` schema (322 tables; 29 in modeling scope)
3. Local [`profiles.yml`](profiles.yml) (not committed with production passwords)

```powershell
# From PROJECT_ROOT
python -m venv .venv
.venv\Scripts\pip install dbt-postgres
dbt deps --profiles-dir .
```

### profiles.yml

```yaml
zension:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      dbname: zension
      user: postgres
      password: <local-only>
      schema: source
      threads: 4
```

> Use `.venv\Scripts\dbt.exe` for Postgres. System Fusion dbt does not include the Postgres adapter.

---

## Execution Commands

```powershell
# Install packages
.venv\Scripts\dbt.exe deps --profiles-dir .

# Build staging → intermediate → marts (recommended)
.venv\Scripts\dbt.exe build --select staging.* intermediate.* marts.* --profiles-dir .

# Run only
.venv\Scripts\dbt.exe run --select marts.* --profiles-dir .

# Test only
.venv\Scripts\dbt.exe test --select marts.* --profiles-dir .

# Compile (validates SQL + semantic manifest)
.venv\Scripts\dbt.exe compile --profiles-dir .

# Parse semantic layer resources
.venv\Scripts\dbt.exe parse --profiles-dir .
```

Compile output (verified): **74 models, 384 tests, 41 metrics, 24 semantic models**.

---

## KPI Traceability Matrix

Staging → intermediate → mart → semantic metric (actual model names from this project).

| # | Business question | Staging | Intermediate | Mart | Semantic metric |
|---|-------------------|---------|--------------|------|-----------------|
| Q1 | Orders & GMV by partner/program/month | `stg_crm__tos_orders`, `stg_crm__tos_programs`, `stg_crm__tos_channel_partners` | `int_orders` | `fct_orders` | `order_count`, `gmv_sar` |
| Q2 | Pre-order share & payment→delivery time | `stg_crm__tos_orders`, `stg_crm__tos_payments` | `int_orders`, `int_payments_crm` | `fct_orders`, `fct_payments` | `preorder_order_share`, `avg_days_payment_to_delivery` |
| Q3 | Top device models by partner | `stg_crm__tos_order_items`, `stg_crm__tos_zaam_skus`, `stg_crm__tos_master_skus` | `int_order_items`, `int_device_skus` | `fct_order_items`, `dim_device_skus` | `order_item_count` |
| Q4 | Subscriptions by status & partner | `stg_crm__tos_subscriptions`, `stg_crm__tos_channel_partners` | `int_subscriptions` | `fct_subscriptions` | `subscription_count`, `active_subscription_count` |
| Q5 | MRR & avg term by program | `stg_crm__tos_subscriptions`, `stg_crm__tos_subscription_pricing`, `stg_crm__tos_subscription_durations` | `int_subscriptions` | `fct_subscriptions`, `dim_subscription_durations` | `mrr_sar`, `avg_subscription_term_months` |
| Q6 | Churn & upgrade rate | `stg_crm__tos_subscriptions` | `int_subscriptions`, `int_subscription_snapshots_monthly` | `fct_subscription_monthly_snapshots`, `fct_subscriptions` | `churn_rate`, `upgrade_rate` |
| Q7 | Collected vs invoiced revenue | `stg_crm__tos_payments`, `stg_crm__aos_invoices` | `int_payments_unified`, `int_invoices`, `int_finance_reconciliation` | `fct_payments`, `fct_invoices`, `fct_finance_reconciliation_monthly` | `collected_revenue_sar`, `invoiced_revenue_sar`, `finance_variance_sar` |
| Q8 | Payment failure & retry | `stg_crm__tos_payment_history`, `stg_payments__transactions` | `int_payment_attempts`, `int_payments_psp` | `fct_payment_attempts`, `fct_psp_transactions` | `payment_failure_rate`, `customers_on_retry_count` |
| Q9 | Refunds & credit notes | `stg_crm__tos_payments`, `stg_crm__tos_credit_notes`, `stg_payments__refunds` | `int_refunds`, `int_credit_notes` | `fct_refunds`, `fct_credit_notes` | `refund_amount_sar`, `credit_note_count` |
| Q10 | Verified customers by CEP company | `stg_crm__accounts`, `stg_crm__tos_corporate_company` | `int_customers` | `dim_customers`, `dim_corporate_companies` | `verified_customer_count` |
| Q11 | Devices per customer & limit utilization | `stg_crm__tos_devices`, `stg_crm__tos_orders`, `stg_crm__tos_programs` | `int_customer_device_counts`, `int_programs` | `fct_devices`, `dim_programs` | `avg_devices_per_customer`, `program_subscription_utilization_pct` |
| Q12 | Outstanding payments & expired cards | `stg_crm__tos_payment_methods`, `stg_crm__aos_invoices`, `stg_crm__tos_payment_history` | `int_payment_attempts`, `int_invoices` | `dim_payment_methods`, `fct_invoices`, `fct_payment_attempts` | `expired_payment_method_count`, `customers_with_outstanding_payments` |
| Q13 | Order-to-delivery SLA | `stg_crm__tos_orders`, `stg_crm__tos_addresses` | `int_orders` | `fct_orders` | `median_order_to_delivery_days` |
| Q14 | Partner webhook failures | `stg_crm__tos_api_logs` | `int_partner_api_events` | `fct_partner_api_events` | `partner_api_failure_rate` |
| Q15 | Programs over limits | `stg_crm__tos_programs`, `stg_crm__tos_subscriptions` | `int_programs` | `dim_programs` | `programs_over_limit_count` |

---

## Semantic Metrics (§9)

All metrics are defined in [`models/semantic/semantic_models.yml`](models/semantic/semantic_models.yml).

| Metric | Type | Source mart | Business questions |
|--------|------|-------------|-------------------|
| `order_count` | simple | `fct_orders` | Q1 |
| `gmv_sar` | simple | `fct_orders` | Q1 |
| `preorder_order_share` | ratio | `fct_orders` | Q2 |
| `avg_days_payment_to_delivery` | simple | `fct_orders` | Q2, Q13 |
| `order_item_count` | simple | `fct_order_items` | Q3 |
| `subscription_count` | simple | `fct_subscriptions` | Q4 |
| `active_subscription_count` | simple | `fct_subscriptions` | Q4 |
| `mrr_sar` | simple | `fct_subscriptions` | Q5 |
| `avg_subscription_term_months` | simple | `fct_subscriptions` | Q5 |
| `churn_rate` | derived | `fct_subscription_monthly_snapshots` | Q6 |
| `upgrade_rate` | ratio | `fct_subscriptions` | Q6 |
| `collected_revenue_sar` | simple | `fct_payments` | Q7 |
| `invoiced_revenue_sar` | simple | `fct_invoices` | Q7 |
| `finance_variance_sar` | simple | `fct_finance_reconciliation_monthly` | Q7 |
| `payment_failure_rate` | ratio | `fct_payment_attempts` | Q8 |
| `customers_on_retry_count` | simple | `fct_psp_transactions` | Q8 |
| `refund_amount_sar` | simple | `fct_refunds` | Q9 |
| `credit_note_count` | simple | `fct_credit_notes` | Q9 |
| `verified_customer_count` | simple | `dim_customers` | Q10 |
| `avg_devices_per_customer` | derived | `fct_devices` | Q11 |
| `program_subscription_utilization_pct` | ratio | `dim_programs` | Q11, Q15 |
| `expired_payment_method_count` | simple | `dim_payment_methods` | Q12 |
| `customers_with_outstanding_payments` | derived | `fct_invoices`, `fct_payment_attempts` | Q12 |
| `median_order_to_delivery_days` | simple | `fct_orders` | Q13 |
| `partner_api_failure_rate` | ratio | `fct_partner_api_events` | Q14 |
| `programs_over_limit_count` | simple | `dim_programs` | Q15 |

**Time spine:** `dim_dates` configured with `time_spine.standard_granularity_column: full_date` for MetricFlow daily granularity.

---

## Agent Skills & Phase Sequence

| Phase | Skill | Output |
|-------|-------|--------|
| 0 — Discovery | `using-dbt-for-analytics-engineering` | [`design_brief.md`](design_brief.md) (approved) |
| 1 — Sources & staging | `using-dbt-for-analytics-engineering`, `running-dbt-commands` | `models/staging/`, `_sources.yml` |
| 2 — Intermediate | `using-dbt-for-analytics-engineering` | `models/intermediate/` |
| 3 — Marts | `using-dbt-for-analytics-engineering` | `models/marts/` star schema |
| 4 — Semantic layer | `building-dbt-semantic-layer` | `models/semantic/semantic_models.yml` |
| 5 — Documentation | This README, `_marts__models.yml` | KPI matrix, runbook |

---

## Codegen Macro Reference

Package: `dbt-labs/codegen` (see [`packages.yml`](packages.yml))

```powershell
# Source codegen (full schema)
.venv\Scripts\dbt.exe run-operation generate_source --args "{schema_name: source, database_name: zension, generate_columns: true, name: source}" --profiles-dir .

# Mart model YAML codegen
.venv\Scripts\dbt.exe run-operation generate_model_yaml --args "{model_names: ['fct_orders', 'fct_order_items', 'dim_customers', 'dim_channel_partners', 'dim_programs', 'dim_corporate_companies', 'dim_device_skus', 'dim_dates', 'fct_subscriptions', 'fct_subscription_monthly_snapshots', 'dim_subscription_pricing', 'dim_subscription_durations', 'fct_payments', 'fct_payment_attempts', 'fct_psp_transactions', 'dim_payment_methods', 'fct_invoices', 'fct_invoice_line_items', 'fct_credit_notes', 'fct_finance_reconciliation_monthly', 'fct_devices', 'fct_device_journey_events', 'fct_partner_api_events', 'bridge_cp_skus', 'fct_refunds']}" --profiles-dir .

# Enrich codegen output with descriptions, KPI linkage, and tests
python scripts/enrich_marts_yml.py
```

---

## Mart Documentation & Tests

Column documentation, primary-key tests (`unique`, `not_null`), and foreign-key `relationships` tests live in [`models/marts/_marts__models.yml`](models/marts/_marts__models.yml).

---

## Key Business Definitions

| Term | Definition |
|------|------------|
| GMV-eligible order | `is_gmv_eligible = true` — excludes cancelled, rejected, expired |
| Active subscription | `subscription_status = active` AND `service_started_at IS NOT NULL` |
| MRR-eligible | Active subscription with valid pricing link |
| Collected revenue | CRM payments with `is_collected = true` |
| Invoiced revenue | Paid Zoho-synced invoices (`is_paid = true`, CRM-sourced) |

See [`design_brief.md`](design_brief.md) §1 and [`requirements.md`](requirements.md) for full domain context.
