-- =====================================================================
-- BlitzMart Analytics — SQL Analysis
-- 15 business queries on 6.6M rows of German e-commerce data
-- Engine: DuckDB (PostgreSQL-compatible syntax)
-- =====================================================================


-- =====================================================================
-- SECTION 1: REVENUE & SALES PERFORMANCE
-- =====================================================================

-- Q1: Topline business health — revenue, orders, AOV, customers
SELECT
    COUNT(DISTINCT o.order_id)                                AS total_orders,
    COUNT(DISTINCT o.customer_id)                             AS unique_customers,
    ROUND(SUM(oi.line_total), 0)                              AS total_revenue_eur,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value_eur,
    ROUND(SUM(oi.quantity)::DECIMAL
          / COUNT(DISTINCT o.order_id), 2)                    AS avg_items_per_order
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status IN ('Delivered', 'Shipped');


-- Q2: Monthly revenue trend with Year-over-Year growth %
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date) AS month,
           SUM(oi.line_total)                AS revenue,
           COUNT(DISTINCT o.order_id)        AS orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status IN ('Delivered', 'Shipped')
    GROUP BY 1
)
SELECT month, orders,
       ROUND(revenue, 0)                                AS revenue_eur,
       ROUND(LAG(revenue, 12) OVER (ORDER BY month), 0) AS revenue_last_year,
       ROUND(100.0 * (revenue - LAG(revenue, 12) OVER (ORDER BY month))
             / NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0), 1) AS yoy_growth_pct
FROM monthly
ORDER BY month;


-- Q3: Revenue, profit, and margin by product category
SELECT p.category,
       SUM(oi.quantity)                                   AS units_sold,
       ROUND(SUM(oi.line_total), 0)                       AS revenue_eur,
       ROUND(SUM((oi.unit_price - p.unit_cost) * oi.quantity
                 * (1 - oi.discount)), 0)                 AS gross_profit_eur,
       ROUND(100.0 * SUM((oi.unit_price - p.unit_cost) * oi.quantity
                         * (1 - oi.discount))
             / SUM(oi.line_total), 1)                     AS gross_margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.order_status IN ('Delivered', 'Shipped')
GROUP BY p.category
ORDER BY revenue_eur DESC;


-- Q4: Top 10 products by revenue
SELECT p.product_id, p.product_name, p.category,
       SUM(oi.quantity)             AS units_sold,
       ROUND(SUM(oi.line_total), 0) AS revenue_eur,
       RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS revenue_rank
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders   o ON oi.order_id   = o.order_id
WHERE o.order_status IN ('Delivered', 'Shipped')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue_eur DESC
LIMIT 10;


-- Q5: Warehouse performance with share of total orders
SELECT w.warehouse_name, w.region,
       COUNT(DISTINCT o.order_id)   AS orders_fulfilled,
       ROUND(SUM(oi.line_total), 0) AS revenue_eur,
       ROUND(AVG(oi.line_total), 2) AS avg_line_value_eur,
       ROUND(100.0 * COUNT(DISTINCT o.order_id)
             / SUM(COUNT(DISTINCT o.order_id)) OVER (), 1) AS pct_of_total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN warehouses w  ON o.warehouse_id = w.warehouse_id
WHERE o.order_status IN ('Delivered', 'Shipped')
GROUP BY w.warehouse_name, w.region
ORDER BY revenue_eur DESC;


-- =====================================================================
-- SECTION 2: CUSTOMER ANALYTICS
-- =====================================================================

