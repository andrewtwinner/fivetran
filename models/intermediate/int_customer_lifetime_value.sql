-- models/intermediate/int_customer_lifetime_value.sql
-- Purpose: Calculate customer LTV, order frequency, recency, and RFM segment.
-- Feeds dim_customers mart and the CMO's Klaviyo segmentation export.

{{
  config(
    materialized = 'table'
  )
}}

WITH order_summary AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)                              AS total_orders,
        SUM(o.net_revenue)                                      AS total_net_revenue,
        AVG(o.net_revenue)                                      AS avg_order_value,
        MIN(o.order_created_at)                                 AS first_order_date,
        MAX(o.order_created_at)                                 AS most_recent_order_date,
        DATEDIFF('day', MAX(o.order_created_at), CURRENT_DATE)  AS days_since_last_order,
        COUNT(DISTINCT CASE WHEN o.order_status = 'returned'
                            THEN o.order_id END)                AS total_returns,
        COUNT(DISTINCT o.channel)                               AS channels_used

    FROM {{ ref('stg_orders') }} o
    WHERE o.order_status NOT IN ('cancelled', 'pending')
    GROUP BY o.customer_id
),

ltv_scored AS (
    SELECT
        *,
        -- RFM scoring: Recency / Frequency / Monetary — each scored 1-3
        CASE
            WHEN days_since_last_order <= 30  THEN 3
            WHEN days_since_last_order <= 90  THEN 2
            ELSE 1
        END AS recency_score,
        CASE
            WHEN total_orders >= 5 THEN 3
            WHEN total_orders >= 2 THEN 2
            ELSE 1
        END AS frequency_score,
        CASE
            WHEN total_net_revenue >= 500 THEN 3
            WHEN total_net_revenue >= 150 THEN 2
            ELSE 1
        END AS monetary_score

    FROM order_summary
)

SELECT
    *,
    (recency_score + frequency_score + monetary_score)  AS rfm_total_score,
    CASE
        WHEN (recency_score + frequency_score + monetary_score) >= 8 THEN 'champion'
        WHEN (recency_score + frequency_score + monetary_score) >= 6 THEN 'loyal'
        WHEN (recency_score + frequency_score + monetary_score) >= 4 THEN 'at_risk'
        ELSE 'lapsed'
    END AS customer_segment

FROM ltv_scored
