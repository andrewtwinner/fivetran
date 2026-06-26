-- models/staging/stg_products.sql
-- Purpose: Clean products table. Includes new columns added in Scene 3 schema change
--          (warehouse_location, return_rate_pct, supplier_sku) — auto-propagated by Fivetran.

{{
  config(
    materialized = 'view'
  )
}}

SELECT
    product_id,
    sku,
    product_name,
    category,
    subcategory,
    brand,
    unit_cost,
    unit_price,
    stock_quantity,
    is_active,

    -- These columns were added by Scene 3 ALTER TABLE.
    -- Fivetran propagated them automatically — no pipeline changes needed.
    warehouse_location,
    return_rate_pct,
    supplier_sku,

    created_at,
    updated_at,
    _fivetran_synced                    AS fivetran_synced_at

FROM {{ source('northshelf_raw', 'products') }}

WHERE _fivetran_deleted = FALSE
  AND is_active = 1
