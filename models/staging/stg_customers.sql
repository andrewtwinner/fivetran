-- models/staging/stg_customers.sql
-- Purpose: Clean the raw Fivetran replica. Remove deleted rows, cast types,
--          rename columns to consistent snake_case convention.
-- Materialised as a view — always reflects the latest Fivetran sync instantly.

{{
  config(
    materialized = 'view'
  )
}}

SELECT
    customer_id,
    email,
    first_name,
    last_name,
    phone,
    date_of_birth,
    loyalty_tier,
    loyalty_points,
    acquisition_channel,
    created_at                          AS customer_created_at,
    updated_at                          AS customer_updated_at,
    _fivetran_synced                    AS fivetran_synced_at

FROM {{ source('northshelf_raw', 'customers') }}

WHERE _fivetran_deleted = FALSE          -- filter soft-deleted rows flagged by CDC
  AND email IS NOT NULL                  -- data quality guard
