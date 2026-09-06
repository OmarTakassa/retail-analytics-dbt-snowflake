/*
    MART MODEL: dim_customers
    
    Purpose: Customer dimension table following Kimball methodology.
    Enriched with order history metrics and customer segmentation.
    
    Grain: One row per customer
    Type: Slowly Changing Dimension (current state + snapshot for history)
*/

with customers as (
    select * from {{ ref('stg_customers') }}
),

order_summary as (
    select * from {{ ref('int_customer_orders_summary') }}
),

final as (
    select
        -- Surrogate key (best practice for dimension tables)
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} 
                                                            as customer_key,
        
        -- Natural key
        c.customer_id,
        
        -- Customer attributes
        c.first_name,
        c.last_name,
        c.full_name,
        c.email,
        c.phone,
        c.address_line1,
        c.city,
        c.state_code,
        c.zip_code,
        c.country_code,
        c.is_active,
        
        -- Order metrics (from intermediate model)
        coalesce(os.total_orders, 0)                        as total_orders,
        coalesce(os.completed_orders, 0)                    as completed_orders,
        coalesce(os.returned_orders, 0)                     as returned_orders,
        coalesce(os.cancelled_orders, 0)                    as cancelled_orders,
        coalesce(os.lifetime_revenue, 0)                    as lifetime_revenue,
        coalesce(os.avg_order_value, 0)                     as avg_order_value,
        os.first_order_date,
        os.last_order_date,
        coalesce(os.customer_tenure_days, 0)                as customer_tenure_days,
        coalesce(os.days_since_last_order, 0)               as days_since_last_order,
        
        -- Customer segmentation (RFM-inspired)
        case
            when os.total_orders is null then 'Never Purchased'
            when os.total_orders = 1 then 'One-Time Buyer'
            when os.total_orders between 2 and 4 then 'Repeat Customer'
            when os.total_orders >= 5 then 'Loyal Customer'
        end                                                 as customer_segment,
        
        -- Revenue tier
        case
            when coalesce(os.lifetime_revenue, 0) = 0 then 'No Revenue'
            when os.lifetime_revenue < 50 then 'Low Value'
            when os.lifetime_revenue < 150 then 'Medium Value'
            when os.lifetime_revenue < 300 then 'High Value'
            else 'VIP'
        end                                                 as revenue_tier,
        
        -- Activity status
        case
            when os.days_since_last_order is null then 'Never Active'
            when os.days_since_last_order <= 90 then 'Active'
            when os.days_since_last_order <= 180 then 'At Risk'
            when os.days_since_last_order <= 365 then 'Lapsed'
            else 'Churned'
        end                                                 as activity_status,
        
        -- Metadata
        c.created_at                                        as customer_created_at,
        c.updated_at                                        as customer_updated_at,
        current_timestamp()                                 as dbt_loaded_at

    from customers c
    left join order_summary os 
        on c.customer_id = os.customer_id
)

select * from final
