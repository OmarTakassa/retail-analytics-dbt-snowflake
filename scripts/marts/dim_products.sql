/*
    MART MODEL: dim_products
    
    Purpose: Product dimension table following Kimball methodology.
    Includes product hierarchy and pricing tiers.
    
    Grain: One row per product
*/

with products as (
    select * from {{ ref('stg_products') }}
),

-- Calculate product-level sales metrics
product_sales as (
    select
        product_id,
        count(distinct order_id)                            as times_ordered,
        sum(quantity)                                       as total_units_sold,
        sum(net_amount)                                     as total_revenue,
        avg(net_amount)                                     as avg_line_revenue
    from {{ ref('stg_order_items') }}
    group by product_id
),

final as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} 
                                                            as product_key,
        
        -- Natural key
        p.product_id,
        
        -- Product hierarchy
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        
        -- Pricing
        p.unit_price,
        p.cost_price,
        p.profit_per_unit,
        p.profit_margin_pct,
        
        -- Price tier
        case
            when p.unit_price < 20 then 'Budget'
            when p.unit_price < 50 then 'Mid-Range'
            when p.unit_price < 100 then 'Premium'
            else 'Luxury'
        end                                                 as price_tier,
        
        -- Physical
        p.weight_kg,
        
        -- Sales metrics
        coalesce(ps.times_ordered, 0)                       as times_ordered,
        coalesce(ps.total_units_sold, 0)                    as total_units_sold,
        coalesce(ps.total_revenue, 0)                       as total_revenue,
        coalesce(ps.avg_line_revenue, 0)                    as avg_line_revenue,
        
        -- Product performance tier
        case
            when coalesce(ps.total_revenue, 0) = 0 then 'No Sales'
            when ps.total_revenue < 100 then 'Low Performer'
            when ps.total_revenue < 500 then 'Moderate Performer'
            else 'Top Performer'
        end                                                 as performance_tier,
        
        -- Status
        p.is_active,
        
        -- Metadata
        p.created_at                                        as product_created_at,
        p.updated_at                                        as product_updated_at,
        current_timestamp()                                 as dbt_loaded_at

    from products p
    left join product_sales ps 
        on p.product_id = ps.product_id
)

select * from final
