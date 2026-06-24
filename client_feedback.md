# Client Feedback

> **Who fills this:** Data engineer + data analyst — after the client sends review comments.  
> **What happens next:** Run **Feedback Re-run** from [`dbt_ai_agent_prompts_generalized.md`](C:\wamp64\www\dbt-ai-guide\dbt_ai_agent_prompts_generalized.md) **twice** per cycle: pass 1 updates `requirements.md` + `design_brief.md`, sets `Status: pending approval` on **design_brief.md only** and stops; after you approve `design_brief.md`, **tell the agent it is approved** (e.g. `Design brief is approved — continue with Pass 2`); pass 2 implements from the design brief.

---

| Date | Cycle | Deliverable reviewed |
| ---- | ----- | -------------------- |
| 2026-06-23 | 2 | `powerbi/zension.pbix` v1 — 28 `_KPIs` measures, 5 report pages |

## Changes

| KPI / area | What the client said | Agreed fix (definition or behavior) | Phases |
| ---------- | -------------------- | ----------------------------------- | ------ |
| Finance Variance (SAR) | "Reconciliation shows zero but collected (901,936) and invoiced (874,115) don't match — we expect ~27,821 SAR gap." | Monthly `SUM(collected) − SUM(invoiced)`; bucket collected by `date_trunc('month', coalesce(payment_timestamp, created_at))` in `int_finance_reconciliation.sql` | 1, 4, 5, 7, 8 |
| Refund Amount (SAR) | "Refund total is 3.9M SAR — CRM shows ~64,697 SAR refunded." | Single source of record: CRM `tos_payments` refunded rows only (dedup CRM+PSP union in `int_refunds.sql` or split measures). **Confirm with Finance** if PSP should be separate KPI | 1, 4, 5, 7, 8 |
| Churn Rate | "We asked for churn per quarter — not a lifetime 22.55% number." | Quarter-scoped: churned in selected quarter ÷ active at quarter start; use snapshot flags per month not lifetime `DISTINCTCOUNT`. Denominator = Active + `service_start_date` only (exclude `Waiting_For_Delivery`). **Confirm with Product** | 1, 4, 6, 8 |
| Payment Failure Rate | "80% failure rate is wrong — we only care about recurring installments." | Failed ÷ total **recurring installment** attempts only (not all `tos_payment_history`). **Confirm filter with Product** | 1, 3, 7, 8 |
| Upgrade Rate | "Upgrade rate should include KIFed, not just Upgraded." | Add `is_kifed` for statuses `kifed`, `auto_kifed`; numerator = upgraded + kifed. **Confirm with Product** if KIFed is upgrade vs churn | 1, 3, 8 |
| Active Subscription Count | "Active subs look wrong when I slice by partner or program — what is your definition of active?" | **Definition:** `subscription_status = Active` AND `service_start_date IS NOT NULL` (device delivered). Global total (235) is correct. **Not** the same as program limit utilization, which also counts `Waiting_For_Delivery`. By-partner/program breakdowns need `fct_subscriptions[program_id] → dim_programs` relationship active (see slicers row). | 1, 8 |
| Pre-order Share | "Card is blank — should show 0% when there are no pre-orders." | `IF(EligibleOrders=0, BLANK(), DIVIDE(Preorders, EligibleOrders, 0))` — show 0% when eligible > 0 and preorders = 0 | 8 |
| Avg Subscription Term (Months) | "Average term should match MRR scope." | `AVERAGEX` over `subscription_term_months` where `is_mrr_eligible = TRUE` (align with semantic layer) | 8 |
| Customers with Outstanding Payments | "Outstanding customers shows 1,270 — should be ~1,210." | `COUNTROWS(SUMMARIZE(UNION(...), customer_id))` — dedupe customers in both unpaid-invoice and failed-payment sets | 8 |
| Program Subscription Utilization % | "Shows 307% — utilization over 100% is confusing." | Ratio = (active + waiting) subs ÷ limit; display as **multiplier (×)** e.g. `3.1×`, not `0.0%` on a ratio already > 1. **Confirm display with Product** | 8 |
| Disabled Program Count | "Disabled programs card is blank — should be 0." | `COALESCE(CALCULATE(COUNTROWS(dim_programs), is_disabled_program=TRUE), 0)` | 8 |
| Avg Days Payment to Delivery | "Which payment date are you using? `payment_timestamp` is empty in CRM." | Average days from **first paid payment** to `delivered_on`; paid date = `coalesce(payment_timestamp, created_at)` on paid CRM payments | 1, 8 |
| Median Order to Delivery Days | "Median 0 days doesn't work for SLA reporting." | Keep median for now but document that many deliveries are same-day (median 0 is arithmetically correct). **Confirm with Product** whether to switch to P90 | 1, 8 |
| Program / customer slicers | "Breakdowns by program and customer don't filter correctly on detail pages." | Activate inactive relationships: `fct_orders[program_id]`, `fct_subscriptions[program_id]`, `fct_orders[customer_id]` → dimension tables per `report_build_guide.txt` | 8 |

## Phases to re-run this cycle

List every phase number needed **once** (union of the Phases column above):

```
1, 3, 4, 5, 6, 7, 8
```

> **Phase guide (pick the minimum):**  
> **1** — KPI definition changed → update `design_brief.md`  
> **3** — row filters / status flags in staging  
> **4** — joins, reconciliation, intermediate logic  
> **5** — mart columns or grain  
> **6** — semantic layer metrics  
> **7** — `dbt build` + tests (almost always include if 3–6 ran)  
> **8** — BI measures or report (when `ENABLE_BI_DELIVERY: true`)

**Suggested run order:** Confirm open items with client (refund source, recurring filter, KIFed, churn denominator, utilization display, median vs P90) → **Feedback Re-run pass 1** (docs) → approve `design_brief.md` → **Feedback Re-run pass 2** (phases above) → spot-check Finance Variance ≈ 27,821 SAR and Refund Amount ≈ 64,697 SAR.

---

## Example (do not use)

<!--
| KPI | What the client said | Agreed fix | Phases |
| Revenue | Exclude cancelled orders | SUM where status not cancelled | 1, 3, 7 |
| Conversion card | Blank should be 0% | DIVIDE with 0 fallback | 8 |

Phases to re-run: 1, 3, 7, 8
-->
