# 🛒 VenteRapide Enterprise Data Warehouse (Livrable E6)

[![dbt Version](https://img.shields.io/badge/dbt-1.12.3-orange.svg)](https://docs.getdbt.com/)
[![PostgreSQL Version](https://img.shields.io/badge/PostgreSQL-18-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

> **Project Scope:** Implementation of a modern, enterprise-grade Data Warehouse for e-commerce analytics, featuring Kimball dimensional modeling, Type 1 & Type 2 Slowly Changing Dimensions (SCD), Role-Based Access Control (RBAC), GDPR (RGPD) compliance, automated data quality testing, and full lineage documentation.

---

## 📋 Table of Contents

1. [Executive Summary](#-executive-summary)
2. [Skills & Certification Matrix](#-skills--certification-matrix)
3. [Project Architecture & Directory Structure](#-project-architecture--directory-structure)
4. [Technical Prerequisites & Setup](#-technical-prerequisites--setup)
5. [Pipeline Execution Guide](#-pipeline-execution-guide)
6. [Data Modeling & Transformation Strategy](#-data-modeling--transformation-strategy)
7. [Slowly Changing Dimensions (SCD Type 1 & Type 2)](#-slowly-changing-dimensions-scd-type-1--type-2)
8. [Data Governance, Security (RBAC) & GDPR Compliance](#-data-governance-security-rbac--gdpr-compliance)
9. [Data Quality & Testing Framework](#-data-quality--testing-framework)
10. [Deliverable Audit Assets & Screenshot Evidence](#-deliverable-audit-assets--screenshot-evidence)

---

## 🎯 Executive Summary

The **VenteRapide Data Warehouse** project upgrades an operational e-commerce database into an automated, compliant, and scalable analytical warehouse using **dbt (Data Build Tool)** and **PostgreSQL 18**. 

Built strictly upon **Ralph Kimball’s Dimensional Modeling methodology**, the architecture organizes data through an ELT paradigm (**Raw → Staging → Marts**). The solution tracks customer changes over time through Type 2 Slowly Changing Dimensions, enforces strict database security policies through Role-Based Access Control (RBAC), adheres to European GDPR regulations, and establishes continuous data quality monitoring with over 70+ automated dbt tests.

---

## 🎓 Skills & Certification Matrix

This project demonstrates mastery across the required evaluation competencies:

| Competency ID | Competency Description | Project Implementation Proof |
| :--- | :--- | :--- |
| **C16** | **Modeling & Designing Data Warehouses** | Star schema architecture (`fact_commandes`, `dim_produit`, `dim_date`) built using dbt staging and mart layers. |
| **C17** | **Managing Historical Changes (SCD)** | Type 1 overwrite on products and **Type 2 snapshot history tracking** on `scd_client` with Point-in-Time join logic. |
| **C18** | **Data Governance, Security & Documentation** | RBAC privilege policy, GDPR Article 30 registry, automated test assertions, and interactive lineage DAG. |

---

## 📂 Project Architecture & Directory Structure
```
datawarehouse_e6/
├── analyses/                  # Ad-hoc analytical SQL scripts
├── docs/                      # Architectural & compliance documentation
│   ├── GESTION_ACCES_ET_RGPD.md # RBAC roles, grant policies & GDPR registry
│   └── screenshots/           # Certification audit evidence (C17, C18)
│       ├── task_3.6_c17_scd2_client_history_tracking.png
│       ├── task_3.6_c17_point_in_time_fact_scd_join.png
│       └── task_3.7_c18_dbt_lineage_dag_graph.png
├── macros/                    # Reusable SQL logic & custom tests
├── models/
│   ├── staging/               # Cleaning, renaming, & casting (stg_*)
│   │   ├── stg_clients.sql
│   │   ├── stg_commandes.sql
│   │   ├── stg_ligne_commandes.sql
│   │   └── stg_produits.sql
│   └── marts/                 # Star schema dimensional models
│       ├── dim_date.sql
│       ├── dim_produit.sql    # SCD Type 1
│       └── fact_commandes.sql # Central sales fact model
├── seeds/                     # Raw seed CSV datasets
├── snapshots/                 # dbt Snapshots for SCD Type 2
│   └── scd_client.sql         # Client historical state tracking
├── tests/                     # Singular custom SQL data tests
├── dbt_project.yml            # dbt configuration & target mappings
└── packages.yml               # dbt external dependencies (dbt_utils)
```
---

## ⚙️ Technical Prerequisites & Setup

### Environment Requirements
* **Operating System:** macOS / Linux / Windows WSL
* **Database Engine:** PostgreSQL 18+ (managed via Homebrew or system daemon)
* **Runtime:** Python 3.11+
* **dbt Version:** dbt-core 1.12.3 / dbt-postgres 1.11.0

### Local Installation

1. Clone the repository & activate virtual environment:
   git clone <repository_url>
   cd datawarehouse_e6
   python3 -m venv .venv
   source .venv/bin/activate
   pip install dbt-postgres

2. Configure Database Connection (~/.dbt/profiles.yml):
   datawarehouse_e6:
     target: dev
     outputs:
       dev:
         type: postgres
         host: localhost
         port: 5432
         user: dbt_user
         pass: "{{ env_var('DBT_PASSWORD') }}"
         dbname: datawarehouse_e6
         schema: public
         threads: 4

3. Verify Database Connectivity:
   dbt debug

---

## 🚀 Pipeline Execution Guide

Run the full end-to-end data pipeline sequentially:

# 1. Seed raw operational datasets into PostgreSQL
dbt seed

# 2. Build staging models and dimensional marts
dbt run

# 3. Capture historical changes (SCD Type 2 snapshot)
dbt snapshot

# 4. Execute automated data assertion tests
dbt test

# 5. Generate metadata & serve lineage documentation
dbt docs generate
dbt docs serve --port 8080

---

## 📐 Data Modeling & Transformation Strategy

The data warehouse follows **Kimball Star Schema architecture**, dividing data into distinct operational layers:

[Raw Seeds / Tables] ---> [Staging Models (stg_*)] ---> [Marts: Facts & Dimensions]
                                    |
                                    v
                         [dbt Snapshots (scd_*)]

### 1. Staging Layer (`models/staging/`)
Normalizes data types, renames technical fields to intuitive business terms, removes invalid records, and prepares clean staging views without altering operational granularity.

### 2. Marts Layer (`models/marts/`)
* **`fact_commandes` (Fact Table):** Granular transactional record containing order metrics (`montant_total`, `frais_livraison`, `delai_expedition_jours`, `nb_articles`) linked to dimension keys via surrogate keys (`client_id`, `date_commande_id`).
* **`dim_produit` (Dimension Table):** Catalog dimension containing product details, category hierarchy, and unit prices.
* **`dim_date` (Dimension Table):** Comprehensive calendar reference supporting granular temporal analytics (day, month, quarter, year, weekend indicators).

---

## 🔄 Slowly Changing Dimensions (SCD Type 1 & Type 2)

### SCD Type 1 Implementation (`dim_produit`)
Product attribute updates (such as unit price corrections or category renames) overwrite historic values in `dim_produit` to maintain a single current state catalog.

### SCD Type 2 Implementation (`snapshots/scd_client.sql`)
To preserve historical accuracy when customer demographic details change (e.g., relocation from Bordeaux to Lyon), dbt snapshot tracking generates versioned records using `dbt_valid_from` and `dbt_valid_to` timestamps.

#### Point-in-Time Temporal Join Logic
To associate an operational order with the customer's location *at the exact moment the order occurred*:
```
SELECT
    fc.commande_id,
    fc.client_id,
    dd.date_jour AS date_commande,
    sc.ville AS ville_au_moment_de_la_commande,
    sc.segment
FROM public.fact_commandes fc
JOIN public.dim_date dd 
    ON fc.date_commande_id = dd.date_id
LEFT JOIN public.scd_client sc 
    ON fc.client_id = sc.client_id
   AND (
        (dd.date_jour >= sc.dbt_valid_from::date AND (dd.date_jour < sc.dbt_valid_to::date OR sc.dbt_valid_to IS NULL))
        OR sc.dbt_valid_to IS NULL
   );
```
---

## 🔒 Data Governance, Security (RBAC) & GDPR Compliance

Full security and compliance governance documentation is available in [`docs/GESTION_ACCES_ET_RGPD.md`]. 

### 1. Role-Based Access Control (RBAC)
Database permissions follow the **Principle of Least Privilege (PoLP)** across three segregated database roles:

| Role Name | Scope & Purpose | Schema Privileges |
| :--- | :--- | :--- |
| `postgres` / `admin` | Infrastructure administration & DDL migrations | `SUPERUSER` / Full Control |
| `dbt_user` | Automated ETL/ELT pipeline transformation agent | `CREATE`, `SELECT`, `INSERT`, `UPDATE` on `public` |
| `reporting` | Read-only access for BI platforms (e.g., Metabase, PowerBI) | `USAGE` on schema, `SELECT` on Mart tables/views |

### 2. GDPR (RGPD) Compliance Measures
* **Article 30 Processing Register:** Formally catalogs personal data processing purposes, categories (names, email addresses, phone numbers), and data controller responsibilities.
* **Data Minimization & Anonymization:** Raw personal identifiers are masked or hash-anonymized prior to presentation in public reporting views.
* **Storage Limitation:** Inactive client records beyond the mandatory retention window are purged or irreversibly anonymized.

---

## 🧪 Data Quality & Testing Framework

Data integrity is protected by over 70+ automated tests executed via `dbt test`.

* **Generic Tests:** Primary keys are continuously validated for `unique` and `not_null` constraints across staging and mart tables.
* **Referential Integrity:** Foreign key relationships between `fact_commandes` and dimension models (`dim_produit`, `scd_client`) are validated via `relationships` tests.
* **Custom Business Rules:** Singular custom tests assert numeric ranges (e.g., non-negative order amounts: `montant_total >= 0`).

---

## 📸 Deliverable Audit Assets & Screenshot Evidence

Audit artifacts proving full compliance for certification review are archived in `screenshots_report/`:

| Task / Competency | Deliverable Description      | Audit Screenshot Asset |
| :--- | :----------- | :--- |
| **Task 3.1 (C16)** | **dbt Connection Verification:** Validates database connection and adapter configuration via `dbt debug`. | `screenshots_report/01_dbt_connection_debug.png` |
| **Task 3.2 (C16)** | **Staging & Seeds Execution:** Execution output of staging views and seed loading (`stg_retours` & `dbt seed`). | `screenshots_report/02_run_stg_retours_sql_view_model&dbt_seed.png` |
| **Task 3.3 (C16)** | **Fact Model Execution:** Terminal output verifying successful `dbt run` for `fact_retours` model. | `screenshots_report/03_run_output_sql_view_model_fact_retours.png` |
| **Task 3.4 (C18)** | **Data Quality Testing:** Test suite results running schema and custom assertions on `fact_retours`. | `screenshots_report/04_test_output_fact_retours.png` |
| **Task 3.4 (C16)** | **Local Mart Verification:** Query results verifying populated analytical records in `fact_retours`. | `screenshots_report/05_local_dbt_fact_retours.png` |
| **Task 3.4 (C16)** | **Local Staging Verification:** Query results verifying cleaned staging data in `stg_retours`. | `screenshots_report/06_local_dbt_stg_retours.png` |
| **Task 3.5 (C18)** | **RBAC Read-Only Test (Part A):** Proof of restricted permissions for `reporting` read-only user execution. | `screenshots_report/07_b_task_3_5_readonly_test.png` |
| **Task 3.5 (C18)** | **RBAC Read-Only Test (Part B):** Verification of write protection preventing data modification by read-only role. | `screenshots_report/08_task_3_5_readonly_test.png` |
| **Task 3.6 (C17)** | **Point-in-Time Join Execution:** Query output demonstrating historical location matching between order transactions and customer snapshot states. | `screenshots_report/09_task_3_6_c17_point_in_time_fact_scd_join.png` |
| **Task 3.6 (C17)** | **SCD Type 2 History Verification:** Shows expired record (`dbt_valid_to` populated) and active record for client state transition. | `screenshots_report/10_task_3_6_c17_scd2_client_history_tracking.png` |
| **Task 3.7 (C18)** | **dbt Lineage DAG:** Interactive Directed Acyclic Graph proving end-to-end data pipeline connectivity from seeds to marts. | `screenshots_report/11_task_3_7_c18_dbt_lineage_dag_graph.png` |