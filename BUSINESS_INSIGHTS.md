# 📊 BlitzMart Analytics — Business Insights

> End-to-end analysis of a fictional German e-commerce retailer modeled after Zalando, Otto, and Amazon DE.
> **6.6M rows analyzed across 8 relational tables** using SQL (DuckDB) + Python (pandas).

---

## 🎯 Executive Summary

BlitzMart processed **€2.16 billion in revenue across 1.39M delivered orders** from 200K active customers between 2022 and 2024 — at an average order value of **€1,548**. The analysis surfaces three structural opportunities worth acting on: a **31.7-point carrier performance gap**, a **Leipzig warehouse underperformance crisis**, and a **Fashion-driven returns problem** that accounts for outsized refund costs.

---

## 📌 Top 8 Findings

### 1. 💰 Business runs at €2.16B scale — concentrated in November/December
The full 3-year period generated **€2.16B** across **1.39M orders**. Peak months (Nov–Dec) deliver **€126.6M vs €42.3M off-season** — a **3.0× holiday surge**. This Q4 spike is the make-or-break quarter for the year.

> **Why it matters:** Inventory planning, hiring, and logistics capacity must scale 3× for 2 months. Any operational weakness compounds during peak.

---

### 2. 📊 36% of SKUs drive 80% of revenue — classic ABC distribution
**1,805 of 5,000 products (A-class)** generate **80%** of revenue. The remaining 64% of catalog SKUs share just 20%.

> **Why it matters:** A-class products need tight stock control, premium carrier service, and zero stockouts. C-class can run on lean inventory. Treating all SKUs equally wastes working capital.

---

### 3. 🎯 Top 20% of customers generate 38% of revenue
**39,959 customers** (top 20%) drive **37.9%** of total revenue. The "Champions" RFM segment alone represents 15% of customers but disproportionately higher lifetime value.

> **Why it matters:** Retention spend should be heavily skewed toward this segment. A 5% churn reduction here is worth more than 20% acquisition growth in lower tiers.

---

### 4. 🚚 31.7-point OTIF gap between best and worst carrier
**DHL delivers 76.5% on-time** vs **GLS at 44.8%** — a **31.7 percentage point gap** across 1.4M shipments. UPS (70%), DPD (67%), and Hermes (54%) sit between.

> **Why it matters:** Every GLS shipment is essentially a coin flip. Consolidating volume away from GLS toward DHL would improve customer NPS without changing prices. Estimated impact: **~80,000 fewer late deliveries per year**.

---

### 5. 🏭 Leipzig Distribution is the operational outlier
**Leipzig Hub: 45.4% OTIF, 3.64 days avg delivery** vs **Berlin Hub: 72.8% OTIF, 3.2 days** — a **27.4-point gap**. Other warehouses cluster within 2 points of Berlin.

> **Why it matters:** Leipzig is dragging down the East region's customer experience. Either invest in its capacity or reroute East German orders through Berlin Hub. This is a clear, isolatable problem with a clear owner.

---

### 6. 📦 Fashion returns 2.3× more than Books — and "Wrong size" is the root cause
**Fashion return rate: 15.6%** (highest) vs **Books: 6.7%** (lowest). Across all categories, **"Wrong size" accounts for 23% of every return** — making it the #1 driver of reverse logistics cost.

> **Why it matters:** A virtual try-on tool or better size charts would specifically attack the biggest cost lever. Even a 20% reduction in size-driven returns saves an estimated **~12,700 returns per year** in Fashion alone.

---

### 7. 🎯 Demand forecasting is healthy — 91-94% accuracy across all categories
Forecast accuracy ranges from **91.4% (Home & Kitchen)** to **94.1% (Toys)**. No category falls below 90%.

> **Why it matters:** Demand planning is not the bottleneck. The supply-side execution (carriers, Leipzig warehouse) is where to focus. Don't waste cycles improving forecasts when fulfillment is the real problem.

---

### 8. 🌍 Berlin + Hamburg + München = 47% of revenue
**Berlin alone drives 22% of revenue.** The top 3 cities concentrate nearly half of all sales. The bottom 6 cities combined contribute under 20%.

> **Why it matters:** Marketing budget allocation, regional pricing, and warehouse capacity should reflect this skew. Premium delivery options (same-day) are most viable in the top 3 cities.

---

## 🛠 Recommended Actions

| # | Action | Driver | Expected Impact |
|---|---|---|---|
| **1** | Consolidate GLS volume → DHL | OTIF gap | ~80K fewer late deliveries/year |
| **2** | Audit & invest in Leipzig Hub OR reroute East orders | Warehouse outlier | +20pp OTIF in East region |
| **3** | Launch sizing guide / virtual try-on for Fashion | "Wrong size" 23% | Save ~12K Fashion returns/year |
| **4** | Build VIP retention program for top 20% customers | Customer concentration | Protect 38% of revenue |
| **5** | Pre-stock A-class SKUs by Oct 15 every year | Nov/Dec 3x spike | Reduce stockouts in peak |

---

## 🔬 Methodology

- **Data scale:** 6.6M records across 8 relational tables (customers, orders, order_items, products, suppliers, warehouses, shipments, returns)
- **ETL pipeline:** Python pandas — generated, injected 29K realistic data quality issues, then cleaned via imputation, deduplication, outlier capping, and referential repair
- **SQL analysis:** 15 queries in DuckDB, including window functions (LAG, NTILE, ROW_NUMBER), CTEs, and cohort retention
- **Python analysis:** ABC analysis (products + customers), OTIF carrier scorecard, demand seasonality, forecast accuracy, return root cause, geographic concentration
- **Tools:** Python, pandas, NumPy, DuckDB, matplotlib, seaborn, Tableau (dashboard layer)

---

*Analysis by Pavan raj Kotagiri — Built using publicly inspired e-commerce KPIs benchmarked against Zalando, Otto, and DHL operational data.*
