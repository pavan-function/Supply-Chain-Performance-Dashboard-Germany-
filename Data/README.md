# 📂 Data Dictionary — BlitzMart Analytics

The raw CSV files (~250 MB total) are **not committed to this repo** due to GitHub file size limits. The notebook `notebooks/BlitzMart_01_DataGeneration.ipynb` regenerates the entire dataset from scratch in ~5 minutes.

---

## Schema Overview

8 relational tables, ~6.6M rows total.

```
customers ──< orders ──< order_items >── products >── suppliers
                │
                ├──< shipments
                ├──< returns
                └──> warehouses
```

---

## Tables

### `customers` — 200,000 rows
| Column | Type | Description |
|---|---|---|
| customer_id | int | Primary key |
| first_name, last_name | string | Customer name |
| city | string | German city (population-weighted) |
| region | string | North / South / East / West |
| age | int | Customer age |
| gender | string | M / F / D / Unknown |
| signup_date | date | Account creation date |
| customer_segment | string | Standard / Premium / VIP |

### `orders` — 1,500,000 rows
| Column | Type | Description |
|---|---|---|
| order_id | int | Primary key |
| customer_id | int | FK → customers |
| order_date | date | Order placement date |
| warehouse_id | int | FK → warehouses |
| order_status | string | Delivered / Shipped / Cancelled / Processing / Returned |
| payment_method | string | Credit Card / PayPal / Klarna / SEPA / Apple Pay / Google Pay |

### `order_items` — ~3.4M rows
| Column | Type | Description |
|---|---|---|
| order_item_id | int | Primary key |
| order_id | int | FK → orders |
| product_id | int | FK → products |
| quantity | int | Units ordered |
| unit_price | decimal | Price per unit at time of sale |
| discount | decimal | Discount applied (0.0–0.20) |
| line_total | decimal | quantity × unit_price × (1 − discount) |

### `products` — 5,000 rows
| Column | Type | Description |
|---|---|---|
| product_id | int | Primary key |
| product_name | string | Product name |
| category | string | 8 categories (Electronics, Fashion, etc.) |
| supplier_id | int | FK → suppliers |
| unit_cost | decimal | Cost to BlitzMart |
| unit_price | decimal | Catalog selling price |
| weight_kg | decimal | Product weight |

### `suppliers` — 50 rows
| Column | Type | Description |
|---|---|---|
| supplier_id | int | Primary key |
| supplier_name | string | Supplier company name |
| country | string | Supplier country |
| rating | decimal | Supplier rating (3.0–5.0) |
| lead_time_days | int | Average lead time |

### `warehouses` — 6 rows
| Column | Type | Description |
|---|---|---|
| warehouse_id | int | Primary key |
| warehouse_name | string | Warehouse name |
| city | string | Warehouse location |
| region | string | North / South / East / West |
| capacity_units | int | Storage capacity |

### `shipments` — ~1.4M rows
| Column | Type | Description |
|---|---|---|
| shipment_id | int | Primary key |
| order_id | int | FK → orders |
| carrier | string | DHL / Hermes / DPD / UPS / GLS |
| ship_date | date | Date shipped |
| promised_delivery_days | int | Promised delivery window |
| actual_delivery_days | int | Actual delivery time |
| delivery_date | date | Date delivered |
| on_time_delivery | int | 1 = on-time, 0 = late |

### `returns` — ~150K rows
| Column | Type | Description |
|---|---|---|
| return_id | int | Primary key |
| order_id | int | FK → orders |
| return_date | date | Date of return |
| return_reason | string | Wrong size / Damaged / Not as described / etc. |
| refund_amount | decimal | Refund value in EUR |

---

## Data Quality Notes

The dataset intentionally includes realistic data quality issues that are detected and cleaned in the ETL pipeline:
- ~2% missing customer ages and genders
- ~0.1% duplicate order records
- ~0.5% invalid quantities/prices
- ~0.3% impossible delivery dates
- ~50 extreme refund outliers
- ~1% missing supplier references

After cleaning: `data_clean/` contains the analysis-ready tables. A cleaning audit report (`_cleaning_report.csv`) documents every fix.
