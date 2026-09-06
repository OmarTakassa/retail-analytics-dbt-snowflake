/*
    INTERMEDIATE MODEL: int_order_items_enriched
    
    Purpose: Join order items with order headers and product details
    to create a fully enriched line-item level dataset.
    
    This is ephemeral (not materialized) — it's used as a building block
    for mart models without creating an extra table in the warehouse.
    
    Grain: One row per order line item
*/

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

enriched as (
    select
        -- Keys
        oi.order_item_id,
        oi.order_item_key,
        oi.order_id,
        oi.product_id,
        o.customer_id,
        
        -- Order context
        o.order_date,
        o.order_date_day,
        o.order_status,
        o.is_completed,
        o.payment_method,
        o.shipping_method,
        
        -- Product context
        p.product_name,
        p.category                                          as product_category,
        p.subcategory                                       as product_subcategory,
        p.brand                                             as product_brand,
        p.cost_price                                        as product_cost_price,
        p.profit_margin_pct                                 as product_profit_margin_pct,
        
        -- Line item financials
        oi.quantity,
        oi.unit_price,
        oi.discount_pct,
        oi.gross_amount,
        oi.discount_amount,
        oi.net_amount,
        
        -- Cost and profit at line item level
        (oi.quantity * p.cost_price)::decimal(10,2)         as line_cost,
        (oi.net_amount - (oi.quantity * p.cost_price))::decimal(10,2) 
                                                            as line_profit,
        
        -- Order-level financials (denormalized for convenience)
        o.shipping_cost,
        o.discount_amount                                   as order_discount_amount,
        o.tax_amount,
        o.total_amount                                      as order_total_amount

    from order_items oi
    inner join orders o 
        on oi.order_id = o.order_id
    inner join products p 
        on oi.product_id = p.product_id
)

select * from enriched
