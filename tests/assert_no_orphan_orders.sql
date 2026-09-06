/*
    CUSTOM TEST: assert_no_orphan_orders
    
    Purpose: Every order in stg_orders should have at least one
    line item in stg_order_items. An order without items is a data issue.
    
    Returns 0 rows = PASS
    Returns rows = FAIL (shows which orders are missing items)
*/

with orders as (
    select order_id
    from {{ ref('stg_orders') }}
),

order_items as (
    select distinct order_id
    from {{ ref('stg_order_items') }}
),

orphan_orders as (
    select o.order_id
    from orders o
    left join order_items oi
        on o.order_id = oi.order_id
    where oi.order_id is null
)

select * from orphan_orders
