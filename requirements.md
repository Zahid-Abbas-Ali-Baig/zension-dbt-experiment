# requirements — Zension Platform

> Business-oriented view derived from codebase analysis. For technical detail see [requirements.md](requirements.md).

## Domain Summary

B2B device reseller and subscription management platform operating in Saudi Arabia (KSA). Channel partners (Jarir, CEP, Axiom, FNF) sell hardware devices—often bundled with monthly subscriptions, damage protection, and corporate employee programs—through Zaam-branded customer and partner channels.

Core processes:

**Partner setup** → **customer onboarding (identity + payment profile)** → **browse / order** → **checkout & card capture** → **invoice** → **device delivery** → **active subscription** → **recurring billing** → **renewal or closure**

Two commercial motions coexist:

- **Direct / CEP** — end customers self-serve via ops portal; corporate email-domain validation for employee programs
- **B2B pre-order (Jarir, Axiom)** — partner creates order before delivery; subscription activates at device handover

## Business Goals

- Sell devices and subscriptions through multiple channel partners from one operational platform
- Manage the full subscription lifecycle: signup, delivery activation, recurring payments, cancellation, refund, and upgrade
- Automate invoicing and accounting sync to Zoho Books for finance compliance (VAT, credit notes, journals)
- Verify customer identity (Nafath) and credit eligibility (CRDM) before high-value commitments
- Notify customers and partners at key events via email (Mailchimp Transactional) and SMS (Unifonic)
- Give each partner governed API access without sharing another partner’s data
- Provide operations teams a single CRM (SuiteCRM) for orders, devices, subscriptions, and support cases

## Pain Points

- **Revenue and subscription metrics differ by partner** — Jarir and Axiom have bespoke flows (pre-order, delivery activation, partner templates); FNF scope is undefined in application logic
- **Dual payment truth** — card processing lives in an external Payment Service; Zoho Books holds accounting invoices; reconciliation is manual or scheduler-dependent
- **No single executive dashboard** — operational data sits in SuiteCRM MySQL; finance data partially mirrors in Zoho; no governed analytics layer in this codebase
- **Partner branding inconsistency** — Axiom is configured in CRM but customer communications use Samsung-branded templates
- **Incomplete partner coverage** — FNF has API credentials but no documented or coded business rules equivalent to Jarir
- **Customer portal not in this repository** — `zaam.life` frontend is external; business rules and UX cannot be fully audited here
- **Invoice sync is one-way** — CRM pushes to Zoho; inbound payment-status webhooks from Zoho are not implemented
- **Ad-hoc reporting risk** — teams may query production CRM tables directly without consistent definitions for active subscription, recognized revenue, or churn

## Business Questions

**Sales & orders**

- How many orders and what gross merchandise value (GMV) by channel partner, program, and month?
- What share of orders are pre-order vs standard order (show 0% when none), and what is average time from payment to delivery?
- Which device models (brand, storage, color) sell most by partner?

**Subscriptions**

- How many subscriptions are Active, Waiting for Delivery, Cancelled, or Defaulted by partner?
- What is monthly recurring revenue (MRR) and average subscription term by program?
- What is churn rate per quarter (not a lifetime rate) and upgrade rate including KIFed and Upgraded statuses per quarter (from monthly snapshots, not all-time subscription counts)?

**Payments & finance**

- What is collected revenue vs invoiced revenue vs Zoho Books recognized revenue by month, and what is the monthly finance variance (collected − invoiced)?
- What is payment failure rate on **recurring installment** attempts only (excluding one-off card captures), and how many customers are on retry?
- What is refund volume from CRM paid/refunded payments (source of record ~64,697 SAR in discovery) and credit-note value by partner and reason?

**Customers**

- How many verified customers (Nafath + mobile OTP) by corporate company (CEP)?
- What is average devices-per-customer and program subscription limit utilization (active + waiting-for-delivery subs vs limit)?
- Which customers have outstanding payments (unpaid invoices or retry-queue failures only) or expired cards?

**Operations & partners**

- What is order-to-delivery SLA by partner and region?
- How many partner webhook (SNS) status updates failed or were delayed?
- Which programs are disabled or over subscription / payment-method limits?

## Source Systems

| System | Role | Data of record |
|--------|------|----------------|
| **SuiteCRM (tos-ksa)** | Operational CRM — orders, subscriptions, devices, customers, payments | MySQL (`tos_*` modules, `accounts`, `aos_invoices`) |
| **Payment Service** | Card capture, recurring billing, refunds | External PSP (vendor not named in code) |
| **Zoho Books** | Invoicing, customer contacts, credit notes, journals | Zoho cloud |
| **API Middleware (AWS)** | Partner and ops API authentication; traffic to CRM | API Gateway + Lambda (no local DB) |
| **Nafath** | Saudi national ID verification | External identity provider |
| **CRDM** | Credit / risk decisions | External API |
| **Mailchimp Transactional** | Order, payment, activation, OTP emails | Mandrill templates |
| **Unifonic** | SMS cart links, payment confirmations, OTP | External messaging |
| **AWS SNS** | Outbound partner order-status webhooks | Event notifications |

Primary analytical source for operations: **SuiteCRM MySQL**. Finance alignment: **Zoho Books** (synced from CRM on payment and invoice events).

