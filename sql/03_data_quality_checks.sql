-- =====================================================================
-- 03 Data quality checks. Every query returns the number of violating rows: 0 = pass.
-- =====================================================================

-- Q: dq_row_count
SELECT COUNT(*) AS row_count FROM inventory_count_events;
-- END Q

-- Q: dq_duplicate_count_ids
SELECT COUNT(*) AS violations FROM (SELECT Count_ID FROM inventory_count_events GROUP BY Count_ID HAVING COUNT(*) > 1) d;
-- END Q

-- Q: dq_null_required_fields
SELECT COUNT(*) AS violations FROM inventory_count_events
WHERE Count_Date IS NULL OR SKU_ID IS NULL OR Bin IS NULL OR System_Qty IS NULL OR Physical_Qty IS NULL OR Unit_Cost_INR IS NULL OR Confirmed_Root_Cause IS NULL;
-- END Q

-- Q: dq_negative_quantities
SELECT COUNT(*) AS violations FROM inventory_count_events WHERE System_Qty < 0 OR Physical_Qty < 0;
-- END Q

-- Q: dq_non_positive_cost
SELECT COUNT(*) AS violations FROM inventory_count_events WHERE Unit_Cost_INR <= 0;
-- END Q

-- Q: dq_last_count_after_count_date
SELECT COUNT(*) AS violations FROM inventory_count_events WHERE Last_Count_Date > Count_Date;
-- END Q

-- Q: dq_sku_not_in_master
SELECT COUNT(*) AS violations FROM inventory_count_events e LEFT JOIN sku_master s ON s.SKU_ID = e.SKU_ID WHERE s.SKU_ID IS NULL;
-- END Q

-- Q: dq_root_cause_not_in_lookup
SELECT COUNT(*) AS violations FROM inventory_count_events e LEFT JOIN reason_code_lookup r ON r.Confirmed_Root_Cause = e.Confirmed_Root_Cause WHERE r.Confirmed_Root_Cause IS NULL;
-- END Q

-- Q: dq_duplicate_bin_per_date
SELECT COUNT(*) AS violations FROM (SELECT Bin, Count_Date FROM inventory_count_events GROUP BY Bin, Count_Date HAVING COUNT(*) > 1) d;
-- END Q

-- Q: dq_bins_with_more_than_one_sku
SELECT COUNT(*) AS violations FROM (SELECT Bin FROM inventory_count_events GROUP BY Bin HAVING COUNT(DISTINCT SKU_ID) > 1) d;
-- END Q

-- Q: dq_variance_without_cause
SELECT COUNT(*) AS violations FROM inventory_count_events WHERE System_Qty <> Physical_Qty AND Confirmed_Root_Cause = 'Not Applicable';
-- END Q

-- Q: dq_zero_system_qty_rows
-- Not an error: zero system quantity is a documented edge case. Unit accuracy only divides by the SUM of system qty, so it never divides by zero.
SELECT COUNT(*) AS rows_with_zero_system_qty FROM inventory_count_events WHERE System_Qty = 0;
-- END Q
