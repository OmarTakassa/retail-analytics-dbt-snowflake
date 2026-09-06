/*
    MART MODEL: fact_daily_revenue
    
    Purpose: Pre-aggregated fact table for dashboard performance.
    Instead of querying millions of line items, dashboards query this
    table which has one row per date per category — much faster.
    
    Grain: One row per order_date + product_category combination
    
    This is what Power BI / Tableau / Looker connects to for:
    - Daily revenue trends
    - Category performance comparison
    - KPI dashboards
*/

with fact as (
    select * from {{ ref('fact_orders') }}
    where is_completed = true  -- Only completed orders count as revenue
),

daily_revenue as (
    select
        -- Grain keys
        order_date,
        product_category,
        
        -- Order metrics
        count(distinct order_id)                            as total_orders,
        count(order_item_id)                                as total_line_items,
        count(distinct customer_id)                         as unique_customers,
        
        -- Revenue metrics
        sum(gross_amount)::decimal(12,2)                    as gross_revenue,
        sum(discount_amount)::decimal(12,2)                 as total_discounts,
        sum(net_amount)::decimal(12,2)                      as net_revenue,
        sum(line_cost)::decimal(12,2)                       as total_cost,
        sum(line_profit)::decimal(12,2)                     as total_profit,
        
        -- Average metrics
        avg(net_amount)::decimal(10,2)                      as avg_line_value,
        avg(quantity)::decimal(10,2)                        as avg_quantity_per_line,
        
        -- Quantity metrics
        sum(quantity)                                       as total_units_sold,
        
        -- Profit margin
        case
            when sum(net_amount) > 0
            then round(sum(line_profit) / sum(net_amount) * 100, 2)
            else 0
        end                                                 as profit_margin_pct,
        
        -- Product diversity
        count(distinct product_id)                          as unique_products_sold,
        
        -- Metadata
        current_timestamp()                                 as dbt_loaded_at

    from fact
    group by
        order_date,
        product_category
)

select * from daily_revenue
