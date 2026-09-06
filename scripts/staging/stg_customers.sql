/*
    STAGING MODEL: stg_customers
    
    Purpose: Clean and standardize raw customer data
    Source: raw.raw_customers
    
    Transformations applied:
    - Rename columns to consistent snake_case
    - Cast data types explicitly
    - Trim whitespace from string fields
    - Standardize state codes to uppercase
    - Convert string booleans to actual booleans
    - Filter out test/invalid records
*/

with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

cleaned as (
    select
        -- Primary key
        customer_id::integer                                as customer_id,
        
        -- Customer name
        trim(first_name)::varchar(100)                      as first_name,
        trim(last_name)::varchar(100)                       as last_name,
        trim(first_name) || ' ' || trim(last_name)          as full_name,
        
        -- Contact info
        trim(lower(email))::varchar(255)                    as email,
        trim(phone)::varchar(20)                            as phone,
        
        -- Address
        trim(address_line1)::varchar(255)                   as address_line1,
        trim(city)::varchar(100)                            as city,
        trim(upper(state))::varchar(2)                      as state_code,
        trim(zip_code)::varchar(10)                         as zip_code,
        trim(upper(country))::varchar(2)                    as country_code,
        
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
        customer_id is not null
        and email is not null
        and email like '%@%'  -- Basic email validation
)

select * from cleaned
