-- =====================================================================
-- 05 Analysis queries: accuracy, financial exposure, root cause. Each result matches a table on the Excel Summary / Root_Cause sheets.
-- =====================================================================

-- Q: overall_kpis
-- Record accuracy = exact matches / counts. Unit accuracy = 1 - absolute variance units / system units (floored at 0, blank if system units are 0).
SELECT
    COUNT(*)                                                         AS counted_records,
    SUM(record_match_flag)                                           AS exact_matches,
    ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4)                AS record_accuracy,
    CASE WHEN SUM(System_Qty) > 0
         THEN ROUND(MAX(0, 1 - 1.0 * SUM(absolute_variance_qty) / SUM(System_Qty)), 4) END AS unit_accuracy,
    SUM(variance_flag)                                               AS variance_records,
    ROUND(SUM(variance_value_inr), 2)                                AS variance_value_inr,
    ROUND(-SUM(CASE WHEN signed_variance_qty < 0 THEN signed_variance_value_inr ELSE 0 END), 2) AS shortage_value_inr,
    ROUND(SUM(CASE WHEN signed_variance_qty > 0 THEN signed_variance_value_inr ELSE 0 END), 2)  AS surplus_value_inr
FROM v_count_calc;
-- END Q

-- Q: by_warehouse
SELECT Warehouse AS grp, COUNT(*) AS counts, SUM(record_match_flag) AS exact_matches,
       ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy,
       ROUND(SUM(variance_value_inr), 2) AS variance_value_inr,
       ROUND(100.0 * SUM(variance_value_inr) / (SELECT SUM(variance_value_inr) FROM v_count_calc), 1) AS pct_of_value
FROM v_count_calc GROUP BY Warehouse ORDER BY variance_value_inr DESC;
-- END Q

-- Q: by_zone
SELECT zone_name AS grp, COUNT(*) AS counts, SUM(record_match_flag) AS exact_matches,
       ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy,
       ROUND(SUM(variance_value_inr), 2) AS variance_value_inr,
       ROUND(100.0 * SUM(variance_value_inr) / (SELECT SUM(variance_value_inr) FROM v_count_calc), 1) AS pct_of_value
FROM v_count_calc GROUP BY zone_name ORDER BY variance_value_inr DESC;
-- END Q

-- Q: by_shift
SELECT Shift AS grp, COUNT(*) AS counts, SUM(record_match_flag) AS exact_matches,
       ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr
FROM v_count_calc GROUP BY Shift ORDER BY variance_value_inr DESC;
-- END Q

-- Q: by_category
SELECT Category AS grp, COUNT(*) AS counts, SUM(record_match_flag) AS exact_matches,
       ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr
FROM v_count_calc GROUP BY Category ORDER BY variance_value_inr DESC;
-- END Q

-- Q: by_movement_tier
SELECT movement_tier AS grp, COUNT(*) AS counts, SUM(record_match_flag) AS exact_matches,
       ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr
FROM v_count_calc GROUP BY movement_tier ORDER BY variance_value_inr DESC;
-- END Q

-- Q: by_cost_tier
SELECT cost_tier AS grp, COUNT(*) AS counts, SUM(record_match_flag) AS exact_matches,
       ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr
FROM v_count_calc GROUP BY cost_tier ORDER BY variance_value_inr DESC;
-- END Q

-- Q: pareto_root_cause
-- Window functions give the running (cumulative) share, the same as the Excel Pareto table.
SELECT Confirmed_Root_Cause AS root_cause, variance_records, ROUND(value_inr, 2) AS variance_value_inr,
       ROUND(100.0 * value_inr / SUM(value_inr) OVER (), 1) AS pct_of_value,
       ROUND(100.0 * SUM(value_inr) OVER (ORDER BY value_inr DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM(value_inr) OVER (), 1) AS cumulative_pct
FROM (SELECT Confirmed_Root_Cause, SUM(variance_flag) AS variance_records, SUM(variance_value_inr) AS value_inr
      FROM v_count_calc WHERE variance_flag = 1 GROUP BY Confirmed_Root_Cause) t
ORDER BY value_inr DESC;
-- END Q

-- Q: first_pass_reason_quality
SELECT SUM(variance_flag) AS variance_records,
       ROUND(100.0 * SUM(initial_matches_confirmed) / SUM(variance_flag), 1) AS pct_initial_equals_confirmed,
       ROUND(100.0 * SUM(CASE WHEN variance_flag = 1 AND Initial_Reason_Code = 'Unknown' THEN 1 ELSE 0 END) / SUM(variance_flag), 1) AS pct_initial_unknown
FROM v_count_calc;
-- END Q

-- Q: zone_by_root_cause
SELECT zone_name, Confirmed_Root_Cause AS root_cause, COUNT(*) AS variance_records
FROM v_count_calc WHERE variance_flag = 1 GROUP BY zone_name, Confirmed_Root_Cause ORDER BY zone_name, variance_records DESC;
-- END Q

-- Q: open_or_investigating
SELECT COUNT(*) AS variance_records, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr
FROM v_count_calc WHERE variance_flag = 1 AND Reconciliation_Status IN ('Open', 'Investigating');
-- END Q

-- Q: monthly_trend
-- DIALECT: SUBSTR on a date works in SQLite/MySQL. SQL Server: FORMAT(Count_Date, 'yyyy-MM'). PostgreSQL: TO_CHAR(Count_Date, 'YYYY-MM').
SELECT SUBSTR(Count_Date, 1, 7) AS month, COUNT(*) AS counts, ROUND(1.0 * SUM(record_match_flag) / COUNT(*), 4) AS record_accuracy, ROUND(SUM(variance_value_inr), 2) AS variance_value_inr
FROM v_count_calc GROUP BY SUBSTR(Count_Date, 1, 7) ORDER BY month;
-- END Q
