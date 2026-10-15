-- =====================================================================
-- 04 Calculation views. Same definitions as the Excel formula columns (see documentation/calculation_definitions.md).
-- Any database-specific syntax lives only in this file, marked DIALECT.
-- =====================================================================

-- One-row view that pivots the parameter table so queries can CROSS JOIN it.
DROP VIEW IF EXISTS v_params;
CREATE VIEW v_params AS
SELECT
    MAX(CASE WHEN param_name = 'w_history'          THEN param_value END) AS w_history,
    MAX(CASE WHEN param_name = 'w_value'            THEN param_value END) AS w_value,
    MAX(CASE WHEN param_name = 'w_movement'         THEN param_value END) AS w_movement,
    MAX(CASE WHEN param_name = 'w_age'              THEN param_value END) AS w_age,
    MAX(CASE WHEN param_name = 'move_medium_units'  THEN param_value END) AS move_medium_units,
    MAX(CASE WHEN param_name = 'move_high_units'    THEN param_value END) AS move_high_units,
    MAX(CASE WHEN param_name = 'high_cost_inr'      THEN param_value END) AS high_cost_inr,
    MAX(CASE WHEN param_name = 'repeat_min_events'  THEN param_value END) AS repeat_min_events,
    MAX(CASE WHEN param_name = 'band_critical'      THEN param_value END) AS band_critical,
    MAX(CASE WHEN param_name = 'band_high'          THEN param_value END) AS band_high,
    MAX(CASE WHEN param_name = 'band_medium'        THEN param_value END) AS band_medium,
    MAX(CASE WHEN param_name = 'policy_days_high'   THEN param_value END) AS policy_days_high,
    MAX(CASE WHEN param_name = 'policy_days_medium' THEN param_value END) AS policy_days_medium,
    MAX(CASE WHEN param_name = 'policy_days_low'    THEN param_value END) AS policy_days_low,
    MAX(CASE WHEN param_name = 'hist_min_events'    THEN param_value END) AS hist_min_events
FROM risk_parameters;

-- Row-level calculations (Excel columns Z to AJ on Count_Events).
DROP VIEW IF EXISTS v_count_calc;
CREATE VIEW v_count_calc AS
SELECT
    e.*,
    CASE WHEN e.System_Qty = e.Physical_Qty THEN 1 ELSE 0 END           AS record_match_flag,
    CASE WHEN e.System_Qty = e.Physical_Qty THEN 0 ELSE 1 END           AS variance_flag,
    e.Physical_Qty - e.System_Qty                                       AS signed_variance_qty,        -- negative = shortage
    ABS(e.Physical_Qty - e.System_Qty)                                  AS absolute_variance_qty,
    ABS(e.Physical_Qty - e.System_Qty) * e.Unit_Cost_INR                AS variance_value_inr,
    (e.Physical_Qty - e.System_Qty) * e.Unit_Cost_INR                   AS signed_variance_value_inr,
    SUBSTR(e.Zone, INSTR(e.Zone, ' ') + 1)                              AS zone_name,                  -- DIALECT: SQL Server uses CHARINDEX(' ', e.Zone)
    CASE WHEN e.Movement_Qty_30D >= p.move_high_units   THEN 'High'
         WHEN e.Movement_Qty_30D >= p.move_medium_units THEN 'Medium'
         ELSE 'Low' END                                                 AS movement_tier,
    CASE WHEN e.Unit_Cost_INR >= p.high_cost_inr THEN 'High value' ELSE 'Standard' END AS cost_tier,
    CASE WHEN e.System_Qty <> e.Physical_Qty AND e.Initial_Reason_Code = e.Confirmed_Root_Cause THEN 1 ELSE 0 END AS initial_matches_confirmed
FROM inventory_count_events e
CROSS JOIN v_params p;
