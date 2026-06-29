-- Use DataBase 
USE salesAnalysis;
GO

-- Create Table 
CREATE TABLE Sales2019 (
    OrderID          INT,
    Product          VARCHAR(255),
    QuantityOrdered  INT,    
    PriceEach        DECIMAL(10,2),    
    OrderDate        VARCHAR(255),
    City             VARCHAR(255),
    Sales            DECIMAL(10,2)
);

-- Insert the Data in the Table 
BULK INSERT Sales2019
FROM "C:\SalesAnalysis\data.csv"
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    TABLOCK
);

select * from Sales2019

-- Change the Dtype of Column OrderDate 
ALTER TABLE Sales2019
ADD Order_Date_Converted DATE NULL;

UPDATE Sales2019
SET Order_Date_Converted = TRY_CONVERT(DATE, [OrderDate], 103)
WHERE [OrderDate] IS NOT NULL
  AND LTRIM(RTRIM([OrderDate])) != '';

SELECT *
FROM Sales2019
WHERE Order_Date_Converted IS NULL
  AND [OrderDate] IS NOT NULL
  AND LTRIM(RTRIM([OrderDate])) != '';

ALTER TABLE Sales2019
DROP COLUMN [OrderDate];

EXEC sp_rename 'Sales2019.Order_Date_Converted', 'OrderDate', 'COLUMN';

select * from Sales2019

-- ======= Exploaratory Data Analysis ========

-- ===============================
--  TIME-BASED ANALYSIS 
-- ===============================

--  Monthly revenue totals
SELECT
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    ROUND(SUM(Sales), 2)                    AS TotalRevenue
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY MonthNum;


-- Month with most orders
SELECT TOP 1
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    COUNT(*)                                AS TotalOrders
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY TotalOrders DESC;


-- Month with highest revenue
SELECT TOP 1
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    ROUND(SUM(Sales), 2)                    AS TotalRevenue
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY TotalRevenue DESC;


-- Average order value per month
SELECT
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    ROUND(AVG(Sales), 2)                    AS AvgOrderValue
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY MonthNum;


-- Best sales day-of-week
SELECT
    DATEPART(WEEKDAY, OrderDate)            AS DayNum,
    DATENAME(WEEKDAY, OrderDate)            AS DayName,
    ROUND(SUM(Sales), 2)                    AS TotalSales,
    COUNT(*)                                AS TotalOrders
FROM Sales2019
GROUP BY DATEPART(WEEKDAY, OrderDate), DATENAME(WEEKDAY, OrderDate)
ORDER BY TotalSales DESC;


-- Quarterly revenue seasonal trend
SELECT
    DATEPART(QUARTER, OrderDate)            AS Quarter,
    ROUND(SUM(Sales), 2)                    AS TotalRevenue,
    COUNT(*)                                AS TotalOrders
FROM Sales2019
GROUP BY DATEPART(QUARTER, OrderDate)
ORDER BY Quarter;


-- Week-over-week revenue growth
WITH WeeklySales AS (
    SELECT
        DATEPART(ISO_WEEK, OrderDate)       AS WeekNum,
        ROUND(SUM(Sales), 2)                AS WeekRevenue
    FROM Sales2019
    GROUP BY DATEPART(ISO_WEEK, OrderDate)
)
-- Lag compares each week to prior week
SELECT
    WeekNum,
    WeekRevenue,
    COALESCE(LAG(WeekRevenue) OVER (ORDER BY WeekNum),0) AS PrevWeekRevenue,
    COALESCE(ROUND(
        (WeekRevenue - LAG(WeekRevenue) OVER (ORDER BY WeekNum))
        / NULLIF(LAG(WeekRevenue) OVER (ORDER BY WeekNum), 0) * 100
    , 2),0)                                  AS WoW_GrowthPct
FROM WeeklySales
ORDER BY WeekNum;


-- Month with highest avg quantity
SELECT TOP 1
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    ROUND(AVG(CAST(QuantityOrdered AS FLOAT)), 2) AS AvgQty
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY AvgQty DESC;


