# Retail Intelligence Analytics Engineering Platform

A production-ready **dbt + Snowflake** analytics engineering platform designed to convert multi-source transactional data into clean, documented, and fully tested analytical datasets. 

This project implements a **Medallion Architecture** (Raw → Staging → Intermediate → Marts) and a **Kimball Star Schema** to power self-service BI and downstream executive reporting.

---

## 🏗️ Architecture & Data Lineage

The transformation pipeline follows modern data architecture principles to ensure data reliability and operational efficiency.

* **Medallion Architecture Flow:** See [`docs/architecture.md`](docs/architecture.md)
* **Kimball Star Schema:** See [`docs/star_schema.md`](docs/star_schema.md)
* **Layered Data Transformation:** See [`docs/data_flow.md`](docs/data_flow.md)

---

## 🎯 Business Context

* **Problem:** High-growth retail platforms generate raw, fragmented transaction logs across orders, customers, products, and payments. Raw queries are slow, metrics drift across teams, and historical changes (like customer location shifts) are lost.
* **Analytics Engineering Solution:** A modular data pipeline built with dbt and Snowflake that enforces software engineering best practices—automated testing, version control, clear modeling layers, and dynamic environment builds.

---

## 🛠️ Tech Stack

| Technology | Layer / Domain | Function in Pipeline |
| :--- | :--- | :--- |
| **dbt Core** | Transformation | Data modeling, lineage tracking, testing, and documentation |
| **Snowflake** | Cloud Data Warehouse | Scalable MPP compute and storage platform |
| **SQL** | Core Transformation Language | Declarative business logic and dimensional modeling |
| **Jinja** | Analytics Engineering | Dynamic SQL generation, environment branching, and macros |
| **GitHub Actions** | CI/CD | Automated pull-request testing and linting |

---

## 🚀 Key Features

* **Kimball Dimensional Modeling:** Standardized data mart consisting of core facts (`fact_orders`) surrounded by descriptive dimensions (`dim_customers`, `dim_products`, `dim_dates`).
* **SCD Type 2 Historical Tracking:** Implemented via dbt snapshots to track change history on customer records over time.
* **35+ Data Quality Assertions:** 100% critical test coverage using native dbt tests (`unique`, `not_null`, `relationships`) and custom singular SQL tests.
* **Advanced Business Metrics:** Pre-baked logic for RFM customer segmentation, product revenue performance tiers, and pricing bands.
* **Performance Optimization:** Pre-aggregated analytics views (`fact_daily_revenue`) built to reduce BI query latency and Snowflake compute cost.
* **Automated CI/CD:** Continuous Integration via GitHub Actions to run tests against target pull-request schemas before production deployment.

---

## 📂 Project Structure

```text
DBT_Ecommerce_Warehouse/
├── scripts/
│   ├── staging/          # Clean, rename, cast types, & light filtering (4 views)
│   ├── intermediate/     # Business logic, CTE abstractions, & joins (2 ephemeral models)
│   └── marts/            # Final Star Schema ready for BI consumers (5 tables)
├── datasets/                # Raw CSV source datasets for local reproducibility (4 files)
├── snapshots/            # Slowly Changing Dimensions Type 2 logic (1 snapshot)
├── tests/                # Custom singular data quality assertions (2 tests)
├── macros/               # Reusable SQL functions and utilities (3 macros)
├── analyses/             # Analytical query playground (6 scripts)
├── docs/                 # Pipeline visualizers and architecture guides
└── .github/workflows/    # CI/CD pipelines for pull-request testing
