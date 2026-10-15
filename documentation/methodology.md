# Methodology

**Business problem.** System stock and physical counts differ because of wrong-bin putaway, unrecorded picks, unposted returns, damage, receiving mistakes and counting errors. The Inventory Control Manager needs to know where and why records differ, what the gap is worth, and which locations to count first.

**Decision supported.** A daily and weekly cycle-count list, plus process fixes for the biggest causes.

**Process.** Receiving, Putaway, Storage, Picking, Returns/Adjustments, Cycle Count, Reconciliation. Count events sit at the Cycle Count step; each confirmed root cause points back to an earlier step.

**Data grain.** One SKU x bin x count event (`Count_ID`). One SKU per bin location. Nothing is aggregated before the uniqueness checks.

**Scope and exclusions.** Synthetic period 1 July to 30 September 2026, 5 fictional warehouses, 5 zones, 5 categories, 400 SKUs (396 counted), 620 bins. No labour time, counting cost or real employer data.

**Order of work.** Data checks (Excel `Checks` sheet and `sql/03`) then row-level calculations then summaries by warehouse, zone, shift, category, movement and cost tier, then root-cause Pareto and heat maps, then the risk score and priority queue, then validation.

**Comparisons.** Groups are compared on rates (share of counts with a variance), with a chi-square test (Excel `CHITEST`, sheet `Tests`) so a small gap is not over-read.

**Root cause.** `Confirmed_Root_Cause` is a synthetic label. When no cause is confirmed it is `Unknown/Unconfirmed`, never guessed. For matching counts the cause fields read "No Discrepancy" or "Not Applicable".

**Decision model.** A transparent, adjustable score and band rules, not a prediction model.

**Validation.** 15 live checks on the `Checks` sheet; 236 SQL-vs-Excel comparisons; hand-checked sign cases; holdout check and weight sensitivity for the score. See `validation_summary.md`.
