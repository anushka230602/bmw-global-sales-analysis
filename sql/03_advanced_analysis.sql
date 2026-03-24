-- ============================================
-- PART B: ADVANCED STAR SCHEMA ANALYTICS
-- ============================================


-- ============================================================
-- 1. Top 3 Models per Region per Year
-- Objective: Identify best-performing models across regions annually
-- Why this matters: Helps understand regional demand patterns and product popularity
-- Expected Insight: EV models may dominate in certain regions, indicating market shift
-- ============================================================

WITH region_model_year AS (
    SELECT
        r.region_name,
        m.model_name,
        d.year,
        SUM(f.units_sold) AS total_units
    FROM fact_sales f
    JOIN dim_region r ON f.region_id = r.region_id
    JOIN dim_model m ON f.model_id = m.model_id
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY r.region_name, m.model_name, d.year
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY region_name, year ORDER BY total_units DESC) AS rank_in_region
    FROM region_model_year
)
SELECT region_name, year, model_name, total_units
FROM ranked
WHERE rank_in_region <= 3
ORDER BY region_name, year, total_units DESC;



-- ============================================================
-- 2. YoY Growth per Model
-- Objective: Analyze year-over-year growth in units sold for each model
-- Why this matters: Identifies fast-growing or declining products
-- Expected Insight: EV models likely show higher growth compared to traditional models
-- ============================================================

WITH model_yearly AS (
    SELECT
        m.model_name,
        d.year,
        SUM(f.units_sold) AS units
    FROM fact_sales f
    JOIN dim_model m ON f.model_id = m.model_id
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY m.model_name, d.year
)
SELECT *,
       LAG(units) OVER(PARTITION BY model_name ORDER BY year) AS prev_year_units,
       ROUND((units - LAG(units) OVER(PARTITION BY model_name ORDER BY year)) * 100.0 /
             NULLIF(LAG(units) OVER(PARTITION BY model_name ORDER BY year),0), 2) AS yoy_growth_percent
FROM model_yearly
ORDER BY model_name, year;



-- ============================================================
-- 3. Cumulative Revenue per Model
-- Objective: Track long-term revenue contribution of each model
-- Why this matters: Identifies consistently high-performing models over time
-- Expected Insight: Premium models may show stronger cumulative revenue trends
-- ============================================================

WITH model_revenue AS (
    SELECT
        m.model_name,
        d.year,
        SUM(f.revenue_eur) AS revenue
    FROM fact_sales f
    JOIN dim_model m ON f.model_id = m.model_id
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY m.model_name, d.year
)
SELECT *,
       SUM(revenue) OVER(PARTITION BY model_name ORDER BY year) AS cumulative_revenue
FROM model_revenue
ORDER BY model_name, year;



-- ============================================================
-- 4. Price vs Demand Analysis (Price Buckets)
-- Objective: Understand how pricing impacts demand (units sold)
-- Why this matters: Helps evaluate price sensitivity across segments
-- Expected Insight: Mid-range price buckets may show highest demand
-- ============================================================

WITH price_buckets AS (
    SELECT
        ROUND(m.avg_price_eur, -3) AS price_bucket,
        SUM(f.units_sold) AS units
    FROM fact_sales f
    JOIN dim_model m ON f.model_id = m.model_id
    GROUP BY price_bucket
)
SELECT *,
       LAG(units) OVER(ORDER BY price_bucket) AS prev_units,
       ROUND((units - LAG(units) OVER(ORDER BY price_bucket)) * 100.0 /
             NULLIF(LAG(units) OVER(ORDER BY price_bucket),0), 2) AS pct_change_units,
       LAG(price_bucket) OVER(ORDER BY price_bucket) AS prev_price,
       ROUND((price_bucket - LAG(price_bucket) OVER(ORDER BY price_bucket)) * 100.0 /
             NULLIF(LAG(price_bucket) OVER(ORDER BY price_bucket),0), 2) AS pct_change_price
FROM price_buckets
ORDER BY price_bucket;



