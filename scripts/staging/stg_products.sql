/*
    STAGING MODEL: stg_products
    
    Purpose: Clean and standardize raw product catalog data
    Source: raw.raw_products
    
    Transformations applied:
    - Cast data types explicitly
    - Trim whitespace
    - Standardize category names
    - Calculate profit margin
    - Filter inactive/invalid products
*/

with source as (
    select * from {{ source('raw', 'raw_products') }}
),

cleaned as (
    select
        -- Primary key
        product_id::integer                                 as product_id,
        
        -- Product details
        trim(product_name)::varchar(255)                    as product_name,
        trim(initcap(category))::varchar(100)               as category,
        trim(initcap(subcategory))::varchar(100)            as subcategory,
        trim(brand)::varchar(100)                           as brand,
        
        -- Pricing
        unit_price::decimal(10,2)                           as unit_price,
        cost_price::decimal(10,2)                           as cost_price,
        (unit_price - cost_price)::decimal(10,2)            as profit_per_unit,
        case 
            when unit_price > 0 
            then round((unit_price - cost_price) / unit_price * 100, 2)
            else 0 
        end                                                 as profit_margin_pct,
        
        -- Physical
        weight_kg::decimal(8,2)                             as weight_kg,
        
        -- Status
        case 
            when lower(trim(is_active)) = 'true' then true
            when lower(trim(is_active)) = 'false' then false
            else null
        end                                                 as is_active,
        
        -- Timestamps
        created_at::timestamp_ntz                           as created_at,
        updated_at::timestamp_ntz                           as updated_at

    from source
    where 
        product_id is not null
        and unit_price > 0
)

select * from cleaned
