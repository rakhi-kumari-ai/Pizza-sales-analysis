-- =====================================================
-- 🍕 Pizza Sales Analysis using MySQL
-- Description: SQL queries to analyze pizza sales data
-- =====================================================

/* =====================================================
BASIC ANALYSIS
===================================================== */

-- 1. Retrieve the total number of orders placed
SELECT
COUNT(order_id) AS total_orders
FROM orders;

-- 2. Calculate the total revenue generated from pizza sales
SELECT
ROUND(SUM(p.price * od.quantity), 2) AS total_revenue
FROM pizzas p
JOIN order_details od
ON od.pizza_id = p.pizza_id;

-- 3. Identify the highest-priced pizza
SELECT
pt.name AS pizza_name,
p.price
FROM pizzas p
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- 4. Identify the most common pizza size ordered
SELECT
size,
COUNT(size) AS size_count
FROM pizzas
GROUP BY size
ORDER BY size_count DESC
LIMIT 1;

-- 5. List the top 5 most ordered pizza types along with their quantities
SELECT
pt.name AS pizza_type,
SUM(od.quantity) AS total_quantity
FROM pizzas p
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od
ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

/* =====================================================
INTERMEDIATE ANALYSIS
===================================================== */

-- 6. Find the total quantity of each pizza category ordered
SELECT
pt.category,
SUM(od.quantity) AS total_quantity
FROM pizzas p
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od
ON od.pizza_id = p.pizza_id
GROUP BY pt.category;

-- 7. Determine the distribution of orders by hour of the day
SELECT
HOUR(order_time) AS order_hour,
COUNT(order_id) AS order_count
FROM orders
GROUP BY HOUR(order_time)
ORDER BY order_hour;

-- 8. Find the category-wise distribution of pizzas
SELECT
category,
COUNT(name) AS pizza_count
FROM pizza_types
GROUP BY category;

-- 9. Calculate the average number of pizzas ordered per day
WITH daily_orders AS (
SELECT
o.order_date,
SUM(od.quantity) AS total_pizzas
FROM orders o
JOIN order_details od
ON od.order_id = o.order_id
GROUP BY o.order_date
)
SELECT
ROUND(AVG(total_pizzas), 2) AS avg_pizzas_per_day
FROM daily_orders;

-- 10. Determine the top 3 most ordered pizza types based on revenue
SELECT
pt.name AS pizza_type,
ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;

/* =====================================================
ADVANCED ANALYSIS
===================================================== */

-- 11. Calculate the percentage contribution of each pizza category to total revenue
SELECT
pt.category,
CONCAT(
ROUND(
SUM(od.quantity * p.price) /
(SELECT SUM(od2.quantity * p2.price)
FROM order_details od2
JOIN pizzas p2
ON p2.pizza_id = od2.pizza_id) * 100, 2
), '%'
) AS revenue_percentage
FROM order_details od
JOIN pizzas p
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY revenue_percentage DESC;

-- 12. Analyze the cumulative revenue generated over time (monthly)
WITH monthly_revenue AS (
SELECT
YEAR(o.order_date) AS year,
MONTH(o.order_date) AS month,
SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p
ON p.pizza_id = od.pizza_id
JOIN orders o
ON o.order_id = od.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
)
SELECT
CONCAT(month, '/', year) AS order_month,
ROUND(SUM(total_revenue)
OVER (ORDER BY year, month), 2) AS cumulative_revenue
FROM monthly_revenue;

-- 13. Determine the top 3 most ordered pizza types based on revenue for each category
WITH category_revenue AS (
SELECT
pt.name,
pt.category,
SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p
ON p.pizza_id = od.pizza_id
JOIN pizza_types pt
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category, pt.name
),
ranked_pizzas AS (
SELECT *,
RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS rank_in_category
FROM category_revenue
)
SELECT *
FROM ranked_pizzas
WHERE rank_in_category <= 3;
