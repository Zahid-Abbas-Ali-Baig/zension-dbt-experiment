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
- What share of orders are pre-order vs standard order, and what is average time from payment to delivery?
- Which device models (brand, storage, color) sell most by partner?

**Subscriptions**

- How many subscriptions are Active, Waiting for Delivery, Cancelled, or Defaulted by partner?
- What is monthly recurring revenue (MRR) and average subscription term by program?
- What is churn rate and upgrade rate (KIFed / Upgraded statuses) per quarter?

**Payments & finance**

- What is collected revenue vs invoiced revenue vs Zoho Books recognized revenue by month?
- What is payment failure rate on recurring installments, and how many customers are on retry?
- What is refund volume and credit-note value by partner and reason?

**Customers**

- How many verified customers (Nafath + mobile OTP) by corporate company (CEP)?
- What is average devices-per-customer and subscription limit utilization?
- Which customers have outstanding payments or expired cards?

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

## Constraints and Notes

- **Market:** Saudi Arabia — VAT applies; country-level tax IDs configured per `tos_countries.zoho_tax_id`
- **Currency:** Assumed SAR for KSA programs (confirm with finance)
- **Exclude from revenue KPIs:** voided orders, fully refunded payments, subscriptions in Cancelled / Returned status (unless reporting gross vs net separately)
- **Pre-order revenue:** Jarir/Axiom may collect payment before delivery; subscription and device activation occur at delivery — do not count as active MRR until `service_start_date` is set
- **Identity:** customers require Nafath and/or mobile OTP verification per program rules; national ID is primary identifier
- **Partner isolation:** each B2B partner sees only their channel-partner-scoped data via OAuth `client_credentials`
- **FNF:** treated as generic partner in code today — business rules require stakeholder confirmation before reporting or SLAs are applied
- **Communications:** transactional email/SMS only; no Mailchimp Marketing audience or campaign management in platform
- **Environments:** dev, staging, preprod, sandbox, prod — reporting must target production CRM and Zoho org only

---

