/*
    SNAPSHOT: snap_customers
    
    Purpose: Track changes to customer records over time using SCD Type 2.
    
    When a customer's email, address, city, state, or active status changes,
    dbt creates a new row with the updated values and timestamps the old row
    as expired. This lets analysts see what a customer looked like at any
    point in time — critical for accurate historical reporting.
    
    Strategy: timestamp-based (uses updated_at column to detect changes)
    
    Usage in queries:
      -- Get current customer record
      SELECT * FROM snap_customers WHERE dbt_valid_to IS NULL
      
      -- Get customer record as of a specific date
      SELECT * FROM snap_customers 
      WHERE '2024-06-15' BETWEEN dbt_valid_from AND COALESCE(dbt_valid_to, '9999-12-31')
*/

{% snapshot snap_customers %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    address_line1,
    city,
    state,
    zip_code,
    country,
    is_active,
    created_at,
    updated_at

from {{ source('raw', 'raw_customers') }}

{% endsnapshot %}