-- Q6: Customer segment performance — Standard vs Premium vs VIP
SELECT c.customer_segment,
       COUNT(DISTINCT c.customer_id)                                AS customers,
       COUNT(DISTINCT o.order_id)                                   AS total_orders,
       ROUND(SUM(oi.line_total), 0)                                 AS revenue_eur,
       ROUND(SUM(oi.line_total) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer,
       ROUND(COUNT(DISTINCT o.order_id)::DECIMAL
             / COUNT(DISTINCT c.customer_id), 2)                    AS orders_per_customer
FROM customers c
JOIN orders      o  ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.order_status IN ('Delivered', 'Shipped')
GROUP BY c.customer_segment
ORDER BY revenue_eur DESC;


-- Q7: Top 20 customers by lifetime value
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       c.city, c.customer_segment,
       COUNT(DISTINCT o.order_id)         AS total_orders,
       ROUND(SUM(oi.line_total), 2)       AS lifetime_value_eur,
       MIN(o.order_date)                  AS first_order,
       MAX(o.order_date)                  AS last_order
FROM customers c
JOIN orders      o  ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.order_status IN ('Delivered', 'Shipped')
GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.customer_segment
ORDER BY lifetime_value_eur DESC
LIMIT 20;


-- Q8: New vs returning customer revenue split
WITH order_seq AS (
    SELECT o.order_id, o.customer_id, o.order_date,
           ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_num
    FROM orders o
    WHERE o.order_status IN ('Delivered', 'Shipped')
)
SELECT
    CASE WHEN os.order_num = 1 THEN 'New customer' ELSE 'Returning customer' END AS customer_type,
    COUNT(DISTINCT os.order_id)                                            AS orders,
    ROUND(SUM(oi.line_total), 0)                                           AS revenue_eur,
    ROUND(100.0 * SUM(oi.line_total) / SUM(SUM(oi.line_total)) OVER (), 1) AS pct_of_revenue
FROM order_seq os
JOIN order_items oi ON os.order_id = oi.order_id
GROUP BY 1
ORDER BY revenue_eur DESC;


-- =====================================================================
-- SECTION 3: OPERATIONS & SUPPLY CHAIN
-- =====================================================================

-- Q9: OTIF (On-Time-In-Full) by carrier
SELECT carrier,
       COUNT(*)                                                AS total_shipments,
       SUM(on_time_delivery)                                   AS on_time_count,
       ROUND(100.0 * AVG(on_time_delivery), 2)                 AS on_time_pct,
       ROUND(AVG(actual_delivery_days), 2)                     AS avg_delivery_days,
       ROUND(AVG(actual_delivery_days - promised_delivery_days), 2) AS avg_delay_days
FROM shipments
GROUP BY carrier
ORDER BY on_time_pct DESC;


-- Q10: Fulfillment speed by warehouse
SELECT w.warehouse_name, w.city,
       COUNT(s.shipment_id)                      AS shipments,
       ROUND(AVG(s.actual_delivery_days), 2)     AS avg_delivery_days,
       ROUND(100.0 * AVG(s.on_time_delivery), 2) AS on_time_pct
FROM shipments s
JOIN orders     o ON s.order_id     = o.order_id
JOIN warehouses w ON o.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name, w.city
ORDER BY avg_delivery_days ASC;


-- Q11: Return rate by product category
WITH cat_orders AS (
    SELECT p.category, COUNT(DISTINCT oi.order_id) AS total_orders
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.category
),
cat_returns AS (
    SELECT p.category,
           COUNT(DISTINCT r.order_id) AS returned_orders,
           SUM(r.refund_amount)       AS refund_eur
    FROM returns r
    JOIN order_items oi ON r.order_id   = oi.order_id
    JOIN products    p  ON oi.product_id = p.product_id
    GROUP BY p.category
)
SELECT co.category, co.total_orders, cr.returned_orders,
       ROUND(100.0 * cr.returned_orders / co.total_orders, 2) AS return_rate_pct,
       ROUND(cr.refund_eur, 0)                                AS total_refunds_eur
FROM cat_orders co
LEFT JOIN cat_returns cr ON co.category = cr.category
ORDER BY return_rate_pct DESC;


-- Q12: Top return reasons — root cause analysis
SELECT return_reason,
       COUNT(*)                                          AS return_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_returns,
       ROUND(SUM(refund_amount), 0)                      AS total_refund_eur,
       ROUND(AVG(refund_amount), 2)                      AS avg_refund_eur
FROM returns
GROUP BY return_reason
ORDER BY return_count DESC;


-- Q13: Payment method mix
SELECT o.payment_method,
       COUNT(*)                                          AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders,
       ROUND(SUM(oi.line_total), 0)                      AS revenue_eur,
       ROUND(AVG(oi.line_total), 2)                      AS avg_line_value_eur
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status IN ('Delivered', 'Shipped')
GROUP BY o.payment_method
ORDER BY orders DESC;


-- =====================================================================
-- SECTION 4: ADVANCED ANALYTICS
-- =====================================================================

-- Q14: RFM customer segmentation (Recency, Frequency, Monetary)
WITH customer_metrics AS (
    SELECT c.customer_id,
           DATE_DIFF('day', MAX(o.order_date), DATE '2024-12-31') AS recency_days,
           COUNT(DISTINCT o.order_id)                             AS frequency,
           SUM(oi.line_total)                                     AS monetary
    FROM customers c
    JOIN orders      o  ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.order_status IN ('Delivered', 'Shipped')
    GROUP BY c.customer_id
),
rfm_scores AS (
    SELECT customer_id, recency_days, frequency, monetary,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency ASC)    AS f_score,
           NTILE(5) OVER (ORDER BY monetary ASC)     AS m_score
    FROM customer_metrics
)
SELECT
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN '01 Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN '02 Loyal customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN '03 New customers'
        WHEN r_score <= 2 AND f_score >= 3                  THEN '04 At risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN '05 Cant lose them'
        WHEN r_score <= 2 AND f_score <= 2                  THEN '06 Hibernating'
        ELSE                                                     '07 Others'
    END                              AS rfm_segment,
    COUNT(*)                         AS customer_count,
    ROUND(AVG(monetary), 0)          AS avg_lifetime_value_eur,
    ROUND(AVG(recency_days), 0)      AS avg_days_since_last_order,
    ROUND(AVG(frequency), 1)         AS avg_orders
FROM rfm_scores
GROUP BY rfm_segment
ORDER BY rfm_segment;


-- Q15: Monthly cohort retention
WITH first_order AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE order_status IN ('Delivered', 'Shipped')
    GROUP BY customer_id
),
customer_activity AS (
    SELECT fo.cohort_month, o.customer_id,
           DATE_DIFF('month', fo.cohort_month, DATE_TRUNC('month', o.order_date)) AS month_offset
    FROM first_order fo
    JOIN orders o ON fo.customer_id = o.customer_id
    WHERE o.order_status IN ('Delivered', 'Shipped')
)
SELECT cohort_month,
       COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END) AS cohort_size,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 1 THEN customer_id END)
             / NULLIF(COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END), 0), 1) AS month_1_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 3 THEN customer_id END)
             / NULLIF(COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END), 0), 1) AS month_3_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 6 THEN customer_id END)
             / NULLIF(COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END), 0), 1) AS month_6_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 12 THEN customer_id END)
             / NULLIF(COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END), 0), 1) AS month_12_pct
FROM customer_activity
GROUP BY cohort_month
HAVING COUNT(DISTINCT CASE WHEN month_offset = 0 THEN customer_id END) > 100
ORDER BY cohort_month;
