/*
    STAGING MODEL: stg_order_items
    
    Purpose: Clean and standardize raw order line item data
    Source: raw.raw_order_items
    
    Transformations applied:
    - Cast data types explicitly
    - Calculate line item total
    - Calculate discount amount per line
    - Generate surrogate key for fact table
*/

with source as (
    select * from {{ source('raw', 'raw_order_items') }}
),

cleaned as (
    select
        -- Primary key
        order_item_id::integer                              as order_item_id,
        
        -- Foreign keys
        order_id::integer                                   as order_id,
        product_id::integer                                 as product_id,
        
        -- Surrogate key (combines order + product for unique grain)
        {{ dbt_utils.generate_surrogate_key(['order_id', 'product_id']) }} 
                                                            as order_item_key,
        
        -- Quantities and pricing
        quantity::integer                                   as quantity,
        unit_price::decimal(10,2)                           as unit_price,
        coalesce(discount_pct, 0)::decimal(5,2)             as discount_pct,
        
        -- Calculated fields
        (quantity * unit_price)::decimal(10,2)               as gross_amount,
        (quantity * unit_price * coalesce(discount_pct, 0) / 100)::decimal(10,2) 
                                                            as discount_amount,
        (quantity * unit_price * (1 - coalesce(discount_pct, 0) / 100))::decimal(10,2) 
                                                            as net_amount,
        
        -- Timestamps
        created_at::timestamp_ntz                           as created_at

    from source
    where 
        order_item_id is not null
        and quantity > 0
        and unit_price > 0
)

select * from cleaned