-- Months with unusually low order counts
WITH MonthlyCounts AS (
    SELECT
        MONTH(OrderDate)                    AS MonthNum,
        DATENAME(MONTH, OrderDate)          AS MonthName,
        COUNT(*)                            AS TotalOrders
    FROM Sales2019
    GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
)
-- Orders below average flagged as low
SELECT
    MonthNum,
    MonthName,
    TotalOrders,
    ROUND(AVG(TotalOrders) OVER (), 0)      AS OverallAvgOrders,
    CASE
        WHEN TotalOrders < AVG(TotalOrders) OVER () THEN 'Low'
        ELSE 'Normal'
    END                                     AS Flag
FROM MonthlyCounts
ORDER BY MonthNum;


-- Month-over-month revenue growth rate
WITH MonthlyRev AS (
    SELECT
        MONTH(OrderDate)                    AS MonthNum,
        DATENAME(MONTH, OrderDate)          AS MonthName,
        ROUND(SUM(Sales), 2)                AS Revenue
    FROM Sales2019
    GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
)
-- Lag computes prior month revenue
SELECT
    MonthNum,
    MonthName,
    Revenue,
    COALESCE(LAG(Revenue) OVER (ORDER BY MonthNum) ,0)  AS PrevMonthRevenue,
    COALESCE(ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY MonthNum))
        / NULLIF(LAG(Revenue) OVER (ORDER BY MonthNum), 0) * 100
    , 2),0)                                    AS MoM_GrowthPct
FROM MonthlyRev
ORDER BY MonthNum;


-- ============================
--  PRODUCT ANALYSIS  
-- ============================

-- Product with highest total revenue
SELECT TOP 1
    Product,
    ROUND(SUM(Sales), 2)    AS TotalRevenue
FROM Sales2019
GROUP BY Product
ORDER BY TotalRevenue DESC;


-- Most ordered product by quantity
SELECT TOP 1
    Product,
    SUM(QuantityOrdered)     AS TotalQty
FROM Sales2019
GROUP BY Product
ORDER BY TotalQty DESC;


-- Highest average price product
SELECT TOP 1
    Product,
    ROUND(AVG(PriceEach), 2)    AS AvgPrice
FROM Sales2019
GROUP BY Product
ORDER BY AvgPrice DESC;


-- High volume but low revenue products
SELECT
    Product,
    SUM(QuantityOrdered)   AS TotalQty,
    ROUND(SUM(Sales), 2)   AS TotalRevenue,
    ROUND(SUM(Sales) / NULLIF(SUM(QuantityOrdered), 0), 2) AS RevenuePerUnit
FROM Sales2019
GROUP BY Product
-- Low revenue despite high quantity
ORDER BY TotalQty DESC, TotalRevenue ASC;


-- Top 5 and bottom 5 by revenue
SELECT Product, TotalRevenue, Rank
FROM (
    SELECT
        Product,
        ROUND(SUM(Sales), 2)                AS TotalRevenue,
        RANK() OVER (ORDER BY SUM(Sales) DESC) AS Rank
    FROM Sales2019
    GROUP BY Product
) ranked
WHERE Rank <= 5

UNION ALL

SELECT Product, TotalRevenue, Rank
FROM (
    SELECT
        Product,
        ROUND(SUM(Sales), 2)                AS TotalRevenue,
        RANK() OVER (ORDER BY SUM(Sales) ASC) AS Rank
    FROM Sales2019
    GROUP BY Product
) ranked
WHERE Rank <= 5
ORDER BY TotalRevenue DESC;


-- Each product's revenue share %
SELECT
    Product,
    ROUND(SUM(Sales), 2)                    AS TotalRevenue,
    ROUND(SUM(Sales) / SUM(SUM(Sales)) OVER () * 100, 2) AS RevenuePct
FROM Sales2019
GROUP BY Product
ORDER BY RevenuePct DESC;


-- Most consistent monthly sales (lowest stddev)
SELECT
    Product,
    ROUND(AVG(MonthlyRevenue), 2)           AS AvgMonthlyRevenue,
    -- Lower stdev = more consistent sales
    ROUND(STDEV(MonthlyRevenue), 2)         AS StdDevRevenue
