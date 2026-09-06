/*
    STAGING MODEL: stg_orders
    
    Purpose: Clean and standardize raw order header data
    Source: raw.raw_orders
    
    Transformations applied:
    - Cast data types explicitly
    - Standardize status values to lowercase
    - Standardize payment and shipping methods
    - Filter out test orders
*/

with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

cleaned as (
    select
        -- Primary key
        order_id::integer                                   as order_id,
        
        -- Foreign key
        customer_id::integer                                as customer_id,
        
        -- Order details
        order_date::timestamp_ntz                           as order_date,
        order_date::date                                    as order_date_day,
        trim(lower(status))::varchar(50)                    as order_status,
        trim(lower(payment_method))::varchar(50)            as payment_method,
        trim(lower(shipping_method))::varchar(50)           as shipping_method,
        
        -- Financial
        coalesce(shipping_cost, 0)::decimal(10,2)           as shipping_cost,
        coalesce(discount_amount, 0)::decimal(10,2)         as discount_amount,
        coalesce(tax_amount, 0)::decimal(10,2)              as tax_amount,
        coalesce(total_amount, 0)::decimal(10,2)            as total_amount,
        
        -- Derived: is this a completed/successful order?
        case 
            when trim(lower(status)) = 'completed' then true
            else false
        end                                                 as is_completed,
        
        -- Timestamps
        created_at::timestamp_ntz                           as created_at,
        updated_at::timestamp_ntz                           as updated_at

    from source
    where 
        order_id is not null
        and customer_id is not null
        and total_amount >= 0
)

select * from cleaned
