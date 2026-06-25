# Project Config

> Fill once per engagement. Attach alongside [`dbt_ai_agent_prompts_generalized.md`](dbt_ai_agent_prompts_generalized.md) when running any phase prompt.

## How to Use

1. Replace every `{{placeholder}}` below with your project values.
2. Set `REQUIREMENTS_DOC` and `DESIGN_BRIEF_DOC` paths (defaults: `requirements.md`, `design_brief.md`).
3. Attach this file when running phase prompts. Attach `requirements.md` starting at **Phase 1**.
4. The agent reads `config.md` at the start of every phase and substitutes values into commands and file paths.
5. After client review: fill [`client_feedback.md`](client_feedback.md), then run the **Feedback Re-run** prompt from the prompt library.

> **Security:** Do not commit real passwords. Use a local-only copy of this file or environment variables for production credentials.

---

## Variables

```
PROJECT_ROOT:        .                      # dbt project files created in current directory
REQUIREMENTS_DOC:    requirements.md
DESIGN_BRIEF_DOC:    design_brief.md
CLIENT_FEEDBACK_DOC: client_feedback.md     # filled by DE/analyst after client review
AI_EXECUTION_LOG:    AI_EXECUTION_LOG.md    # optional per-engagement log

PROJECT_NAME:        zension
WAREHOUSE_TYPE:      postgres
DATABASE_NAME:       zension
SCHEMA_NAME:         source                   # raw source schema (dbt staging sources only)
DB_HOST:             localhost
DB_PORT:             5432
DB_USER:             postgres
DB_PASSWORD:         admin99
DB_THREADS:          4

SOURCE_NAME:         source
STAGING_SCHEMA:      staging
INTERMEDIATE_SCHEMA: intermediate
MARTS_SCHEMA:        marts                    # Phase 8 BI semantic model source (not SCHEMA_NAME)

ENABLE_SEMANTIC_LAYER: true

BI_TOOL:             powerbi                  # Phase 8 — PBIP project delivery
BI_PBIP_DIR:         powerbi-project          # human saves .pbip + linked .Report/.SemanticModel here
```

> **Not in this file:** table lists, fact/dimension classifications, column renames, join keys, metrics, or business questions. Those are inferred from the requirements doc + schema discovery in Phase 1.

> **Alignment:** `DATABASE_NAME`, `SCHEMA_NAME`, and `WAREHOUSE_TYPE` here should match the source-system hints in [`requirements.md`](requirements.md).

> **Phase 8 human step:** Create folder `BI_PBIP_DIR` (`powerbi-project/`) if missing and save an empty `.pbip` into that folder in Power BI Desktop before running Phase 8. Desktop creates `{name}.pbip`, `{name}.Report/`, and `{name}.SemanticModel/` together.  
> **This project:** scaffold already at `C:\wamp64\www\zension-dbt-experiment\powerbi-project\` (`zension_pbi_as_code.pbip` + linked folders). Re-save only if starting fresh.

> **Phase 8 BI source:** Power BI imports from `MARTS_SCHEMA` (`marts`), not `SCHEMA_NAME` (`source`). Confirm in `dbt_project.yml` (`models.marts.+schema: marts`).

> **v1 scope:** One `SOURCE_NAME` and one `SCHEMA_NAME` per engagement. Additional source schemas require a future config extension.

---