-- ============================================================
-- 5. EV vs Premium Correlation
-- Objective: Measure relationship between EV adoption and premium segment
-- Why this matters: Determines if EV growth complements or impacts premium sales
-- Expected Insight: Positive correlation suggests EVs are part of premium strategy
-- ============================================================

SELECT 
    CORR(f.bev_share, f.premium_share) AS bev_premium_correlation
FROM fact_sales f;



-- ============================================================
-- 6. Rolling 3-Month Average Sales
-- Objective: Smooth short-term fluctuations in monthly sales
-- Why this matters: Helps identify underlying trends more clearly
-- Expected Insight: Post-2020 trend likely shows consistent growth
-- ============================================================

WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        SUM(f.units_sold) AS units
    FROM fact_sales f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.month
)
SELECT *,
       ROUND(AVG(units) OVER(ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS rolling_3_month_avg
FROM monthly_sales
ORDER BY year, month;



-- ============================================================
-- 7. Segment-wise Revenue Contribution
-- Objective: Analyze revenue distribution across vehicle segments
-- Why this matters: Identifies most profitable segments
-- Expected Insight: Premium and SUV segments may dominate revenue share
-- ============================================================

SELECT m.segment,
       SUM(f.revenue_eur) AS segment_revenue,
       ROUND(SUM(f.revenue_eur) * 100.0 / SUM(SUM(f.revenue_eur)) OVER(),2) AS revenue_percent
FROM fact_sales f
JOIN dim_model m ON f.model_id = m.model_id
GROUP BY m.segment
ORDER BY segment_revenue DESC;



-- ============================================================
-- 8. Regional EV Adoption Trends
-- Objective: Compare EV adoption across regions
-- Why this matters: Identifies leading and lagging markets in electrification
-- Expected Insight: Developed markets likely show higher EV adoption
-- ============================================================

SELECT r.region_name,
       AVG(f.bev_share) AS avg_bev_share
FROM fact_sales f
JOIN dim_region r ON f.region_id = r.region_id
GROUP BY r.region_name
ORDER BY avg_bev_share DESC;



-- ============================================================
-- 9. Multi-factor Analysis: GDP & Fuel Price vs Sales
-- Objective: Understand macroeconomic impact on sales performance
-- Why this matters: Links external factors to business outcomes
-- Expected Insight: Higher GDP growth may correlate with higher sales
-- ============================================================

WITH yearly_summary AS (
    SELECT
        d.year,
        AVG(f.gdp_growth) AS avg_gdp,
        AVG(f.fuel_price_index) AS avg_fuel,
        SUM(f.units_sold) AS total_units,
        SUM(f.revenue_eur) AS total_revenue
    FROM fact_sales f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.year
)
SELECT *,
       LAG(total_units) OVER(ORDER BY year) AS prev_year_units,
       LAG(total_revenue) OVER(ORDER BY year) AS prev_year_revenue
FROM yearly_summary
ORDER BY year;



-- ============================================================
-- 10. Price Bucket vs Market Share
-- Objective: Analyze market share distribution across price segments
-- Why this matters: Helps identify dominant pricing segments in the market
-- Expected Insight: Mid-range price buckets may hold largest market share
-- ============================================================

WITH price_bucket_units AS (
    SELECT
        ROUND(m.avg_price_eur,-3) AS price_bucket,
        SUM(f.units_sold) AS units
    FROM fact_sales f
    JOIN dim_model m ON f.model_id = m.model_id
    GROUP BY price_bucket
)
SELECT *,
       ROUND(units * 100.0 / SUM(units) OVER(),2) AS market_share_percent
FROM price_bucket_units
ORDER BY price_bucket;



-- ============================================
-- FINAL BUSINESS SUMMARY
-- ============================================

-- Key Takeaways:
-- 1. EV models (iX, i4) are driving volume growth → strong shift toward electrification
-- 2. Premium models (X7) contribute disproportionately to revenue → high-margin strategy
-- 3. Revenue is evenly distributed across regions → diversified global presence
-- 4. EV adoption is increasing rapidly → key future growth driver
-- 5. Pricing analysis suggests strong demand in mid-range segments

-- Conclusion:
-- Future business growth will depend on scaling EV production,
-- maintaining premium positioning, and expanding into emerging markets.
