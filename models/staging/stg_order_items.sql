-- models/staging/stg_order_items.sql
-- Purpose: Clean order line items. Filter deleted rows.

{{
  config(
    materialized = 'view'
  )
}}

SELECT
    item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total,
    created_at,
    _fivetran_synced                    AS fivetran_synced_at

FROM {{ source('northshelf_raw', 'order_items') }}

WHERE _fivetran_deleted = FALSE
