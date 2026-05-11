DROP TABLE IF EXISTS ORDERS_DATA;

CREATE TABLE orders_data (
    order_item TEXT,
    order_id BIGINT,
    order_date TIMESTAMP,
    allot_time TIMESTAMP,
    accept_time TIMESTAMP,
    pickup_time TIMESTAMP,
    delivered_time TIMESTAMP,
    rider_id BIGINT,
    first_mile DECIMAL,
    last_mile DECIMAL,
    alloted_orders DECIMAL,
    delivered_orders DECIMAL,
    cancelled DECIMAL,
    undelivered_orders DECIMAL,
    lifetime_order_count DECIMAL,
    reassignment_method TEXT,
    reassignment_reason TEXT,
    reassigned_order TEXT,
    session_time TEXT,
    cancelled_time TIMESTAMP
);


SELECT * FROM orders_data;


COPY orders_data
FROM 'D:/swiggyzomato_sql_project_dataset/Rider-Info.csv'
DELIMITER ','
CSV HEADER;


CREATE TABLE swiggy_orders_clean AS
SELECT
    order_id,
    order_date,
    rider_id,
    first_mile,
    last_mile,
	accept_time,
    alloted_orders,
    delivered_orders,
    cancelled,
	pickup_time,
    undelivered_orders,
    lifetime_order_count,
    reassignment_method,
    reassignment_reason,
    EXTRACT(EPOCH FROM (pickup_time - accept_time))/60 AS
	rider_pickup_minutes,
    EXTRACT(EPOCH FROM (delivered_time - pickup_time))/60 AS
	delivery_minutes,
    EXTRACT(EPOCH FROM (delivered_time - allot_time))/60 AS
	total_delivery_minutes
FROM orders_data;


--Top riders with delivery + cancel percentage


SELECT 
    rider_id,
    SUM(COALESCE(delivered_orders, 0)) AS
	total_orders,
    ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time,
    ROUND(SUM(COALESCE(cancelled,0)) * 100.0 / 
        NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled,0)), 0), 2) 
     	AS cancel_percentage
FROM swiggy_orders_clean
GROUP BY rider_id
ORDER BY total_orders DESC
LIMIT 10;


--Top riders with highest cancelled orders


SELECT
	rider_id,
	SUM(COALESCE(cancelled, 0)) AS
	total_cancel_orders
FROM swiggy_orders_clean
GROUP BY rider_id
ORDER BY total_cancel_orders DESC
LIMIT 10;


--Overall average delivery time


SELECT
	ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean;


--Peak order demand by hour


SELECT
	EXTRACT('HOUR' FROM accept_time) AS
	hours,
	COUNT(order_id) AS
	total_orders
FROM swiggy_orders_clean
GROUP BY 1
ORDER BY total_orders DESC;


--Distance vs delivery time analysis


SELECT 
    rider_id,
    ROUND(AVG(first_mile), 2) AS
	avg_first_mile,
    ROUND(AVG(last_mile), 2) AS
	avg_last_mile,
    ROUND(AVG(first_mile) + AVG(last_mile), 2) AS
	avg_total_distance,
    ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING COUNT(order_id) >= 50
ORDER BY avg_total_distance DESC
LIMIT 10;


--Slowest riders


SELECT
	rider_id,
	COUNT(order_id) AS
	total_orders,
	ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING COUNT(order_id) >= 50
ORDER BY avg_delivery_time DESC
LIMIT 5;


--Orders above 120 minutes


SELECT
	order_id,
	ROUND(total_delivery_minutes, 2) AS
	total_delivery_time
FROM swiggy_orders_clean
WHERE total_delivery_minutes > 120;


--Overall cancellation percentage


SELECT
	ROUND(SUM(COALESCE(cancelled, 0)) * 100.0 /
	NULLIF(SUM(delivered_orders + cancelled + undelivered_orders), 0),2) AS
	cancel_percentage
FROM swiggy_orders_clean;


--Fastest riders with high volume


SELECT
	rider_id,
	SUM(delivered_orders) AS
	total_Orders,
	ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING SUM(delivered_orders) >= 50
ORDER BY avg_delivery_time ASC
LIMIT 5;


