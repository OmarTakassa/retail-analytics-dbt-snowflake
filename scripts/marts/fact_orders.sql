/*
    MART MODEL: fact_orders
    
    Purpose: Central fact table following Kimball methodology.
    Grain: One row per order line item (the most granular level).
    
    This is the primary table analysts will query for:
    - Revenue analysis
    - Product performance
    - Customer behavior
    - Order trends
    
    Foreign keys connect to all dimension tables.
*/

with enriched_items as (
    select * from {{ ref('int_order_items_enriched') }}
),

customers as (
    select customer_id, customer_key
    from {{ ref('dim_customers') }}
),

products as (
    select product_id, product_key
    from {{ ref('dim_products') }}
),

final as (
    select
        -- Fact table surrogate key
        {{ dbt_utils.generate_surrogate_key([
            'ei.order_id', 
            'ei.product_id',
            'ei.order_item_id'
        ]) }}                                               as order_fact_key,
        
        -- Dimension foreign keys (surrogate keys for star schema joins)
        c.customer_key,
        p.product_key,
        
        -- Degenerate dimensions (natural keys kept for convenience)
        ei.order_id,
        ei.order_item_id,
        ei.customer_id,
        ei.product_id,
        
        -- Date keys (join to dim_dates on these)
        ei.order_date_day                                   as order_date,
        
        -- Order attributes (degenerate dimensions)
        ei.order_status,
        ei.is_completed,
        ei.payment_method,
        ei.shipping_method,
        
        -- Product context (denormalized for query convenience)
        ei.product_name,
        ei.product_category,
        ei.product_subcategory,
        ei.product_brand,
        
        -- Measures — the numeric facts analysts will aggregate
        ei.quantity,
        ei.unit_price,
        ei.discount_pct,
        ei.gross_amount,
        ei.discount_amount,
        ei.net_amount,
        ei.line_cost,
        ei.line_profit,
        
        -- Order-level measures (repeated per line item — use with care)
        ei.shipping_cost,
        ei.order_discount_amount,
        ei.tax_amount,
        ei.order_total_amount,
        
        -- Profit margin at line item level
        case
            when ei.net_amount > 0
            then round(ei.line_profit / ei.net_amount * 100, 2)
            else 0
        end                                                 as line_profit_margin_pct,
        
        -- Metadata
        current_timestamp()                                 as dbt_loaded_at

    from enriched_items ei
    left join customers c
        on ei.customer_id = c.customer_id
    left join products p
        on ei.product_id = p.product_id
)

select * from final
