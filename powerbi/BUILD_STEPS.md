# Power BI build steps: Inventory Variance Root-Cause Analytics

The data model, Power Query (M) and DAX are in this repository. The report itself is built in Power BI Desktop; these are the steps (about 45 to 60 minutes the first time).
The numbers shown in the check table at the end come from the Excel workbook and the SQL queries, so you can confirm the report is right before you export it.

## 1. Load the data
1. Open Power BI Desktop. **Home > Transform data > Manage parameters > New parameter**: Name `RepoPath`, Type `Text`, Current value = the full path of this folder, ending with a backslash (for example `C:\Projects\inventory-variance-root-cause-analytics-excel-sql-powerbi\`). Click OK.
2. For each query below: **Home > Transform data > New source > Blank query**, then **Home > Advanced editor**, delete the default text, paste the file from the `power-query` folder, click **Done**, and rename the query exactly as shown. Create them in this order:
   1. **Params**: `00_Params.pq` (a record of thresholds and weights)
   2. **CountEvents**: `01_CountEvents.pq`
   3. **SKUMaster**: `02_SKUMaster.pq`
   4. **BinRisk**: `03_BinRisk.pq` (one row per SKU-bin, risk score and rank; uses Params and CountEvents)
3. Check each query for a yellow banner or an error cell. If there is one, read the message, fix that step in the Advanced editor, and compare with the SQL or Excel number before moving on. These M files have not yet been run in Power BI Desktop, so a small fix on first load is normal.
4. **Home > Close & apply**.

## 2. Model
- CountEvents[SKU_ID] to SKUMaster[SKU_ID]: many-to-one, single direction.
- CountEvents[Bin] to BinRisk[Bin]: many-to-one, single direction (BinRisk acts as a small dimension for the priority table).
- Create a date table: **Modeling > New table**, then paste the Calendar formula given at the end of `dax/measures.dax`. Relate Calendar[Date] to CountEvents[Count_Date] (many-to-one, single direction).
- Hide the key columns you do not need on report pages.

## 3. Measures
Create each measure in `dax/measures.dax`: select the fact table, **Modeling > New measure**, paste one measure at a time. Then set the format:

| Measure | Format |
|---|---|
| Counted Records, Exact Matches, Variance Records, Absolute Variance Units | Whole number, thousands separator |
| Record Accuracy %, Unit Accuracy %, Initial Equals Confirmed %, Unconfirmed Value %, Variance Value % of Total, Cumulative Value %, Critical High Value % | Percentage, 1 decimal |
| Variance Value INR, Net Variance Value INR, Shortage Value INR, Surplus Value INR | Whole number, thousands separator |
| Variance Value Lakh | Decimal, 2 places |
| Avg Risk Score | Decimal, 1 place |
| Locations, Critical Locations, High Locations, Critical Plus High, Open Or Investigating Variances | Whole number |

## 4. Theme
**View > Themes > Browse for themes**, choose `powerbi/powerbi_theme.json`.

## 5. Pages
### Page 1: Executive Inventory Accuracy
- Cards: Record Accuracy %, Unit Accuracy %, Variance Value Lakh, Open Or Investigating Variances, Critical Plus High.
- Line chart: Calendar[Week Start] on the axis, Record Accuracy % as values; filter out the partial first and last weeks with a visual-level filter on Calendar[Week Start].
- Slicers: Warehouse, Zone_Name, Category, Calendar[Date].

### Page 2: Variance Root Cause
- Pareto: line and clustered column chart. Confirmed_Root_Cause on the axis (sort by Variance Value INR, descending), column = Variance Value INR, line = Cumulative Value %. Add a filter Variance_Flag = 1.
- Matrix: Zone_Name rows x Confirmed_Root_Cause columns, values = Variance Records, conditional formatting (background colour scale).
- Table: Initial_Reason_Code vs Confirmed_Root_Cause, value = Variance Records, to show how often the first-pass reason is wrong.

### Page 3: SKU / Warehouse / Bin Drilldown
- Matrix: Warehouse rows x Zone_Name columns, value = variance rate (Variance Records / Counted Records), colour scale.
- Scatter: X = Movement_30D_Latest (BinRisk), Y = Total_Variance_Value (BinRisk), details = Bin, log scale on both axes.
- Table with drill-through: Warehouse > Zone_Name > Bin, values Counted Records, Variance Records, Variance Value INR.

### Page 4: Financial Exposure
- Clustered column: Shortage Value INR vs Surplus Value INR by Warehouse.
- Bar chart: Variance Value INR by Category and by Zone_Name.
- Card: Net Variance Value INR (negative = physical below system).

### Page 5: Cycle Count Priority Queue
- Table: BinRisk Priority_Rank, Bin, SKU_ID, Product_Name, Warehouse, Zone_Name, Events_90D, Avg_Abs_Variance_Value, Movement_30D_Latest, Days_Since_Last_Count, Risk_Score, Priority. Sort by Priority_Rank ascending.
- Slicer: Priority (Critical, High, Medium, Low). Bar chart: Locations by Priority.

## 6. Check the numbers before you export
| Item | Should read |
|---|---|
| Record Accuracy % | 81.3% |
| Unit Accuracy % | 97.0% |
| Variance Value INR | 4,550,655 |
| Variance Records / Counted Records | 982 / 5,243 |
| Open Or Investigating Variances | 413 |
| Critical Locations, High Locations | 41, 65 |
| Top root cause by value | Wrong Bin Putaway (19%) |

If a number is off, the cause is almost always a missing filter, a wrong data type, or a relationship direction. Compare with the matching SQL query in the `sql` folder.

## 7. Export the PDF for your LinkedIn post
**File > Export > Export to PDF**. Choose all pages, save as `powerbi/inventory-variance-root-cause-analytics-report.pdf`. Take one screenshot per page (**Windows key + Shift + S**) into `dashboard/screenshots/`. Save the report as `powerbi/inventory-variance-root-cause-analytics.pbix` if the file is under 100 MB (GitHub's limit).