--Highest cancellation percentage riders


SELECT
	rider_id,
	SUM(COALESCE(delivered_orders, 0)) AS 
	total_orders,
	SUM(COALESCE(cancelled, 0)) AS
	cancelled_orders,
	ROUND(SUM(COALESCE(cancelled, 0)) * 100.0 /
	NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
	cancel_percentage
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING SUM(delivered_orders) >= 50
ORDER BY cancel_percentage DESC
LIMIT 5;


--Fast riders below average delivery time


SELECT
    rider_id,
    SUM(COALESCE(delivered_orders, 0)) AS
	total_orders,
    ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING AVG(total_delivery_minutes) < (SELECT AVG(total_delivery_minutes)
    FROM swiggy_orders_clean)
AND SUM(COALESCE(delivered_orders, 0)) >= 50
ORDER BY total_orders DESC
LIMIT 5;


--High cancel percentage riders with volume


SELECT
    rider_id,
    SUM(COALESCE(delivered_orders, 0)) AS
	total_orders,
    ROUND(SUM(COALESCE(cancelled, 0)) * 100.0 /
    NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS cancel_percentage
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING SUM(delivered_orders) >= 50
ORDER BY cancel_percentage DESC, total_orders DESC
LIMIT 5;


-- Riders with high delivery time and high cancellation percentage


SELECT
    rider_id,
    ROUND(SUM(COALESCE(cancelled, 0)) * 100.0 /
        NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
		cancel_percentage,
    ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING SUM(delivered_orders) >= 50
AND AVG(total_delivery_minutes) > (SELECT AVG(total_delivery_minutes)
    FROM swiggy_orders_clean)
AND ROUND(SUM(COALESCE(cancelled, 0)) * 100.0 /
        SUM(delivered_orders + cancelled), 2) > 5
ORDER BY avg_delivery_time, cancel_percentage DESC;


-- Distance vs delivery time analysis for riders


SELECT
    rider_id,
	COUNT(order_id) AS
total_orders,
	ROUND(AVG(first_mile), 2) AS
avg_first_mile,
    ROUND(AVG(last_mile), 2) AS
avg_last_mile,
    ROUND(AVG(total_delivery_minutes), 2) AS
avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING COUNT(order_id) >= 50
ORDER BY avg_delivery_time DESC
LIMIT 10;


-- Rider reassignment, cancellation, and delivery performance analysis

SELECT
	rider_id, 
	COUNT(order_id) AS
total_orders,
	ROUND(COUNT(reassignment_reason) * 100.0 /
	NULLIF(COUNT(order_id), 0), 2) AS
reassignment_percentage,
	ROUND(SUM(COALESCE(cancelled, 0))* 100.0 /
    NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
cancel_percentage,
	ROUND(AVG(total_delivery_minutes), 2) AS 
avg_delivery_time
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING COUNT(order_id) >= 50
ORDER BY avg_delivery_time DESC,
	cancel_percentage DESC,
	reassignment_percentage DESC
;


-- Peak demand hours with delivery and cancellation metrics


SELECT
	EXTRACT('HOUR' FROM accept_time) AS
	hours,
	COUNT(order_id) AS
	total_orders,
	SUM(COALESCE(delivered_orders, 0)) AS
	total_delivered_orders,
	ROUND(SUM(COALESCE(cancelled, 0))* 100.0 /
        NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
cancel_percentage
FROM swiggy_orders_clean
GROUP BY EXTRACT('HOUR' FROM accept_time)
ORDER BY hours ASC
;


-- Weekday-wise order volume and delivery performance analysis


SELECT
	TRIM(TO_CHAR(order_date, 'DAY')) AS
	weekday,
	COUNT(order_id) AS
	total_orders,
	ROUND(AVG(total_delivery_minutes), 2) AS
	total_delivery_time,
	ROUND(SUM(COALESCE(cancelled, 0))* 100.0 /
    NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
	cancel_percentage
FROM swiggy_orders_clean
GROUP BY TRIM(TO_CHAR(order_date, 'DAY'))
ORDER BY total_orders DESC
;


-- Rider speed ranking compared to platform average delivery time


SELECT 
    rider_id,
    total_orders,
    avg_delivery_time,
    RANK() OVER (ORDER BY avg_delivery_time ASC) AS speed_rank,
    ROUND(avg_delivery_time - AVG(avg_delivery_time) OVER (), 2) AS
	diff_from_platform_avg
FROM (
    SELECT 
        rider_id,
        SUM(COALESCE(delivered_orders, 0)) AS total_orders,
        ROUND(AVG(total_delivery_minutes), 2) AS avg_delivery_time
    FROM swiggy_orders_clean
    GROUP BY rider_id
    HAVING SUM(COALESCE(delivered_orders, 0)) >= 50
) AS rider_summary
ORDER BY speed_rank;


-- Top rider in each hour based on order volume using window function


WITH hourly_riders AS (
    SELECT 
        EXTRACT('HOUR' FROM accept_time) AS hour_of_day,
        rider_id,
        COUNT(order_id) AS
		orders_that_hour,
        ROUND(AVG(total_delivery_minutes), 2) AS
		avg_delivery_time,
        RANK() OVER (
            PARTITION BY EXTRACT('HOUR' FROM accept_time)
            ORDER BY COUNT(order_id) DESC
        ) AS rank_in_hour
    FROM swiggy_orders_clean
    WHERE accept_time IS NOT NULL
    GROUP BY 1, 2
)
SELECT 
    hour_of_day,
    rider_id,
    orders_that_hour,
    avg_delivery_time,
    rank_in_hour
FROM hourly_riders
WHERE rank_in_hour = 1
ORDER BY hour_of_day ASC
;


--Riders with highest pickup delay and delivery performance analysis


SELECT 
	rider_id,
	COUNT(order_id) AS
	total_orders,
	ROUND(AVG(EXTRACT(EPOCH FROM(pickup_time - accept_time)) /
	60), 2) AS
	avg_pickup_delay,
	ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time,
	ROUND(SUM(COALESCE(cancelled, 0))* 100.0 /
    NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
cancel_percentage
FROM swiggy_orders_clean
WHERE pickup_time IS NOT NULL
AND accept_time IS NOT NULL
GROUP BY rider_id
HAVING COUNT(order_id) >= 100
ORDER BY avg_pickup_delay DESC
LIMIT 10
;


--Hour wise peak demand, cancellation, and delivery performance analysis 


SELECT
	EXTRACT('HOUR' FROM accept_time) AS
	hours,
	COUNT(order_id) AS
	total_orders,
	ROUND(SUM(COALESCE(cancelled, 0))* 100.0 /
    NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
    cancel_percentage,
	ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time
FROM swiggy_orders_clean
GROUP BY EXTRACT('HOUR' FROM accept_time)
ORDER BY total_orders DESC,
cancel_percentage DESC,
avg_delivery_time DESC
;


--Fastest riders with high order volume and low cancellation percentage


SELECT 
	rider_id,
	SUM(delivered_orders) AS
	total_orders,
	ROUND(AVG(total_delivery_minutes), 2) AS 
	avg_delivery_time,
	ROUND(SUM(COALESCE(cancelled, 0))* 100.0 /
    NULLIF(SUM(delivered_orders) + SUM(COALESCE(cancelled, 0)), 0), 2) AS
    cancel_percentage
FROM swiggy_orders_clean
GROUP BY rider_id
HAVING SUM(delivered_orders) >= 50
ORDER BY avg_delivery_time ASC,
cancel_percentage ASC
;


--Overall business KPI summary for orders, deliveries, cancellations, riders, and delivery time


SELECT 
	COUNT(order_id) AS
	total_orders,
	COUNT(order_id) - SUM(COALESCE(cancelled, 0)) AS
	total_delivered_orders,
	SUM(cancelled) AS
	total_cancelled_orders,
	ROUND(SUM(cancelled)* 100.0 /
    SUM(delivered_orders + cancelled), 2) AS
	cancel_percentage,
	ROUND(AVG(total_delivery_minutes), 2) AS
	avg_delivery_time,
	COUNT(DISTINCT rider_id) AS
	total_riders
FROM swiggy_orders_clean
;

