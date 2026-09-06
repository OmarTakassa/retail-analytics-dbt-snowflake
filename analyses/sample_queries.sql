/*
    ANALYSIS: sample_queries.sql
    
    Purpose: Example queries that demonstrate the power of the star schema.
    These are NOT dbt models — they're saved here to show recruiters
    what kind of analysis this warehouse enables.
    
    Include these in your README as "Example Queries" to show the value.
*/


-- ============================================================
-- QUERY 1: Monthly Revenue Trend with Year-over-Year Comparison
-- ============================================================
-- Shows: Window functions, date manipulation, YoY growth
select
    date_trunc('month', f.order_date)                       as month,
    sum(f.net_amount)                                       as monthly_revenue,
    lag(sum(f.net_amount)) over (order by date_trunc('month', f.order_date)) 
                                                            as prev_month_revenue,
    round(
        (sum(f.net_amount) - lag(sum(f.net_amount)) over (order by date_trunc('month', f.order_date)))
        / nullif(lag(sum(f.net_amount)) over (order by date_trunc('month', f.order_date)), 0) * 100
    , 2)                                                    as mom_growth_pct
from marts.fact_orders f
where f.is_completed = true
group by date_trunc('month', f.order_date)
order by month;


-- ============================================================
-- QUERY 2: Customer Cohort Analysis — Revenue by Signup Month
-- ============================================================
-- Shows: Cohort analysis, joins across star schema
select
    date_trunc('month', c.customer_created_at)              as cohort_month,
    c.customer_segment,
    count(distinct c.customer_id)                           as customers,
    sum(f.net_amount)                                       as total_revenue,
    round(sum(f.net_amount) / count(distinct c.customer_id), 2) 
                                                            as revenue_per_customer
from marts.fact_orders f
inner join marts.dim_customers c
    on f.customer_key = c.customer_key
where f.is_completed = true
group by 1, 2
order by cohort_month, customer_segment;


-- ============================================================
-- QUERY 3: Product Performance — Top 10 by Revenue and Profit
-- ============================================================
-- Shows: Ranking, profit analysis, multi-metric comparison
select
    p.product_name,
    p.category,
    p.brand,
    p.price_tier,
    sum(f.quantity)                                          as units_sold,
    sum(f.net_amount)                                       as total_revenue,
    sum(f.line_profit)                                      as total_profit,
    round(sum(f.line_profit) / nullif(sum(f.net_amount), 0) * 100, 2) 
                                                            as profit_margin_pct,
    rank() over (order by sum(f.net_amount) desc)           as revenue_rank,
    rank() over (order by sum(f.line_profit) desc)          as profit_rank
from marts.fact_orders f
inner join marts.dim_products p
    on f.product_key = p.product_key
where f.is_completed = true
group by 1, 2, 3, 4
order by total_revenue desc
limit 10;


-- ============================================================
-- QUERY 4: Customer RFM Segmentation Distribution
-- ============================================================
-- Shows: Dimension table analysis, business segmentation
select
    customer_segment,
    revenue_tier,
    activity_status,
    count(*)                                                as customer_count,
    round(count(*) * 100.0 / sum(count(*)) over (), 2)     as pct_of_total,
    sum(lifetime_revenue)                                   as segment_lifetime_revenue,
    avg(avg_order_value)                                    as avg_order_value,
    avg(total_orders)                                       as avg_orders_per_customer
from marts.dim_customers
group by 1, 2, 3
order by segment_lifetime_revenue desc;


-- ============================================================
-- QUERY 5: Category Revenue by Day of Week — When Do People Buy?
-- ============================================================
-- Shows: Date dimension join, behavioral analysis
select
    d.day_of_week_name,
    d.day_of_week,
    f.product_category,
    count(distinct f.order_id)                              as total_orders,
    sum(f.net_amount)                                       as total_revenue,
    avg(f.net_amount)                                       as avg_order_value
from marts.fact_orders f
inner join marts.dim_dates d
    on f.order_date = d.date_day
where f.is_completed = true
group by 1, 2, 3
order by d.day_of_week, f.product_category;


-- ============================================================
-- QUERY 6: Shipping Method Impact on Order Completion
-- ============================================================
-- Shows: Conversion analysis, business insight
select
    shipping_method,
    count(*)                                                as total_orders,
    count(case when is_completed then 1 end)                as completed_orders,
    count(case when order_status = 'returned' then 1 end)   as returned_orders,
    count(case when order_status = 'cancelled' then 1 end)  as cancelled_orders,
    round(count(case when is_completed then 1 end) * 100.0 / count(*), 2) 
                                                            as completion_rate_pct,
    round(avg(case when is_completed then net_amount end), 2) 
                                                            as avg_completed_order_value
from marts.fact_orders
group by 1
order by completion_rate_pct desc;