FROM (
    SELECT
        Product,
        MONTH(OrderDate)                    AS MonthNum,
        SUM(Sales)                          AS MonthlyRevenue
    FROM Sales2019
    GROUP BY Product, MONTH(OrderDate)
) monthly
GROUP BY Product
ORDER BY StdDevRevenue ASC;


-- Product revenue Q4 vs Q1 comparison
SELECT
    Product,
    ROUND(SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 1 THEN Sales ELSE 0 END), 2) AS Q1_Revenue,
    ROUND(SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 4 THEN Sales ELSE 0 END), 2) AS Q4_Revenue,
    -- Difference shows seasonal shift
    ROUND(
        SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 4 THEN Sales ELSE 0 END) -
        SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 1 THEN Sales ELSE 0 END)
    , 2)                                    AS Q4_vs_Q1_Diff
FROM Sales2019
GROUP BY Product
ORDER BY Q4_vs_Q1_Diff DESC;


-- Highest average order quantity per transaction
SELECT TOP 1
    Product,
    ROUND(AVG(CAST(QuantityOrdered AS FLOAT)), 2) AS AvgQtyPerOrder
FROM Sales2019
GROUP BY Product
ORDER BY AvgQtyPerOrder DESC;


-- ===========================
--  CITY / LOCATION ANALYSIS  
-- ===========================

-- City with highest total revenue
SELECT TOP 1
    City,
    ROUND(SUM(Sales), 2)  AS TotalRevenue
FROM Sales2019
GROUP BY City
ORDER BY TotalRevenue DESC;


--  City placing most orders
SELECT TOP 1
    City,
    COUNT(*)   AS TotalOrders
FROM Sales2019
GROUP BY City
ORDER BY TotalOrders DESC;


-- Average order value per city
SELECT
    City,
    ROUND(AVG(Sales), 2)   AS AvgOrderValue
FROM Sales2019
GROUP BY City
ORDER BY AvgOrderValue DESC;


-- Highest revenue-per-order city
SELECT TOP 1
    City,
    ROUND(SUM(Sales) / COUNT(*), 2)  AS RevenuePerOrder
FROM Sales2019
GROUP BY City
ORDER BY RevenuePerOrder DESC;


-- Top 3 products per city
WITH CityProductRank AS (
    SELECT
        City,
        Product,
        ROUND(SUM(Sales), 2)    AS TotalRevenue,
        -- Rank products within each city
        RANK() OVER (PARTITION BY City ORDER BY SUM(Sales) DESC) AS RankInCity
    FROM Sales2019
    GROUP BY City, Product
)
SELECT City, Product, TotalRevenue, RankInCity
FROM CityProductRank
WHERE RankInCity <= 3
ORDER BY City, RankInCity;


-- City with most diverse product mix
SELECT TOP 1
    City,
    COUNT(DISTINCT Product)   AS UniqueProducts
FROM Sales2019
GROUP BY City
ORDER BY UniqueProducts DESC;


-- City ordering a product disproportionately
WITH ProductCityShare AS (
    SELECT
        City,
        Product,
        SUM(QuantityOrdered)  AS CityQty,
        SUM(SUM(QuantityOrdered)) OVER (PARTITION BY Product) AS TotalProductQty
    FROM Sales2019
    GROUP BY City, Product
)
-- Share shows city dominance per product
SELECT
    City,
    Product,
    CityQty,
    TotalProductQty,
    ROUND(CAST(CityQty AS FLOAT) / NULLIF(TotalProductQty, 0) * 100, 2) AS CitySharePct
FROM ProductCityShare
ORDER BY CitySharePct DESC;


-- Each city's revenue share %
SELECT
    City,
    ROUND(SUM(Sales), 2)  AS TotalRevenue,
    ROUND(SUM(Sales) / SUM(SUM(Sales)) OVER () * 100, 2) AS RevSharePct
FROM Sales2019
GROUP BY City
ORDER BY RevSharePct DESC;


-- City with highest avg quantity per order
SELECT TOP 1
    City,
    ROUND(AVG(CAST(QuantityOrdered AS FLOAT)), 2) AS AvgQtyPerOrder
FROM Sales2019
GROUP BY City
ORDER BY AvgQtyPerOrder DESC;



