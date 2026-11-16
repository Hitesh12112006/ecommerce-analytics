-- Q1 Monthly revenue and order count
SELECT month, ROUND(SUM(revenue),2) AS revenue, COUNT(*) AS orders
FROM orders GROUP BY month ORDER BY month;

-- Q2 Revenue by category with share of total
SELECT category, ROUND(SUM(revenue),2) AS revenue,
       ROUND(100.0*SUM(revenue)/(SELECT SUM(revenue) FROM orders),1) AS pct
FROM orders GROUP BY category ORDER BY revenue DESC;

-- Q3 Top 10 customers by lifetime value
SELECT customer_id, COUNT(*) AS orders, ROUND(SUM(revenue),2) AS ltv
FROM orders GROUP BY customer_id ORDER BY ltv DESC LIMIT 10;

-- Q4 Repeat purchase rate
SELECT ROUND(100.0*SUM(CASE WHEN c > 1 THEN 1 ELSE 0 END)/COUNT(*),1) AS repeat_pct
FROM (SELECT customer_id, COUNT(*) c FROM orders GROUP BY customer_id);

-- Q5 RFM segmentation
WITH rfm AS (
  SELECT customer_id,
         julianday('2026-01-01') - julianday(MAX(order_date)) AS recency,
         COUNT(*) AS frequency, SUM(revenue) AS monetary
  FROM orders GROUP BY customer_id),
scored AS (
  SELECT *, NTILE(4) OVER (ORDER BY recency DESC) AS r,
            NTILE(4) OVER (ORDER BY frequency)   AS f,
            NTILE(4) OVER (ORDER BY monetary)    AS m
  FROM rfm)
SELECT customer_id, r, f, m,
  CASE WHEN r+f+m >= 10 THEN 'Champion'
       WHEN r+f+m >= 7  THEN 'Loyal'
       WHEN r <= 2 AND f >= 3 THEN 'At risk'
       ELSE 'Occasional' END AS segment
FROM scored;

-- Q6 Month-over-month growth
SELECT month, revenue,
  ROUND(100.0*(revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month),1) AS mom_pct
FROM (SELECT month, SUM(revenue) AS revenue FROM orders GROUP BY month);
