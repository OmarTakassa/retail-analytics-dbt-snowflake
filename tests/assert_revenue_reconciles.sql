/*
    CUSTOM TEST: assert_revenue_reconciles
    
    Purpose: Ensure that total revenue in fact_orders matches
    the sum of line items in staging. If these numbers don't match,
    something went wrong in our transformation logic.
    
    This test PASSES if it returns 0 rows.
    It FAILS if the revenue difference exceeds $0.01 (rounding tolerance).
    
    This is exactly the kind of test that impresses interviewers —
    it shows you think about data integrity end-to-end.
*/

with fact_revenue as (
    select
        sum(net_amount) as total_fact_revenue
    from {{ ref('fact_orders') }}
),

staging_revenue as (
    select
        sum(net_amount) as total_staging_revenue
    from {{ ref('stg_order_items') }}
),

comparison as (
    select
        f.total_fact_revenue,
        s.total_staging_revenue,
        abs(f.total_fact_revenue - s.total_staging_revenue) as revenue_difference
    from fact_revenue f
    cross join staging_revenue s
)

-- This query should return 0 rows if the test passes
-- If it returns a row, the revenue doesn't reconcile
select *
from comparison
where revenue_difference > 0.01
