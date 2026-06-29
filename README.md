# Sales Analysis 2019 — End-to-End Data Pipeline

> A full-stack data analysis project spanning raw CSV ingestion, Python-based data cleaning, SQL-driven exploratory analysis, and an interactive Power BI dashboard — built to surface actionable business insights from 2019 retail sales data.

---

## Project Structure

```
Sales-Analysis-2019/
│
├── data.csv                     # Raw 2019 sales dataset
├── Data Cleaning.ipynb          # Python notebook — data wrangling & preprocessing
├── SQL analysis.sql             # T-SQL — 40+ EDA queries across 5 analysis domains
├── Power BI Dashboard Demo.mp4  # Recorded walkthrough of the interactive dashboard
└── README.md
```

---

## Pipeline Overview

```
Raw CSV  ──►  Python Cleaning  ──►  SQL (T-SQL) Analysis  ──►  Power BI Dashboard
(data.csv)    (Pandas / Jupyter)    (MS SQL Server)              (Interactive Report)
```

Each stage feeds the next — the cleaned CSV is loaded into SQL Server, analyzed with structured queries, and the results are visualized in Power BI.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data Storage | CSV → Microsoft SQL Server |
| Data Cleaning | Python · Pandas · Jupyter Notebook |
| Exploratory Analysis | T-SQL · MS SQL Server |
| Visualization | Power BI |

---

## Stage 1 — Data Cleaning (`Data Cleaning.ipynb`)

Raw data arrived with structural inconsistencies that required preprocessing before any analysis could begin.

**Key operations performed:**
- Removed duplicate and null records
- Parsed and standardized `OrderDate` from mixed string formats to proper date types
- Extracted `City` from the combined address column
- Computed a derived `Sales` column (`QuantityOrdered × PriceEach`)
- Validated data types across all columns
- Exported a clean, analysis-ready CSV

---

## Stage 2 — SQL Analysis (`SQL analysis.sql`)

A 672-line T-SQL script covering **40+ structured queries** across five analytical domains. The script also handles table creation and bulk data ingestion from CSV into SQL Server.

### Time-Based Analysis
- Monthly and quarterly revenue totals and trends
- Month-over-month (MoM) and week-over-week (WoW) revenue growth rates using `LAG()` window functions
- Best-performing day of week and identification of seasonally low months
- Cumulative revenue running total via `SUM() OVER()`

### Product Analysis
- Top and bottom 5 products by revenue using `RANK()` window function
- Revenue share percentage per product
- High-volume / low-revenue product identification
- Most consistent sellers by standard deviation of monthly revenue
- Q4 vs. Q1 revenue comparison per product
- Premium vs. bulk item classification using pricing pattern logic

### City / Location Analysis
- Top cities by total revenue, order count, and average order value
- Revenue-per-order efficiency ranking across cities
- Top 3 products per city using `RANK() OVER(PARTITION BY City)`
- City dominance share per product using window aggregation
- Most product-diverse city by unique product count

### Revenue & Sales Analysis
- Grand total revenue and unique order count
- Orders segmented above and below $500 threshold
- Sales spread via standard deviation and variance
- Per-product peak vs. lowest month revenue swing

### Advanced / Combo Analysis
- Best city × product revenue combination
- Revenue quartile distribution using `NTILE(4)`
- Cohort analysis tracking revenue by first-order month
- City revenue rank shifts across months via `RANK() OVER(PARTITION BY MonthNum)`
- Biggest MoM revenue drop per product using `LAG()` with `PARTITION BY Product`
- Average basket size (distinct products per order)

---

## Stage 3 — Power BI Dashboard

An interactive report built on the cleaned and analyzed data, featuring:

- **Revenue trend line** across all 12 months of 2019
- **City performance map** and revenue bar comparisons
- **Product revenue breakdown** with ranking visuals
- **KPI cards** for total revenue, total orders, and average order value

- **Slicers** for dynamic filtering by city, product, and month

> See the Demo.

https://github.com/user-attachments/assets/aca07698-1865-463b-bd67-d6d0015ec0e3


---

## Key Business Insights

- **December** drove peak revenue — holiday demand was the single strongest seasonal signal.
- **San Francisco** consistently ranked as the highest-revenue city across nearly every month.
- **MacBook Pro Laptop** and **iPhone** were top revenue contributors despite lower order volumes, confirming a premium-item sales pattern.
- **AAA/AA Batteries** had the highest order quantities but contributed marginally to total revenue — a classic high-volume / low-margin profile.
- **Q4** showed significant revenue uplift over Q1 for most products, indicating strong seasonal concentration of demand.

---


## About

This project was built as a demonstration of an analyst's full workflow — from messy raw data through to a decision-ready dashboard — using industry-standard tools across every layer of the pipeline.

**Skills demonstrated:** Data wrangling · SQL window functions · Cohort analysis · Time-series aggregation · Business intelligence reporting

---

*Eman Fatima · [GitHub](https://github.com/EmanFatima05)*
