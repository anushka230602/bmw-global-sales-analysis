
/* =========================================
BMW Global Sales - Star Schema Creation
Author: Anushka Yadav
========================================= */

/*  Create Dimension Tables */

/* Dim Date */

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

/* Dim Region */
CREATE TABLE dim_region (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(50) UNIQUE
);

/* Dim Model */
CREATE TABLE dim_model (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(50) UNIQUE,
    segment VARCHAR(20),
    avg_price_eur NUMERIC
);

/* Create Fact Table */
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

/* Populate Dimension Tables */

/* Dim Date */
INSERT INTO dim_date (year, month)
SELECT DISTINCT 
    year, 
    month::INT   -- cast month from VARCHAR to INT
FROM bmw_global_sales;

/* Dim Region */
INSERT INTO dim_region (region_name)
SELECT DISTINCT region
FROM bmw_global_sales;

/* Dim Model */
INSERT INTO dim_model (model_name, avg_price_eur)
SELECT DISTINCT model, AVG(avg_price_eur)
FROM bmw_global_sales
GROUP BY model;

/* segment*/
UPDATE dim_model
SET segment = 'SUV'
WHERE model_name IN ('X5', 'X6', 'X7');

UPDATE dim_model
SET segment = 'Sedan'
WHERE model_name IN ('3 Series', '5 Series', '7 Series');

UPDATE dim_model
SET segment = 'EV'
WHERE model_name IN ('i3', 'iX', 'i4');

/*  Populate Fact Table */
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
JOIN dim_date d 
    ON b.year::INT = d.year       -- cast year to INT
    AND b.month::INT = d.month    -- cast month to INT
JOIN dim_region r 
    ON b.region = r.region_name
JOIN dim_model m 
    ON b.model = m.model_name;
