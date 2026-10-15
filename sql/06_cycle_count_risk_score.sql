-- =====================================================================
-- 06 Cycle-count risk score and priority queue (SKU-bin level). Same logic as the Excel Bin_Risk and Priority_Queue sheets.
-- Score = w_history x history + w_value x value + w_movement x movement + w_age x days since count (each component 0-100 points).
-- =====================================================================

-- As-of date for the score. DIALECT: date arithmetic differs by database; only this view needs editing.
--   SQLite: julianday('2026-10-01') - julianday(last_count_date)
--   MySQL: DATEDIFF('2026-10-01', last_count_date)       SQL Server: DATEDIFF(day, last_count_date, '2026-10-01')
-- The 90-day window start is written as a literal date (as-of 2026-10-01 minus 90 days = 2026-07-03) so no date arithmetic is needed.
DROP VIEW IF EXISTS v_bin_base;
CREATE VIEW v_bin_base AS
SELECT
    b.Bin,
    b.SKU_ID, b.Product_Name, b.Warehouse, b.zone_name,
    b.counts, b.variance_events, b.events_90d, b.total_variance_value, b.avg_abs_variance_value, b.last_count_date,
    l.Movement_Qty_30D AS movement_30d_latest,
    CAST(julianday('2026-10-01') - julianday(b.last_count_date) AS INTEGER) AS days_since_last_count
FROM (
    SELECT Bin, MIN(SKU_ID) AS SKU_ID, MIN(Product_Name) AS Product_Name, MIN(Warehouse) AS Warehouse, MIN(zone_name) AS zone_name,
           COUNT(*) AS counts, SUM(variance_flag) AS variance_events,
           SUM(CASE WHEN variance_flag = 1 AND Count_Date > '2026-07-03' AND Count_Date <= '2026-10-01' THEN 1 ELSE 0 END) AS events_90d,
           SUM(variance_value_inr) AS total_variance_value, 1.0 * SUM(variance_value_inr) / COUNT(*) AS avg_abs_variance_value,
           MAX(Count_Date) AS last_count_date
    FROM v_count_calc GROUP BY Bin
) b
JOIN v_count_calc l ON l.Bin = b.Bin AND l.Count_Date = b.last_count_date;   -- latest count of the bin (one count per bin per date is checked in 03)

DROP VIEW IF EXISTS v_bin_risk;
CREATE VIEW v_bin_risk AS
SELECT x.*,
       ROUND(p.w_history * score_history + p.w_value * score_value + p.w_movement * score_movement + p.w_age * score_age, 1) AS risk_score
FROM (
    SELECT b.*,
           CASE WHEN movement_30d_latest >= p.move_high_units THEN 'High' WHEN movement_30d_latest >= p.move_medium_units THEN 'Medium' ELSE 'Low' END AS movement_tier,
           CASE WHEN events_90d >= 3 THEN 100 WHEN events_90d >= 2 THEN 67 WHEN events_90d >= 1 THEN 33 ELSE 0 END AS score_history,
           CASE WHEN avg_abs_variance_value >= 3000 THEN 100 WHEN avg_abs_variance_value >= 1000 THEN 67 WHEN avg_abs_variance_value >= 250 THEN 33 ELSE 0 END AS score_value,
           CASE WHEN movement_30d_latest >= p.move_high_units THEN 100 WHEN movement_30d_latest >= p.move_medium_units THEN 50 ELSE 0 END AS score_movement,
           CASE WHEN days_since_last_count >= 90 THEN 100 WHEN days_since_last_count >= 60 THEN 67 WHEN days_since_last_count >= 30 THEN 33 ELSE 0 END AS score_age
    FROM v_bin_base b CROSS JOIN v_params p
) x CROSS JOIN v_params p;

DROP VIEW IF EXISTS v_priority_queue;
CREATE VIEW v_priority_queue AS
SELECT ROW_NUMBER() OVER (ORDER BY risk_score DESC, total_variance_value DESC, Bin DESC) AS priority_rank,   -- same tie-break as Excel Sort_Key
       r.*,
       CASE WHEN risk_score >= p.band_critical THEN 'Critical' WHEN risk_score >= p.band_high THEN 'High' WHEN risk_score >= p.band_medium THEN 'Medium' ELSE 'Low' END AS priority,
       CASE WHEN days_since_last_count > CASE movement_tier WHEN 'High' THEN p.policy_days_high WHEN 'Medium' THEN p.policy_days_medium ELSE p.policy_days_low END THEN 1 ELSE 0 END AS overdue_flag,
       CASE WHEN variance_events >= p.repeat_min_events THEN 1 ELSE 0 END AS repeat_flag
FROM v_bin_risk r CROSS JOIN v_params p;

-- Q: priority_band_counts
SELECT priority, COUNT(*) AS locations, ROUND(100.0 * SUM(total_variance_value) / (SELECT SUM(total_variance_value) FROM v_priority_queue), 1) AS pct_of_period_variance_value
FROM v_priority_queue GROUP BY priority ORDER BY CASE priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;
-- END Q

-- Q: top_20_priority_queue
SELECT priority_rank, Bin, SKU_ID, Warehouse, zone_name, variance_events, events_90d, ROUND(avg_abs_variance_value, 0) AS avg_abs_variance_inr, movement_30d_latest, days_since_last_count, risk_score, priority
FROM v_priority_queue ORDER BY priority_rank LIMIT 20;
-- END Q

-- Q: risk_summary
SELECT COUNT(*) AS locations,
       SUM(CASE WHEN priority IN ('Critical','High') THEN 1 ELSE 0 END) AS critical_plus_high,
       ROUND(100.0 * SUM(CASE WHEN priority IN ('Critical','High') THEN total_variance_value ELSE 0 END) / SUM(total_variance_value), 1) AS critical_high_pct_of_value,
       SUM(overdue_flag) AS overdue_locations,
       SUM(repeat_flag) AS repeat_locations,
       ROUND(100.0 * SUM(CASE WHEN repeat_flag = 1 THEN variance_events ELSE 0 END) / SUM(variance_events), 1) AS repeat_pct_of_events,
       ROUND(100.0 * SUM(CASE WHEN repeat_flag = 1 THEN total_variance_value ELSE 0 END) / SUM(total_variance_value), 1) AS repeat_pct_of_value
FROM v_priority_queue;
-- END Q

-- Q: holdout_check
-- Do earlier variances (before 2026-08-15) predict later ones (on or after)? Only locations counted both before and after.
WITH h AS (
    SELECT Bin,
           SUM(CASE WHEN Count_Date <  '2026-08-15' THEN 1 ELSE 0 END)             AS counts_before,
           SUM(CASE WHEN Count_Date <  '2026-08-15' THEN variance_flag ELSE 0 END) AS hist_events,
           SUM(CASE WHEN Count_Date >= '2026-08-15' THEN 1 ELSE 0 END)             AS counts_after,
           SUM(CASE WHEN Count_Date >= '2026-08-15' THEN variance_flag ELSE 0 END) AS var_after
    FROM v_count_calc GROUP BY Bin
)
SELECT CASE WHEN hist_events >= 2 THEN 'history group' ELSE 'no-history group' END AS grp,
       COUNT(*) AS locations, ROUND(100.0 * SUM(var_after) / SUM(counts_after), 1) AS variance_rate_after_pct
FROM h WHERE counts_before > 0 AND counts_after > 0 GROUP BY CASE WHEN hist_events >= 2 THEN 'history group' ELSE 'no-history group' END ORDER BY grp;
-- END Q
