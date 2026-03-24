-- ============================================================
-- BMW GLOBAL SALES ANALYSIS - SQL PROJECT
-- Author: Anushka Yadav
-- ============================================================

-- This file performs exploratory data analysis (EDA) on BMW global sales data
-- to understand business performance, market trends, and key drivers.


-- ============================================================
-- 1. DATASET OVERVIEW
-- Objective: Understand dataset size, coverage, and diversity
-- Why this matters: Ensures data completeness before analysis
-- Expected Insight: Dataset spans multiple years, regions, and models
-- ============================================================

SELECT COUNT(*) AS total_records
FROM bmw_global_sales;

SELECT MIN(year) AS start_year, MAX(year) AS end_year
FROM bmw_global_sales;

SELECT COUNT(DISTINCT region) AS total_regions
FROM bmw_global_sales;

SELECT COUNT(DISTINCT model) AS total_models
FROM bmw_global_sales;



-- ============================================================
-- 2. DATA CLEANING
-- Objective: Identify missing values and duplicate records
-- Why this matters: Ensures data accuracy and reliability
-- Expected Insight: Minimal nulls and duplicates indicate clean dataset
-- ============================================================

SELECT *
FROM bmw_global_sales
WHERE units_sold IS NULL
   OR revenue_eur IS NULL
   OR avg_price_eur IS NULL;

SELECT year, month, region, model, COUNT(*) AS duplicate_count
FROM bmw_global_sales
GROUP BY year, month, region, model
HAVING COUNT(*) > 1;



-- ============================================================
-- 3. KPI ANALYSIS
-- Objective: Calculate key business metrics
-- Why this matters: Provides high-level performance overview
-- Expected Insight: Strong revenue base with measurable EV adoption
-- ============================================================

-- Total Revenue
SELECT SUM(revenue_eur) AS total_revenue
FROM bmw_global_sales;

-- Total Units Sold
SELECT SUM(units_sold) AS total_units
FROM bmw_global_sales;

-- Average Selling Price
SELECT AVG(avg_price_eur) AS avg_vehicle_price
FROM bmw_global_sales;

-- Average EV Share
SELECT AVG(bev_share) AS avg_bev_share
FROM bmw_global_sales;



-- ============================================================
-- 4. REGIONAL MARKET PERFORMANCE
-- Objective: Compare performance across regions
-- Why this matters: Identifies key markets and revenue drivers
-- Expected Insight: Revenue likely evenly distributed across major regions
-- ============================================================

-- Revenue by Region
SELECT region,
       SUM(revenue_eur) AS revenue
FROM bmw_global_sales
GROUP BY region
ORDER BY revenue DESC;

-- Units Sold by Region
SELECT region,
       SUM(units_sold) AS units
FROM bmw_global_sales
GROUP BY region
ORDER BY units DESC;

-- Average Price by Region
SELECT region,
       AVG(avg_price_eur) AS avg_price
FROM bmw_global_sales
GROUP BY region
ORDER BY avg_price DESC;



-- ============================================================
-- 5. MODEL PERFORMANCE
-- Objective: Identify top-performing products
-- Why this matters: Highlights demand drivers and product strategy
-- Expected Insight: EV and SUV models may dominate sales and revenue
-- ============================================================

-- Top Selling Models (by Units)
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



-- ============================================================
-- 6. MARKET SHARE ANALYSIS
-- Objective: Measure contribution of each region to total sales
-- Why this matters: Identifies dominant and underperforming markets
-- Expected Insight: Balanced distribution across major regions
-- ============================================================

SELECT 
    region,
    SUM(units_sold) AS units,
    ROUND(
        SUM(units_sold) * 100.0 /
        SUM(SUM(units_sold)) OVER(),
    2) AS market_share_percent
FROM bmw_global_sales
GROUP BY region
ORDER BY market_share_percent DESC;



-- ============================================================
-- 7. YEARLY SALES TREND
-- Objective: Analyze long-term sales growth
-- Why this matters: Identifies growth patterns and inflection points
-- Expected Insight: Growth acceleration post-2020
-- ============================================================

SELECT year,
       SUM(units_sold) AS sales
FROM bmw_global_sales
GROUP BY year
ORDER BY year;



-- ============================================================
-- 8. REVENUE TREND
-- Objective: Track revenue growth over time
-- Why this matters: Measures financial performance
-- Expected Insight: Revenue growth may outpace units (pricing effect)
-- ============================================================

SELECT year,
       SUM(revenue_eur) AS revenue
FROM bmw_global_sales
GROUP BY year
ORDER BY year;



