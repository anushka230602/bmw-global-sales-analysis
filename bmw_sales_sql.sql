/*BMW Global Sales Analysis - SQL Project
Author: Anushka Yadav

1. Dataset Exploration
2. Data Cleaning
3. KPI Analysis
4. Regional Performance
5. Product Analysis
6. EV Market Trends
7. Economic Impact
8. Advanced SQL Analysis
*/

-- 1. Dataset Overview

SELECT COUNT(*) AS total_records
FROM bmw_global_sales;

SELECT MIN(year), MAX(year)
FROM bmw_global_sales;

SELECT COUNT(DISTINCT region) AS total_regions
FROM bmw_global_sales;

SELECT COUNT(DISTINCT model) AS total_models
FROM bmw_global_sales;
-- 2. Data Cleaning

SELECT *
FROM bmw_global_sales
WHERE units_sold IS NULL
OR revenue_eur IS NULL
OR avg_price_eur IS NULL;

SELECT year, month, region, model, COUNT(*)
FROM bmw_global_sales
GROUP BY year, month, region, model
HAVING COUNT(*) > 1;


-- 3. KPI Analysis

--Total revenue
SELECT SUM(revenue_eur) AS total_revenue
FROM bmw_global_sales;

--Total units sold
SELECT SUM(units_sold) AS total_units
FROM bmw_global_sales;

--Average selling price
SELECT AVG(avg_price_eur) AS avg_vehicle_price
FROM bmw_global_sales;

--Average Battery Electric Vehicle Share
SELECT AVG(bev_share) AS avg_bev_share
FROM bmw_global_sales;


-- 3. Regional Market Performance

--Revenue by region
SELECT region,
SUM(revenue_eur) AS revenue
FROM bmw_global_sales
GROUP BY region
ORDER BY revenue DESC;

--Units sold by region
SELECT region,
       SUM(units_sold) AS units
FROM bmw_global_sales
GROUP BY region
ORDER BY units DESC;

-- avg price per region
SELECT region,
       AVG(avg_price_eur) AS avg_price
FROM bmw_global_sales
GROUP BY region
ORDER BY avg_price DESC;


-- 4. Model Performance

--Top Selling Models
SELECT model,
       SUM(units_sold) AS units
FROM bmw_global_sales
GROUP BY model
ORDER BY units DESC;

-- Highest Revenue Models
SELECT model,
       SUM(revenue_eur) AS revenue
FROM bmw_global_sales
GROUP BY model
ORDER BY revenue DESC;

-- 5.Market Share Analysis

SELECT 
region,
SUM(units_sold) AS units,
ROUND(
SUM(units_sold)*100.0 /
SUM(SUM(units_sold)) OVER(),
2
) AS market_share_percent
FROM bmw_global_sales
GROUP BY region
ORDER BY market_share_percent DESC;

-- 6.Yearly Sales Trend

SELECT year,
SUM(units_sold) AS sales
FROM bmw_global_sales
GROUP BY year
ORDER BY year;

--7. Revenue Trend
SELECT year,
SUM(revenue_eur) AS revenue
FROM bmw_global_sales
GROUP BY year
ORDER BY year;


-- 8.Year-over-Year Revenue Growth
SELECT 
year,
SUM(revenue_eur) AS revenue,
LAG(SUM(revenue_eur)) OVER(ORDER BY year) AS prev_year,
ROUND(
(
SUM(revenue_eur) -
LAG(SUM(revenue_eur)) OVER(ORDER BY year)
)*100.0 /
LAG(SUM(revenue_eur)) OVER(ORDER BY year),
2
) AS growth_percent
FROM bmw_global_sales
GROUP BY year
ORDER BY year;

-- 9. Monthly Demand Pattern
SELECT month,
SUM(units_sold) AS monthly_sales
FROM bmw_global_sales
GROUP BY month
ORDER BY month;


-- 10. EV Market Growth
SELECT year,
AVG(bev_share) AS bev_share
FROM bmw_global_sales
GROUP BY year
ORDER BY year;


-- 11. Regions Leading EV Adoption
SELECT region,
AVG(bev_share) AS bev_share
FROM bmw_global_sales
GROUP BY region
ORDER BY bev_share DESC;

-- 12. Premium Segment Demand
SELECT region,
AVG(premium_share) AS premium_market
FROM bmw_global_sales
GROUP BY region
ORDER BY premium_market DESC;


-- 13. GDP Impact on Sales
SELECT year,
AVG(gdp_growth) AS gdp,
SUM(units_sold) AS sales
FROM bmw_global_sales
GROUP BY year
ORDER BY year;


-- 14. Fuel Price Impact
SELECT fuel_price_index,
SUM(units_sold) AS sales
FROM bmw_global_sales
GROUP BY fuel_price_index
ORDER BY fuel_price_index;

-- 15. Best Model in Each Region
WITH model_sales AS (
    SELECT 
        Region,
        Model,
        SUM(Units_Sold) AS total_units
    FROM bmw_global_sales
    GROUP BY Region, Model
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY Region ORDER BY total_units DESC) AS rank_in_region
    FROM model_sales
)

SELECT 
    Region,
    Model,
    total_units
FROM ranked
WHERE rank_in_region = 1;

-- 16. Price vs Demand Analysis
SELECT 
ROUND(avg_price_eur, -3) AS price_bucket,
SUM(units_sold) AS units
FROM bmw_global_sales
GROUP BY price_bucket
ORDER BY price_bucket;

