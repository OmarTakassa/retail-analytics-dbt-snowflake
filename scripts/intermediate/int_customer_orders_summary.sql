/*
    INTERMEDIATE MODEL: int_customer_orders_summary
    
    Purpose: Aggregate order data at the customer level
    to support the dim_customers mart model.
    
    Grain: One row per customer
*/

with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

customer_orders as (
    select
        o.customer_id,
        
        -- Order counts
        count(distinct o.order_id)                          as total_orders,
        count(distinct case when o.is_completed then o.order_id end) 
                                                            as completed_orders,
        count(distinct case when o.order_status = 'returned' then o.order_id end) 
                                                            as returned_orders,
        count(distinct case when o.order_status = 'cancelled' then o.order_id end) 
                                                            as cancelled_orders,
        
        -- Revenue metrics (only completed orders)
        coalesce(sum(case when o.is_completed then o.total_amount else 0 end), 0)::decimal(12,2) 
                                                            as lifetime_revenue,
        coalesce(avg(case when o.is_completed then o.total_amount end), 0)::decimal(10,2) 
                                                            as avg_order_value,
        
        -- Timeline
        min(o.order_date)::date                             as first_order_date,
        max(o.order_date)::date                             as last_order_date,
        datediff('day', min(o.order_date), max(o.order_date)) 
                                                            as customer_tenure_days,
        
        -- Recency
        datediff('day', max(o.order_date), current_date())  as days_since_last_order

    from orders o
    group by o.customer_id
)

select * from customer_orders
