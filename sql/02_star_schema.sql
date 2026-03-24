-- ============================================================
-- BMW GLOBAL SALES - STAR SCHEMA CREATION
-- Author: Anushka Yadav
-- ============================================================

-- This script transforms raw transactional data into a structured
-- star schema for efficient analytics and reporting.


-- ============================================================
-- 1. DIMENSION TABLES CREATION
-- Objective: Create descriptive tables for filtering and slicing data
-- Why this matters: Improves query performance and enables BI analysis
-- ============================================================


-- ------------------------------------------------------------
-- DIM_DATE
-- Stores time-related attributes for time-series analysis
-- Enables year, month, and quarter-based reporting
-- ------------------------------------------------------------

CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    year INT NOT NULL,
    month INT NOT NULL,
    quarter INT GENERATED ALWAYS AS ((month-1)/3 + 1) STORED,
    month_name VARCHAR(10) GENERATED ALWAYS AS (
        CASE month
            WHEN 1 THEN 'Jan' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar'
            WHEN 4 THEN 'Apr' WHEN 5 THEN 'May' WHEN 6 THEN 'Jun'
            WHEN 7 THEN 'Jul' WHEN 8 THEN 'Aug' WHEN 9 THEN 'Sep'
            WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dec'
        END
    ) STORED,
    UNIQUE(year, month)
);



-- ------------------------------------------------------------
-- DIM_REGION
-- Stores geographical information
-- Enables regional performance analysis
-- ------------------------------------------------------------

CREATE TABLE dim_region (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(50) UNIQUE
);



-- ------------------------------------------------------------
-- DIM_MODEL
-- Stores product-level attributes
-- Includes segment classification and pricing
-- ------------------------------------------------------------

CREATE TABLE dim_model (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(50) UNIQUE,
    segment VARCHAR(20),
    avg_price_eur NUMERIC
);



-- ============================================================
-- 2. FACT TABLE CREATION
-- Objective: Store measurable business metrics
-- Why this matters: Central table for all analytics
-- ============================================================

CREATE TABLE fact_sales (
    sales_id SERIAL PRIMARY KEY,
    date_id INT NOT NULL REFERENCES dim_date(date_id),
    region_id INT NOT NULL REFERENCES dim_region(region_id),
    model_id INT NOT NULL REFERENCES dim_model(model_id),
    units_sold INT,
    revenue_eur NUMERIC,
    bev_share NUMERIC,
    premium_share NUMERIC,
    fuel_price_index NUMERIC,
    gdp_growth NUMERIC
);



-- ============================================================
-- 3. POPULATE DIMENSION TABLES
-- Objective: Extract unique attributes from raw dataset
-- Why this matters: Avoids redundancy and ensures consistency
-- ============================================================


-- ------------------------------------------------------------
-- Populate DIM_DATE
-- Extract distinct year-month combinations
-- ------------------------------------------------------------

INSERT INTO dim_date (year, month)
SELECT DISTINCT 
    year, 
    month::INT
FROM bmw_global_sales;



-- ------------------------------------------------------------
-- Populate DIM_REGION
-- Extract unique regions
-- ------------------------------------------------------------

INSERT INTO dim_region (region_name)
SELECT DISTINCT region
FROM bmw_global_sales;



-- ------------------------------------------------------------
-- Populate DIM_MODEL
-- Extract unique models and assign average price
-- ------------------------------------------------------------

INSERT INTO dim_model (model_name, avg_price_eur)
SELECT DISTINCT model, AVG(avg_price_eur)
FROM bmw_global_sales
GROUP BY model;



-- ============================================================
-- 4. SEGMENT CLASSIFICATION
-- Objective: Categorize models into business segments
-- Why this matters: Enables segment-level analysis in BI tools
-- ============================================================


-- SUV Segment
UPDATE dim_model
SET segment = 'SUV'
WHERE model_name IN ('X5', 'X6', 'X7');

-- Sedan Segment
UPDATE dim_model
SET segment = 'Sedan'
WHERE model_name IN ('3 Series', '5 Series', '7 Series');

-- EV Segment
UPDATE dim_model
SET segment = 'EV'
WHERE model_name IN ('i3', 'iX', 'i4');



-- ============================================================
-- 5. POPULATE FACT TABLE
-- Objective: Link dimensions with transactional data
-- Why this matters: Enables relational analytics via joins
-- ============================================================

INSERT INTO fact_sales (
    date_id,
    region_id,
    model_id,
    units_sold,
    revenue_eur,
    bev_share,
    premium_share,
    fuel_price_index,
    gdp_growth
)
SELECT 
    d.date_id,
    r.region_id,
    m.model_id,
    b.units_sold,
    b.revenue_eur,
    b.bev_share,
    b.premium_share,
    b.fuel_price_index,
    b.gdp_growth
FROM bmw_global_sales b

-- Join with Date Dimension
JOIN dim_date d 
    ON b.year::INT = d.year
    AND b.month::INT = d.month

-- Join with Region Dimension
JOIN dim_region r 
    ON b.region = r.region_name

-- Join with Model Dimension
JOIN dim_model m 
    ON b.model = m.model_name;



-- ============================================================
-- FINAL SUMMARY
-- ============================================================

-- Key Achievements:
-- 1. Converted raw flat dataset into structured star schema
-- 2. Separated data into fact and dimension tables
-- 3. Enabled efficient analytical queries and BI reporting
-- 4. Added business logic via segment classification

-- Outcome:
-- This schema supports scalable analytics, improves query performance,
-- and aligns with industry-standard data warehouse design practices.
