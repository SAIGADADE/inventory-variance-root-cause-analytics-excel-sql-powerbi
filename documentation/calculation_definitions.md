# Calculation definitions

Same logic in all three tools. Excel columns are on `Count_Events` (green headers); SQL is in `sql/04_views_calculations.sql`; Power Query is `power-query/01_CountEvents.pq`; DAX is `dax/measures.dax`.

| Field / measure | Formula | Units | Blank or zero treatment | Example (real row) |
|---|---|---|---|---|
| Record_Match_Flag | 1 if System_Qty = Physical_Qty, else 0 | flag | n/a | CNT-000001: 243 vs 243 gives 1 |
| Signed_Variance_Qty | Physical_Qty - System_Qty | units | negative = shortage, positive = surplus | CNT-000015: 25 - 26 = -1 |
| Absolute_Variance_Qty | ABS(Signed_Variance_Qty) | units | | 1 |
| Variance_Value_INR | Absolute_Variance_Qty x Unit_Cost_INR | INR | cost is always above zero (checked) | |
| Record accuracy % | exact matches / counted records | % | blank if no counts | 4,261 / 5,243 = 81.3% |
| Unit accuracy % | MAX(0, 1 - sum(absolute variance units) / sum(System_Qty)) | % | blank when the system quantity total is 0 (no divide by zero) | 97.0% |
| Snapshot_Date | equals Count_Date: the system quantity is read when counting starts | date | | |
| Zero System_Qty rows | kept (67 rows); a physical count above 0 is a valid surplus | | unit accuracy uses totals, so one zero row cannot break it | |

## Cycle-count risk score (0 to 100)
Score = 30% history + 30% value + 20% movement + 20% age. The weights are the brief's starting weights; every threshold sits on the `Parameters` sheet (yellow cells) and the `risk_parameters` table in SQL.

| Component | Measured as | Points |
|---|---|---|
| History | variance events at the SKU-bin in the 90 days before 1 Oct 2026 | 0 events = 0, 1 = 33, 2 = 67, 3 or more = 100 |
| Value | average absolute variance value per count at the bin | below INR 250 = 0, 250+ = 33, 1,000+ = 67, 3,000+ = 100 |
| Movement | tier from Movement_Qty_30D at the latest count | Low = 0, Medium = 50, High = 100 (Medium from the 50th percentile, High from the 80th: 496 and 1,123 units) |
| Age | days since the latest count at 1 Oct 2026 | under 30 = 0, 30+ = 33, 60+ = 67, 90+ = 100 |

Priority bands: Critical at 65 or more, High 45+, Medium 25+, otherwise Low. Count-policy age for the overdue flag: High movers 30 days, Medium 45, Low 60. Ranks break ties by total variance value, then by sheet order.