-- ===========================
--  REVENUE & SALES ANALYSIS  
-- ===========================

-- Total dataset revenue
SELECT
    ROUND(SUM(Sales), 2)       AS GrandTotalRevenue,
    COUNT(*)                   AS TotalRows,
    COUNT(DISTINCT OrderID)    AS UniqueOrders
FROM Sales2019;


-- Average revenue per city per month
SELECT
    City,
    MONTH(OrderDate)               AS MonthNum,
    DATENAME(MONTH, OrderDate)     AS MonthName,
    ROUND(AVG(Sales), 2)           AS AvgRevenue
FROM Sales2019
GROUP BY City, MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY City, MonthNum;


-- Best city + product revenue combo
SELECT TOP 1
    City,
    Product,
    ROUND(SUM(Sales), 2)    AS TotalRevenue
FROM Sales2019
GROUP BY City, Product
ORDER BY TotalRevenue DESC;


-- Monthly revenue trend across 2019
SELECT
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    ROUND(SUM(Sales), 2)                    AS Revenue,
    -- Running total shows overall growth
    ROUND(SUM(SUM(Sales)) OVER (ORDER BY MONTH(OrderDate)), 2) AS CumulativeRevenue
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY MonthNum;


-- Orders above vs below $500
SELECT
    SUM(CASE WHEN Sales > 500  THEN 1 ELSE 0 END) AS OrdersAbove500,
    SUM(CASE WHEN Sales <= 500 THEN 1 ELSE 0 END) AS OrdersBelow500,
    -- Pct split shows order tier distribution
    ROUND(SUM(CASE WHEN Sales > 500  THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2) AS PctAbove500
FROM Sales2019;


-- Sales spread via standard deviation
SELECT
    ROUND(AVG(Sales), 2)      AS AvgSales,
    ROUND(STDEV(Sales), 2)    AS StdDevSales,
    -- High stdev = wide order value spread
    ROUND(VAR(Sales), 2)      AS VarianceSales
FROM Sales2019;


-- Product peak vs lowest month revenue
WITH MonthlyProductRev AS (
    SELECT
        Product,
        MONTH(OrderDate)                    AS MonthNum,
        ROUND(SUM(Sales), 2)                AS Revenue
    FROM Sales2019
    GROUP BY Product, MONTH(OrderDate)
)
-- Max vs min month per product
SELECT
    Product,
    MAX(Revenue)                            AS PeakMonthRevenue,
    MIN(Revenue)                            AS LowestMonthRevenue,
    MAX(Revenue) - MIN(Revenue)             AS RevenueSwing
FROM MonthlyProductRev
GROUP BY Product
ORDER BY RevenueSwing DESC;


-- ============================
--  ADVANCED / COMBO QUESTIONS 
-- ============================

-- Best month + city revenue combo
SELECT TOP 1
    DATENAME(MONTH, OrderDate)     AS MonthName,
    City,
    ROUND(SUM(Sales), 2)       AS TotalRevenue
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate), City
ORDER BY TotalRevenue DESC;


-- Expensive products by city sales
SELECT
    City,
    Product,
    ROUND(SUM(Sales), 2)                    AS TotalRevenue,
    SUM(QuantityOrdered)                    AS TotalQty
FROM Sales2019
-- Only premium products (> $500)
WHERE PriceEach > 500
GROUP BY City, Product
ORDER BY TotalRevenue DESC;


-- Qty vs price bulk-buy correlation
SELECT
    Product,
    ROUND(AVG(PriceEach), 2)                AS AvgPrice,
    ROUND(AVG(CAST(QuantityOrdered AS FLOAT)), 2) AS AvgQty,
    -- Low price + high qty = bulk pattern
    CASE
        WHEN AVG(PriceEach) < 20
         AND AVG(CAST(QuantityOrdered AS FLOAT)) > 1.5 THEN 'Bulk Item'
        WHEN AVG(PriceEach) >= 200           THEN 'Premium Item'
        ELSE 'Standard'
    END                   AS PricingPattern
FROM Sales2019
GROUP BY Product
ORDER BY AvgPrice;


