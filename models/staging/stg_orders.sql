-- models/staging/stg_orders.sql
-- Purpose: Clean orders from Fivetran source. Derive net_revenue and order_type.
-- Incremental model — only processes rows Fivetran synced since last dbt run.

{{
  config(
    materialized = 'incremental',
    unique_key   = 'order_id'
  )
}}

SELECT
    order_id,
    customer_id,
    order_status,
    channel,
    store_id,
    order_total,
    discount_amount,
    shipping_cost,
    (order_total - discount_amount)     AS net_revenue,
    CASE
        WHEN store_id IS NULL THEN 'online'
        ELSE 'in_store'
    END                                 AS order_type,
    currency,
    created_at                          AS order_created_at,
    updated_at                          AS order_updated_at,
    _fivetran_synced                    AS fivetran_synced_at

FROM {{ source('northshelf_raw', 'orders') }}

WHERE _fivetran_deleted = FALSE

{% if is_incremental() %}
  -- Only process rows that Fivetran synced since the last dbt run.
  -- _fivetran_synced is the watermark — the key to efficient incremental loads.
  AND _fivetran_synced > (SELECT MAX(fivetran_synced_at) FROM {{ this }})
{% endif %}
