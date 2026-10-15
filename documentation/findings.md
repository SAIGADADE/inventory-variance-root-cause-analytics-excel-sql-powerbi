# Findings (synthetic data)

Every number below can be traced to the Excel workbook (`excel/Inventory_Variance_Workbook.xlsx`, sheet named in brackets) and to a query in `sql/`. 5,243 count events, 620 SKU-bin locations, 5 fictional warehouses, 1 July to 30 September 2026.

1. **Accuracy [Summary].** 4,261 of 5,243 counts matched exactly: record accuracy 81.3%. Unit accuracy is 97.0%, so most mismatches are small in units. Absolute variance value is INR 45.51 lakh: shortages INR 28.58 lakh, surpluses INR 16.93 lakh, net INR -11.66 lakh (negative = physical below system).
2. **No single dominant cause [Root_Cause].** Share of variance value: Wrong Bin Putaway 19.0%; Receiving Count Error 18.0%; Unknown/Unconfirmed 13.5%; Unprocessed Return 12.9%; Counting Error 12.0%; Unrecorded Pick 11.5%; Damage Not Written Off 7.4%; System Posting Delay 5.7%. The top four add up to 63.4%, so a "fix the top one" approach would leave most of the value untouched.
3. **First-pass reason is a weak guide [Summary].** The initial reason code matched the confirmed cause in 39.9% of variance records and was "Unknown" in 41.8%.
4. **Reserve and Returns Area are the weak zones [Summary, Tests].** Reserve: record accuracy 77.0%, 46% of variance value (INR 20.99 lakh) from 29% of counts. Returns Area has the lowest accuracy (75.9%). 84 of the 160 Wrong Bin Putaway variances (52.5%) are in Reserve. The zone difference is statistically clear (p < 0.001).
5. **Warehouses [Summary, Root_Cause].** Alpha DC carries 37% of the value (INR 16.92 lakh) from 29% of counts. Charlie DC has the lowest record accuracy (78.3%) and the single worst warehouse-zone cell: 36% of its Returns Area counts show a variance. Warehouse differences are modest (p = 0.012).
6. **Fast movers and high-value SKUs are less accurate [Summary, Tests].** High-movement counts (top 20% of 30-day movement) are 20% of counts but 75% of variance value; record accuracy is 72.4% for High, 81.9% Medium, 84.5% Low (p < 0.001). SKUs costing INR 300+ per unit: 75.2% vs 81.6% (250 counts only, p = 0.012).
7. **Repeat variance [Risk_Summary, Summary].** 147 of 620 locations (24%) had 3 or more variance events: 64% of variance events and 88% of variance value. The variance rate rises with earlier variances at the same bin in the prior 90 days: 13.5% (none), 20.0% (one), 26.2% (two), 41.1% (three or more).
8. **Shift and category are not clear drivers [Tests].** Night shift record accuracy is 79.7% vs 81.7% Morning and 81.7% Evening, but the difference could easily be chance (p = 0.310). Category differences are also not significant (p = 0.846).
9. **Open items [Summary].** 413 variance records (INR 18.76 lakh) are still Open or Investigating, and 13.5% of variance value has no confirmed cause. These are labelled Unknown/Unconfirmed rather than guessed.
10. **Cycle-count priority queue [Risk_Summary, Priority_Queue].** 41 Critical, 65 High, 134 Medium and 380 Low locations. Critical plus High (106 locations, 17%) hold 88% of the period's variance value. This is partly circular because the score uses variance history from the same period. The holdout check is fairer: using only history before 15 August, locations with 2 or more earlier variances had a 34.7% variance rate afterwards, against 17.0% for the rest (100 vs 496 locations). Only 9 locations are past their count-policy age, because the window is counting-heavy.
11. **Weight sensitivity [Risk_Summary].** With equal weights, 86% of the base top-50 locations stay in the top 50; with history-heavy weights 98%; with value-heavy weights 88%.
12. **Weekly trend [Trend].** Weekly record accuracy drifts from 85.3% in the first full week to 74.5% in the last full week. In this synthetic dataset repeat variances feed on themselves by design, so this drift should not be read as a real trend.

## Limits
- A synthetic cause label shows a designed pattern, not proof of what happens in a real warehouse.
- The data was built with variance linked to bin, returns activity, prior variances and zone, so several results above are partly built in. They demonstrate the method.
- Tier cut-offs (value, age, movement) are starting assumptions and can be changed on the Parameters sheet.
- The count list is a modelled queue. No savings or accuracy improvement is claimed.
