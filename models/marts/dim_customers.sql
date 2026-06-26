-- models/marts/dim_customers.sql
-- Purpose: Analytics-ready customer dimension.
-- Powers: CMO's Klaviyo segments, CFO's customer report, AI/ML churn model feature store.
-- Refreshed automatically after every Fivetran sync via the dbt job trigger.

{{
  config(
    materialized = 'table'
  )
}}

SELECT
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    c.loyalty_tier,
    c.loyalty_points,
    c.acquisition_channel,
    c.customer_created_at,

    -- LTV and RFM enrichment from intermediate model
    ltv.total_orders,
    ltv.total_net_revenue,
    ltv.avg_order_value,
    ltv.first_order_date,
    ltv.most_recent_order_date,
    ltv.days_since_last_order,
    ltv.total_returns,
    ltv.channels_used,
    ltv.rfm_total_score,
    ltv.customer_segment,

    -- Boolean flags for marketing automation and AI feature stores
    CASE WHEN ltv.days_since_last_order <= 30  THEN TRUE ELSE FALSE END  AS is_active_30d,
    CASE WHEN ltv.days_since_last_order > 180  THEN TRUE ELSE FALSE END  AS is_churned,
    CASE WHEN ltv.total_orders = 1             THEN TRUE ELSE FALSE END  AS is_one_time_buyer,
    CASE WHEN ltv.channels_used > 1            THEN TRUE ELSE FALSE END  AS is_omnichannel,

    c.fivetran_synced_at

FROM {{ ref('stg_customers') }} c
LEFT JOIN {{ ref('int_customer_lifetime_value') }} ltv
    ON c.customer_id = ltv.customer_id