-- Cumulative revenue running total
SELECT
    MONTH(OrderDate)                        AS MonthNum,
    DATENAME(MONTH, OrderDate)              AS MonthName,
    ROUND(SUM(Sales), 2)                    AS MonthlyRevenue,
    -- Window sum grows month by month
    ROUND(SUM(SUM(Sales)) OVER (ORDER BY MONTH(OrderDate)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS CumulativeRevenue
FROM Sales2019
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY MonthNum;


-- City revenue rank per month (window)
WITH CityMonthRev AS (
    SELECT
        MONTH(OrderDate)                    AS MonthNum,
        DATENAME(MONTH, OrderDate)          AS MonthName,
        City,
        ROUND(SUM(Sales), 2)                AS Revenue
    FROM Sales2019
    GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate), City
)
-- Rank shifts reveal unstable city performance
SELECT
    MonthNum,
    MonthName,
    City,
    Revenue,
    RANK() OVER (PARTITION BY MonthNum ORDER BY Revenue DESC) AS CityRank
FROM CityMonthRev
ORDER BY MonthNum, CityRank;


-- Biggest product revenue MoM drop
WITH MonthlyRev AS (
    SELECT
        Product,
        MONTH(OrderDate)                    AS MonthNum,
        SUM(Sales)                          AS Revenue
    FROM Sales2019
    GROUP BY Product, MONTH(OrderDate)
),
WithLag AS (
    SELECT
        Product,
        MonthNum,
        Revenue,
        LAG(Revenue) OVER (PARTITION BY Product ORDER BY MonthNum) AS PrevRevenue,
        -- Negative diff = revenue dropped
        Revenue - LAG(Revenue) OVER (PARTITION BY Product ORDER BY MonthNum) AS MoM_Change
    FROM MonthlyRev
)
SELECT TOP 1
    Product, MonthNum, Revenue, PrevRevenue, MoM_Change
FROM WithLag
WHERE MoM_Change IS NOT NULL
ORDER BY MoM_Change ASC;


-- Average basket size per order
WITH OrderProducts AS (
    SELECT
        OrderID,
        COUNT(DISTINCT Product)             AS UniqueProducts
    FROM Sales2019
    GROUP BY OrderID
)
-- Avg distinct products per order
SELECT
    ROUND(AVG(CAST(UniqueProducts AS FLOAT)), 2) AS AvgBasketSize,
    MAX(UniqueProducts)                     AS MaxBasketSize,
    MIN(UniqueProducts)                     AS MinBasketSize
FROM OrderProducts;


-- Revenue quartile distribution (NTILE)
WITH Quartiles AS (
    SELECT
        OrderID,
        Sales,
        -- Divides orders into 4 revenue buckets
        NTILE(4) OVER (ORDER BY Sales)      AS RevenueQuartile
    FROM Sales2019
)
SELECT
    RevenueQuartile,
    COUNT(*)                                AS OrderCount,
    ROUND(MIN(Sales), 2)                    AS MinSales,
    ROUND(MAX(Sales), 2)                    AS MaxSales,
    ROUND(AVG(Sales), 2)                    AS AvgSales,
    ROUND(SUM(Sales), 2)                    AS TotalRevenue
FROM Quartiles
GROUP BY RevenueQuartile
ORDER BY RevenueQuartile;


-- Cohort revenue by first-order month
WITH FirstOrder AS (
    SELECT
        OrderID,
        -- Assign cohort = first month seen
        MIN(MONTH(OrderDate))               AS CohortMonth
    FROM Sales2019
    GROUP BY OrderID
),
CohortData AS (
    SELECT
        f.CohortMonth,
        MONTH(s.OrderDate)                  AS OrderMonth,
        ROUND(SUM(s.Sales), 2)              AS Revenue
    FROM Sales2019 s
    JOIN FirstOrder f ON s.OrderID = f.OrderID
    GROUP BY f.CohortMonth, MONTH(s.OrderDate)
)
-- Revenue per cohort tracked over months
SELECT
    CohortMonth,
    OrderMonth,
    OrderMonth - CohortMonth               AS MonthsAfterFirst,
    Revenue
FROM CohortData
ORDER BY CohortMonth, OrderMonth;