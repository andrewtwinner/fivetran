# NorthShelf dbt Project

dbt transformation layer for NorthShelf Retail Group.
Runs on top of Fivetran-replicated data from MySQL (AWS RDS) into Snowflake.

## Stack
- **Source:** MySQL 8 on AWS RDS → Fivetran CDC → Snowflake
- **Transform:** dbt Core (this project)
- **Destination schema:** Snowflake (`fivetran_db.northshelf`)
- **Orchestration:** Fivetran triggers dbt run after every sync

## Project Structure

```
models/
├── staging/          Views — 1:1 with Fivetran raw tables, light cleaning only
├── intermediate/     Tables — business logic, LTV calculation, RFM scoring
└── marts/            Tables — analytics-ready, BI/AI-ready output
```

## Models

| Model | Layer | Purpose |
|-------|-------|---------|
| stg_customers | Staging | Cleaned customers, deleted rows filtered |
| stg_orders | Staging | Cleaned orders, net_revenue derived, incremental |
| stg_order_items | Staging | Cleaned line items |
| stg_products | Staging | Active products incl. schema-change columns |
| stg_inventory_events | Staging | Append-only stock movement log |
| int_customer_lifetime_value | Intermediate | LTV, RFM scores, customer segments |
| dim_customers | Mart | CMO segments, churn flags, AI feature store |
| fct_orders | Mart | CFO trading dashboard, marketing attribution |
| fct_inventory_snapshot | Mart | Real-time stock position, reorder alerts |

## Running locally

```bash
# Install dbt with Snowflake adapter
pip install dbt-snowflake

# Copy profiles.yml to ~/.dbt/profiles.yml and fill in your credentials

# Test connection
dbt debug

# Run all models
dbt run

# Run tests
dbt test

# Run a specific model and its dependencies
dbt run --select dim_customers+
```
