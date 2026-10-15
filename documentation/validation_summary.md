# Validation summary

## Excel `Checks` sheet (live formulas): ALL PASS
Row count at least 5,000 (5,243); unique non-blank Count_ID; no blanks in the 25 raw columns; no negative quantities; unit cost above zero; Last_Count_Date not after Count_Date; every SKU joins to the SKU master; one count per bin per date; every variance row has a cause; zero System_Qty rows exist (67) and unit accuracy still calculates; variance value equals the warehouse and zone table totals; Pareto ends at 100%; risk weights add up to 100%; every location has exactly one rank.

## SQL against Excel
All 236 comparisons match (queries in `sql/05` to `sql/07` against Summary, Root_Cause, Risk_Summary and Priority_Queue values), including the top-20 priority queue rows, band counts and the holdout check. Run `sql/03_data_quality_checks.sql` after loading: every query returns 0 except the row-count and zero-quantity information queries.

## Sign check on real rows
| Case | Count_ID | System | Physical | Signed |
|---|---|---|---|---|
| Shortage | CNT-000015 | 26 | 25 | -1 |
| Surplus | CNT-000012 | 59 | 60 | 1 |
| Match | CNT-000001 | 243 | 243 | 0 |

## Reconciliation
Variance value 4,550,654.65 equals the total of each segment table (warehouse, zone, shift, category, tier) and the Pareto table.

## Not verified
- The Power Query (M) and DAX files have not been run in Power BI Desktop. Check them on first load against the numbers in `powerbi/BUILD_STEPS.md`.
- No .pbix exists in this repository until you build it.
- The PDF in `dashboard/` is exported from the Excel dashboard sheets, not from Power BI.