-- ============================================================
-- 9. YEAR-OVER-YEAR (YoY) REVENUE GROWTH
-- Objective: Measure annual growth rate
-- Why this matters: Evaluates business expansion or slowdown
-- Expected Insight: Low growth may indicate market maturity
-- ============================================================

SELECT 
    year,
    SUM(revenue_eur) AS revenue,
    LAG(SUM(revenue_eur)) OVER(ORDER BY year) AS prev_year,
    ROUND(
        (SUM(revenue_eur) - LAG(SUM(revenue_eur)) OVER(ORDER BY year)) * 100.0 /
        LAG(SUM(revenue_eur)) OVER(ORDER BY year),
    2) AS growth_percent
FROM bmw_global_sales
GROUP BY year
ORDER BY year;



-- ============================================================
-- 10. MONTHLY DEMAND PATTERN
-- Objective: Identify seasonal sales patterns
-- Why this matters: Helps in demand planning and inventory management
-- Expected Insight: Certain months may show peak demand
-- ============================================================

SELECT month,
       SUM(units_sold) AS monthly_sales
FROM bmw_global_sales
GROUP BY month
ORDER BY month;



-- ============================================================
-- 11. EV MARKET GROWTH
-- Objective: Track EV adoption over time
-- Why this matters: Key indicator of industry transition
-- Expected Insight: Steady increase in EV share
-- ============================================================

SELECT year,
       AVG(bev_share) AS bev_share
FROM bmw_global_sales
GROUP BY year
ORDER BY year;



-- ============================================================
-- 12. REGIONAL EV ADOPTION
-- Objective: Compare EV adoption across regions
-- Why this matters: Identifies leading EV markets
-- Expected Insight: Developed regions show higher adoption
-- ============================================================

SELECT region,
       AVG(bev_share) AS bev_share
FROM bmw_global_sales
GROUP BY region
ORDER BY bev_share DESC;



-- ============================================================
-- 13. PREMIUM SEGMENT DEMAND
-- Objective: Analyze demand for premium vehicles
-- Why this matters: Indicates profitability and market positioning
-- Expected Insight: USA & China may lead premium demand
-- ============================================================

SELECT region,
       AVG(premium_share) AS premium_market
FROM bmw_global_sales
GROUP BY region
ORDER BY premium_market DESC;



-- ============================================================
-- 14. GDP IMPACT ON SALES
-- Objective: Analyze relationship between economic growth and sales
-- Why this matters: Links macroeconomic factors to business performance
-- Expected Insight: Higher GDP growth correlates with higher sales
-- ============================================================

SELECT year,
       AVG(gdp_growth) AS gdp,
       SUM(units_sold) AS sales
FROM bmw_global_sales
GROUP BY year
ORDER BY year;



-- ============================================================
-- 15. FUEL PRICE IMPACT
-- Objective: Understand impact of fuel prices on demand
-- Why this matters: Fuel cost influences vehicle purchasing decisions
-- Expected Insight: Higher fuel prices may increase EV demand
-- ============================================================

SELECT fuel_price_index,
       SUM(units_sold) AS sales
FROM bmw_global_sales
GROUP BY fuel_price_index
ORDER BY fuel_price_index;



-- ============================================================
-- 16. BEST MODEL IN EACH REGION
-- Objective: Identify top-performing model per region
-- Why this matters: Helps in regional product strategy
-- Expected Insight: Different regions prefer different models
-- ============================================================

WITH model_sales AS (
    SELECT 
        region,
        model,
        SUM(units_sold) AS total_units
    FROM bmw_global_sales
    GROUP BY region, model
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY region ORDER BY total_units DESC) AS rank_in_region
    FROM model_sales
)
SELECT region, model, total_units
FROM ranked
WHERE rank_in_region = 1;



-- ============================================================
-- 17. PRICE VS DEMAND ANALYSIS
-- Objective: Analyze how price affects demand
-- Why this matters: Helps understand price sensitivity
-- Expected Insight: Mid-range price segments may dominate sales
-- ============================================================

SELECT 
    ROUND(avg_price_eur, -3) AS price_bucket,
    SUM(units_sold) AS units
FROM bmw_global_sales
GROUP BY price_bucket
ORDER BY price_bucket;



-- ============================================================
-- FINAL SUMMARY
-- ============================================================

-- Key Takeaways:
-- 1. Strong global revenue base with moderate growth
-- 2. EV adoption increasing steadily → future growth driver
-- 3. Premium models contribute significantly to revenue
-- 4. Regional markets are well-balanced → diversified risk
-- 5. Pricing plays a critical role in demand distribution

-- Conclusion:
-- Future growth depends on EV expansion, premium positioning,
-- and leveraging high-growth regions.
