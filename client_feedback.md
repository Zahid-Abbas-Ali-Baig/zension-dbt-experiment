# Client Feedback

> **Who fills this:** Data engineer + data analyst — after the client sends review comments.  
> **What happens next:** Run **Feedback Re-run** from [`dbt_ai_agent_prompts_generalized.md`](C:\wamp64\www\dbt-ai-guide\dbt_ai_agent_prompts_generalized.md) **twice** per cycle: (1) agent updates `requirements.md` + `design_brief.md`, sets `Status: pending approval` on **design_brief.md only** → you review; (2) set `design_brief.md` to `Status: approved` → run again to implement from the design brief.
>
> **Source for this cycle:** [`MEASURE_AUDIT_REPORT.md`](MEASURE_AUDIT_REPORT.md) — live MCP audit of 28 Power BI measures (2026-06-24). 19 measures match ground truth; **9 flagged** below.

---

| Date | Cycle | Deliverable reviewed |
| ---- | ----- | -------------------- |
| 2026-06-24 | 3 | `MEASURE_AUDIT_REPORT.md` — 28 `_KPIs` measures vs CRM (`mysql-mcp`), payments (`postgres-payments-mcp`), mart (`postgres-zension-mcp`), PBIX (`powerbi-modeling-mcp`) |

## Changes

| KPI / area | What the client said | Agreed fix (definition or behavior) | Phases |
| ---------- | -------------------- | ----------------------------------- | ------ |
| Churn Rate | "Executive churn card shows 5.43% — that can't be right for this quarter." (Audit: unfiltered DAX sums all snapshot history; Q4 2026 with slicer = 3.43%.) | Quarter-scoped by default: churned in selected (or current) quarter ÷ active at quarter start from `fct_subscription_monthly_snapshots`; rewrite `_KPIs[Churn Rate]` OR add mandatory `snapshot_quarter` slicer on Executive page. Denominator = delivered Active only (exclude `Waiting_For_Delivery`). | 1, 8 |
| Upgrade Rate | "Upgrade rate should be per quarter, not lifetime." (Audit: DAX uses all-time `fct_subscriptions` — 4/826 = 0.48%.) | Quarter-scoped numerator/denominator using `fct_subscription_monthly_snapshots` (`is_upgraded_in_month`, `is_kifed_in_month`). **Confirm with Product** that `kifed` / `auto_kifed` count as upgrades (spec pending). | 1, 4, 8 |
| MRR (SAR) | "Active subs are 235 but MRR only covers 166 — where did 69 go?" (Audit: active subs missing `subscription_pricing_id` or monthly amount excluded from `is_mrr_eligible`.) | **Confirm with Product/Finance:** exclude from MRR (current), impute from order pricing, or show warning on dashboard. Document decision in `requirements.md`; update `int_subscriptions.sql` if rule changes. | 1, 4, 5, 8 |
| Avg Subscription Term (Months) | "Average term should match MRR scope." (Audit: matches MRR-eligible subs at 12.33 months — but scope undefined in spec.) | Align denominator with MRR eligibility decision above; document in `requirements.md`. | 1, 8 |
| Customers with Outstanding Payments | "1,210 outstanding customers seems high." (Audit: DAX unions all unpaid invoices with **all historical** failed payment attempts.) | Redefine: unpaid `fct_invoices` UNION retry-queue failures only (`fct_psp_transactions.is_retry_queue` or recent `fct_payment_attempts`). **Confirm with Product** definition of "outstanding." | 1, 8 |
| Collected Revenue (SAR) | "Can we trust collected revenue against the payment service?" (Audit: measure matches CRM 901,936 SAR; 1,361 paid CRM rows have no PSP reference, 51 missing in PSP.) | CRM remains KPI source per spec; add reconciliation workflow on `int_payments_unified` (`no_psp_reference`, `missing_in_psp`). **Confirm with Finance** which system wins when they disagree. | 1, 4 |
| Invoiced Revenue (SAR) | "We need to validate invoiced total against Zoho/CRM." (Audit: mart = 874,115.43 SAR; raw `aos_invoices.status` NULL in MySQL — not verified live.) | Finance to define paid-invoice rule for `aos_invoices` / `tos_invoices`; validate against `SUM(invoice_amount_sar) WHERE is_paid` in mart. | 1, 4, 7 |
| Pre-order Share | "Card is blank — should show 0% when there are no pre-orders." (Audit: 0 eligible pre-orders; DAX returns BLANK.) | `IF(EligibleOrders = 0, 0, DIVIDE(Preorders, EligibleOrders, 0))` — show **0%** when no pre-orders (not BLANK). | 1, 8 |
| Program Subscription Utilization % | "307% is confusing — utilization over 100% should read as a multiplier." (Audit: `AVERAGEX` of program ratios = 3.07×; 3 programs over limit.) | **Confirm with Product:** keep `AVERAGEX(program_subscription_utilization_pct)` displayed as multiplier (e.g. `3.1×`) OR switch to `SUM(utilization subs) / SUM(limits)`. Format string already `0.0\x` in PBIX. | 1, 8 |

### Confirmed correct this cycle (no change required)

Audit verified live alignment for: **Active Subscription Count** (235 CRM = mart = PBIX), **GMV**, **Order Count**, **Collected Revenue** (CRM), **Refund Amount** (64,697 SAR), **Finance Variance** (27,820.57 SAR), **Payment Failure Rate** (40.4% recurring only), **Verified Customer Count** (2,290), and 10 other measures — see `MEASURE_AUDIT_REPORT.md` per-measure table.

## Phases to re-run this cycle

List every phase number needed **once** (union of the Phases column above):

```
1, 4, 5, 7, 8
```

> **Phase guide (pick the minimum):**  
> **1** — KPI definition changed → update `requirements.md` (business) and `design_brief.md` (technical); **approve design_brief.md** before code  
> **3** — row filters / status flags in staging  
> **4** — joins, reconciliation, intermediate logic  
> **5** — mart columns or grain  
> **6** — semantic layer metrics  
> **7** — `dbt build` + tests (almost always include if 3–6 ran)  
> **8** — BI measures or report (when `ENABLE_BI_DELIVERY: true`)

**Suggested run order:** Resolve open decisions (MRR pricing gap, outstanding definition, CRM vs PSP authority, utilization display, KIFed as upgrade) → **Feedback Re-run pass 1** (docs) → approve `design_brief.md` → **Feedback Re-run pass 2** (phases above) → spot-check Churn Rate with quarter slicer (expect ~3.43% for Q4 2026, not 5.43% unfiltered) and MRR scope after business sign-off.

---

## Example (do not use)

<!--
| KPI | What the client said | Agreed fix | Phases |
| Revenue | Exclude cancelled orders | SUM where status not cancelled | 1, 3, 7 |
| Conversion card | Blank should be 0% | DIVIDE with 0 fallback | 8 |

Phases to re-run: 1, 3, 7, 8
-->
