/*__________________________________________BASIC SQL QUERIES______________________________________________*/

-- Query 1] total number of orders placed. 

CREATE DATABASE dominos;
USE dominos;
SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;
    
/*_________________________________________________________________________________________________________*/

-- Query 2] TOTAL REVENUE GENERATED FROM PIZZA ORDERS

SELECT 
    ROUND(SUM(pizzas.price * orders_details.quantity),
            2) AS total_sales
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id;
    
/*_________________________________________________________________________________________________________*/

-- Query 3] Highest priced pizza.

SELECT name,price AS highest_price
FROM 
pizza_types JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
WHERE pizzas.price = (SELECT MAX(price) FROM pizzas);
 
-- alternative method
 
SELECT name,price AS highest_price
FROM pizzas JOIN pizza_types
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC
LIMIT 1;

/*__________________________________________________________________________________________________________*/

-- Query 4] Most common pizza size ordered

SELECT size,COUNT(order_details_id) AS ordered
FROM 
pizzas JOIN orders_details
ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY size
ORDER BY ordered DESC
LIMIT 1;

-- alternative method

SELECT size,COUNT(size) AS ordered
FROM 
pizzas JOIN orders_details
ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY size
ORDER BY ordered DESC
LIMIT 1;

/*____________________________________________________________________________________________________________*/

-- Query 5] Top 5 most ordered pizza types along with their quantities.

SELECT pizza_types.name, SUM(orders_details.quantity) as quantity
FROM pizzas 
JOIN orders_details 
ON pizzas.pizza_id = orders_details.pizza_id
JOIN pizza_types
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY name
ORDER BY quantity DESC
LIMIT 5;

/*___________________________________INTERMEDIATE SQL QUERIES________________________________________________*/

-- Query 6] Total quantity of each pizza category ordered.

SELECT category, SUM(quantity) as quantity 
FROM pizzas 
JOIN pizza_types
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY category
ORDER BY quantity DESC;

/*_____________________________________________________________________________________________________________*/

-- Query 7] Distribution of orders by hour of the day.
-- (calls from customers)

SELECT hour(order_time) AS hours, count(order_id) AS order_calls
FROM orders
GROUP BY hours;

/*______________________________________________________________________________________________________________*/

-- Query 8] Category-wise distribution of pizzas.

SELECT category,COUNT(pizza_type_id) AS types
FROM pizza_types
GROUP BY category;

/*______________________________________________________________________________________________________________*/

-- Query 9] Average number of pizzas ordered per day.

SELECT AVG(tot_pizzas) AS averageOrder_day
FROM
(SELECT orders.order_date, sum(orders_details.quantity) as tot_pizzas
FROM orders
JOIN orders_details
ON orders.order_id = orders_details.order_id
GROUP BY orders.order_date) AS order_quantity;

/*___________________________________________________________________________________*/

-- Query 10] Top 3 most ordered pizza types based on revenue.

SELECT pizza_types.name, SUM(price*quantity) as T_cost
FROM pizza_types
JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY T_cost DESC
LIMIT 3;

/*_________________________________ADVANCED SQL QUERIES___________________________________________*/

-- Query 11] Percentage contribution of each pizza type to total revenue.

SELECT pizza_types.category , ROUND(SUM(price * quantity),1) as revenue
FROM pizzas JOIN pizza_types 
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY category;

-- Now for percentage, we need to divide each revenue by total revenue and then multiply by 100
-- we will write the same above query but we will update the 'revenue' column by inserting a new
-- sub query in it. The subquery will find the total revenue of the entire database.

SELECT pizza_types.category, ROUND(SUM(price * quantity)/    -- here there was revenue, we will edit here.
(SELECT ROUND(SUM(price * quantity),0) FROM pizzas 
JOIN orders_details
ON pizzas.pizza_id = orders_details.pizza_id)*100,1)
AS revenue FROM pizzas JOIN pizza_types                      -- column name {just shifted down}.
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY category;

/*______________________________________________________________________________________________*/

-- Query 12] Analyzing the Cumulative revenue generated over time.

SELECT order_date, ROUND(SUM(price * quantity),0) AS amount
FROM orders JOIN orders_details
ON orders.order_id = orders_details.order_id
JOIN pizzas ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY order_date;

-- Now making the whole above table as a subquery

SELECT order_date, SUM(amount) OVER (ORDER BY order_date)
AS cumulative_revenue FROM
(SELECT order_date, ROUND(SUM(price * quantity),0) AS amount
FROM orders JOIN orders_details
ON orders.order_id = orders_details.order_id
JOIN pizzas ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY order_date ) AS revenue;

/*______________________________________________________________________________________________________*/

/*
Query 13] Top 3 most ordered pizza types based on revenue for each pizza category
Means in chicken top 3, in italian  top 3, in classic top 3 etc
*/

SELECT category,name,revenue,rn
FROM
(SELECT pizza_types.category,pizza_types.name,
SUM(orders_details.quantity * pizzas.price) AS revenue,
RANK() over(partition by category ORDER BY SUM(orders_details.quantity * pizzas.price) DESC) AS rn
FROM orders_details JOIN pizzas ON orders_details.pizza_id = pizzas.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY category,name) AS a
WHERE rn<=3;

-- Alternative Method

SELECT name,revenue,rn
FROM (SELECT category, name, revenue,
RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
FROM (SELECT pizza_types.category, pizza_types.name,
SUM((orders_details.quantity) * pizzas.price) 
AS revenue FROM pizza_types JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category, pizza_types.name) AS a) AS b
WHERE rn <=3;

/*
This double nesting of select was needed because rn is not recognised because rank(){wrote in first line}
is executed after where {last line},
So, 'where' is executed before the creation of rn , which gives error; but if we make rn in a subquery
then 'where' will work in outer query.
NOTE: This means to make 'where' clause work, it works only on nested query when window functions 
are used in outer queries.
*/

/*___________________________________________________________________________________________________________*/