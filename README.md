# Why Does System Stock Not Match Physical Stock?
### Inventory Variance Root-Cause Analytics (Week 2)

Where do system stock and physical counts disagree, why, what is it worth, and which locations should be counted first?

Built with **Excel** (formulas, named ranges, charts), **SQL** and **Power BI** (Power Query + DAX). All data is synthetic, prepared for this project: 5 fictional warehouses, 5,243 cycle-count events, 1 Jul – 30 Sep 2026.

## Headline results (synthetic data)
- Record accuracy **81.3%**, unit accuracy **97.0%**; variance value **INR 45.51 lakh** (shortage 28.58, surplus 16.93).
- No single cause dominates: the top four causes make up 63% of variance value (Wrong Bin Putaway 19%, Receiving Count Error 18%, Unknown 13.5%, Unprocessed Return 13%).
- Reserve zone: 29% of counts but 46% of variance value.
- 24% of locations account for 88% of variance value; locations with 2+ earlier variances had a 34.7% later variance rate vs 17.0% for the rest.
- Shift and category differences are not statistically clear.

Details and caveats: `documentation/findings.md`.

## What is inside
| Folder | Contents |
|---|---|
| `excel/` | `Inventory_Variance_Workbook.xlsx`: Parameters (yellow inputs), Summary, Root_Cause, Trend, Risk_Summary, Priority_Queue, Tests, Checks, dashboard sheets |
| `sql/` | Tables, data-quality checks, calculation views, analysis queries, risk score, reconciliation |
| `power-query/`, `dax/` | Power Query (M) queries and DAX measures for the Power BI model |
| `powerbi/` | `BUILD_STEPS.md` (page-by-page build guide) and `powerbi_theme.json` |
| `dashboard/` | Dashboard preview exported from the Excel workbook |
| `documentation/` | Methodology, calculation definitions, findings, validation, limitations |
| `data/raw/` | Four CSV files (count events, SKU master, reason codes, 90-day movement) |

## How to use
1. Open the workbook; change thresholds and weights on `Parameters` and everything recalculates. `Checks` should show all PASS.
2. SQL: run `sql/01` to `07` in order (standard SQL; dialect notes inside).
3. Power BI: follow `powerbi/BUILD_STEPS.md`.

## Status and limits
- The Excel workbook and SQL scripts were checked against each other (236 matching comparisons).
- The Power Query and DAX files have not been run in Power BI Desktop yet; check against the numbers in `BUILD_STEPS.md`.
- The dashboard PDF/PNGs here come from Excel, not Power BI.
- The priority score is a transparent rule-based model, not a prediction. No savings are claimed.
