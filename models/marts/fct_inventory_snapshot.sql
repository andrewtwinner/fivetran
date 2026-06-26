-- models/marts/fct_inventory_snapshot.sql
-- Purpose: Real-time inventory position per SKU per location.
-- Powers: Head of E-Commerce stock dashboard and ML demand forecasting model.
-- Reads from append-only inventory_events log — efficient, no full product table scans.

{{
  config(
    materialized = 'table'
  )
}}

WITH running_inventory AS (
    SELECT
        ie.product_id,
        ie.store_id,
        ie.location,
        SUM(ie.quantity_delta)                              AS current_stock_units,
        MAX(ie.event_timestamp)                             AS last_movement_at,
        COUNT(CASE WHEN ie.event_type = 'sale'    THEN 1 END) AS total_units_sold,
        COUNT(CASE WHEN ie.event_type = 'restock' THEN 1 END) AS total_restocks,
        COUNT(CASE WHEN ie.event_type = 'return'  THEN 1 END) AS total_returns

    FROM {{ ref('stg_inventory_events') }} ie
    GROUP BY ie.product_id, ie.store_id, ie.location
)

SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.brand,
    p.unit_price,
    p.unit_cost,

    -- These columns were added by the Scene 3 ALTER TABLE schema change.
    -- Fivetran propagated them automatically. dbt picks them up here with zero changes.
    p.warehouse_location,
    p.return_rate_pct,

    ri.location,
    ri.current_stock_units,
    ri.last_movement_at,
    ri.total_units_sold,
    ri.total_returns,

    -- Derived financial metrics
    (ri.current_stock_units * p.unit_cost)              AS stock_value_at_cost,
    (ri.current_stock_units * p.unit_price)             AS stock_value_at_retail,

    -- Stock health status for reorder alerts
    CASE
        WHEN ri.current_stock_units <= 10 THEN 'critical'
        WHEN ri.current_stock_units <= 30 THEN 'low'
        ELSE 'healthy'
    END AS stock_status,

    -- Actual return rate from events vs. declared rate on product
    CASE
        WHEN ri.total_units_sold > 0
        THEN ROUND(ri.total_returns / ri.total_units_sold * 100, 1)
        ELSE 0
    END AS return_rate_actual_pct

FROM {{ ref('stg_products') }} p
LEFT JOIN running_inventory ri
    ON p.product_id = ri.product_id
