-- models/staging/stg_inventory_events.sql
-- Purpose: Staging for the append-only inventory event log.
-- No _fivetran_deleted filter needed — this table is append-only by design.

{{
  config(
    materialized = 'view'
  )
}}

SELECT
    event_id,
    product_id,
    store_id,
    COALESCE(store_id::VARCHAR, 'warehouse')    AS location,
    event_type,
    quantity_delta,
    reference_id,
    event_timestamp,
    _fivetran_synced                            AS fivetran_synced_at

FROM {{ source('northshelf_raw', 'inventory_events') }}