## Reporting Preferences

- **Grain:** order-level for sales; subscription-level for recurring revenue; payment-installment-level for collections; device-level for fulfillment and asset tracking
- **Dimensions:** channel partner, program, corporate company (CEP), device SKU, order type (order / pre-order), subscription status, payment status
- **Rollups:** daily operational dashboards; weekly partner performance; monthly executive summary (GMV, MRR, active subs, churn, refunds)
- **Finance alignment:** monthly reconciliation report matching CRM payments ↔ Zoho invoices ↔ Payment Service settlements
- **Semantic definitions needed:** active subscription, recognized revenue, refund-adjusted revenue, pre-order vs fulfilled revenue
- **Delivery:** BI tool on star schema or semantic layer preferred over direct production CRM queries
- **BI slicers:** program and customer filters on detail pages require active `fct_orders` / `fct_subscriptions` relationships to `dim_programs` and `dim_customers` (see `powerbi/report_build_guide.txt`)

## Constraints and Notes

- **Market:** Saudi Arabia — VAT applies; country-level tax IDs configured per `tos_countries.zoho_tax_id`
- **Currency:** Assumed SAR for KSA programs (confirm with finance)
- **Exclude from revenue KPIs:** voided orders, fully refunded payments, subscriptions in Cancelled / Returned status (unless reporting gross vs net separately)
- **Pre-order revenue:** Jarir/Axiom may collect payment before delivery; subscription and device activation occur at delivery — do not count as active MRR until `service_start_date` is set
- **Active subscription (reporting):** `subscription_status = Active` AND `service_start_date IS NOT NULL` (device delivered). Distinct from program limit utilization, which also counts `Waiting_For_Delivery`
- **Finance variance:** monthly `SUM(collected) − SUM(invoiced)`; bucket collected payments by month of `coalesce(payment_timestamp, created_at)` when `payment_timestamp` is null in CRM
- **Refund KPI:** CRM `tos_payments` with `payment_status = refunded` is the source of record for refund amount SAR (pending Finance confirmation on whether PSP refunds warrant a separate KPI)
- **Churn rate (Executive):** quarter-scoped by default — churned in selected (or current) quarter ÷ active at quarter start (`service_start_date` set; exclude `Waiting_For_Delivery` from denominator). Unfiltered lifetime aggregation overstates the rate (audit: 5.43% all-time vs ~3.43% for Q4 2026 with quarter slicer)
- **Upgrade rate:** quarter-scoped numerator/denominator from monthly subscription snapshots (`is_upgraded_in_month`, `is_kifed_in_month`) — not lifetime all-time counts. Numerator includes `Upgraded`, `kifed`, and `auto_kifed` (pending Product confirmation that KIFed is upgrade vs churn)
- **MRR eligibility:** active subscriptions with linked `subscription_pricing_id` and `monthly_subscription_amount` only (~166 of 235 active subs in cycle-3 audit). **69 active subs lack pricing FK** — pending Product/Finance decision: (a) exclude from MRR (current), (b) impute from order pricing, or (c) show dashboard warning. Average subscription term must use the same scope
- **Outstanding payments:** distinct customers with unpaid invoices OR retry-queue payment failures only (`is_retry_queue` on PSP transactions / recent `fct_payment_attempts`) — **not** all historical failed payment attempts (audit inflated count to ~1,210). Pending Product confirmation of "outstanding" definition
- **Collected revenue:** CRM `tos_payments` remains KPI source of record (~901,936 SAR in audit). Reconciliation workflow flags on unified payments: `no_psp_reference` (paid CRM rows without PSP ID), `missing_in_psp` (PSP lookup failed). Pending Finance decision on authority when CRM and PSP disagree
- **Invoiced revenue:** validate `SUM(invoice_amount_sar) WHERE is_paid` in mart against Zoho/CRM. Finance to define paid-invoice rule for `aos_invoices` / `tos_invoices` (raw `aos_invoices.status` NULL in MySQL complicates live verification; mart total ~874,115 SAR in audit)
- **Pre-order share:** display **0%** when there are no pre-orders (never BLANK on executive cards)
- **Payment failure rate:** failed ÷ total attempts on **recurring installment** rows in `tos_payment_history` only (pending Product confirmation on exact filter)
- **Payment-to-delivery SLA:** average days from **first paid CRM payment** (`coalesce(payment_timestamp, created_at)` on paid rows) to `delivered_on`
- **Order-to-delivery median:** median of delivery days; many same-day deliveries make median 0 arithmetically correct (pending Product confirmation on switching to P90)
- **Program utilization display:** ratio (active + waiting subs) ÷ program limit; when > 100% show as multiplier (e.g. `3.1×`), not as a percentage (pending Product confirmation)
- **Identity:** customers require Nafath and/or mobile OTP verification per program rules; national ID is primary identifier
- **Partner isolation:** each B2B partner sees only their channel-partner-scoped data via OAuth `client_credentials`
- **FNF:** treated as generic partner in code today — business rules require stakeholder confirmation before reporting or SLAs are applied
- **Communications:** transactional email/SMS only; no Mailchimp Marketing audience or campaign management in platform
- **Environments:** dev, staging, preprod, sandbox, prod — reporting must target production CRM and Zoho org only

---

