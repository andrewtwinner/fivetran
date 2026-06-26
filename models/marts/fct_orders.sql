-- models/marts/fct_orders.sql
-- Purpose: The CFO's trading dashboard fact table.
-- Every order enriched with customer context and marketing attribution.
-- Incremental — only processes new/updated rows since last run.

{{
  config(
    materialized = 'incremental',
    unique_key   = 'order_id'
  )
}}

SELECT
    o.order_id,
    o.order_created_at,
    DATE_TRUNC('week',  o.order_created_at)     AS order_week,
    DATE_TRUNC('month', o.order_created_at)     AS order_month,

    -- Customer context
    o.customer_id,
    c.first_name || ' ' || c.last_name          AS customer_name,
    c.loyalty_tier,
    c.customer_segment,

    -- Order detail
    o.order_type,
    o.channel,
    o.store_id,
    o.order_status,
    o.order_total,
    o.discount_amount,
    o.shipping_cost,
    o.net_revenue,
    o.currency,

    -- Marketing attribution from order_metadata (added in Scene 3 schema change)
    m.utm_source,
    m.utm_medium,
    m.utm_campaign,
    m.device_type,

    o.fivetran_synced_at

FROM {{ ref('stg_orders') }} o
LEFT JOIN {{ ref('dim_customers') }} c
    ON o.customer_id = c.customer_id
LEFT JOIN {{ source('northshelf_raw', 'order_metadata') }} m
    ON o.order_id = m.order_id

{% if is_incremental() %}
WHERE o.fivetran_synced_at > (SELECT MAX(fivetran_synced_at) FROM {{ this }})
{% endif %}
