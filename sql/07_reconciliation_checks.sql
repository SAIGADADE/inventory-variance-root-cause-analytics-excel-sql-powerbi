-- =====================================================================
-- 07 Reconciliation: control totals that must agree between SQL, the Excel workbook and Power BI.
-- Expected values (from the Excel Summary sheet): 5243 counts, 4261 exact matches, variance value 4550654.65, 41 Critical / 65 High / 134 Medium / 380 Low locations.
-- =====================================================================

-- Q: control_totals
SELECT COUNT(*) AS counted_records, SUM(record_match_flag) AS exact_matches, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr FROM v_count_calc;
-- END Q

-- Q: warehouse_total_equals_overall
SELECT ROUND((SELECT SUM(variance_value_inr) FROM v_count_calc) - SUM(v), 2) AS difference
FROM (SELECT Warehouse, SUM(variance_value_inr) AS v FROM v_count_calc GROUP BY Warehouse) t;
-- END Q

-- Q: pareto_total_equals_overall
SELECT ROUND((SELECT SUM(variance_value_inr) FROM v_count_calc) - SUM(v), 2) AS difference
FROM (SELECT Confirmed_Root_Cause, SUM(variance_value_inr) AS v FROM v_count_calc GROUP BY Confirmed_Root_Cause) t;
-- END Q

-- Q: sign_test_examples
-- Hand-check: Signed = Physical - System.
SELECT 'shortage' AS example, MIN(Count_ID) AS count_id, MIN(System_Qty) AS system_qty, MIN(Physical_Qty) AS physical_qty, MIN(signed_variance_qty) AS signed
FROM v_count_calc WHERE Count_ID = (SELECT MIN(Count_ID) FROM v_count_calc WHERE signed_variance_qty < 0)
UNION ALL
SELECT 'surplus', MIN(Count_ID), MIN(System_Qty), MIN(Physical_Qty), MIN(signed_variance_qty)
FROM v_count_calc WHERE Count_ID = (SELECT MIN(Count_ID) FROM v_count_calc WHERE signed_variance_qty > 0)
UNION ALL
SELECT 'match', MIN(Count_ID), MIN(System_Qty), MIN(Physical_Qty), MIN(signed_variance_qty)
FROM v_count_calc WHERE Count_ID = (SELECT MIN(Count_ID) FROM v_count_calc WHERE signed_variance_qty = 0);
-- END Q
