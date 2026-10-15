-- =====================================================================
-- Inventory Variance Root-Cause Analytics | 01 Create tables
-- All data is SYNTHETIC. Tested on SQLite 3.45; written in standard SQL so it
-- also runs on MySQL 8 / PostgreSQL / SQL Server with the small notes marked "DIALECT".
-- =====================================================================

DROP TABLE IF EXISTS inventory_count_events;
CREATE TABLE inventory_count_events (
    Count_ID                    VARCHAR(12)   NOT NULL PRIMARY KEY,   -- one SKU x bin x count event
    Count_Date                  DATE          NOT NULL,
    Snapshot_Date               DATE          NOT NULL,
    SKU_ID                      VARCHAR(10)   NOT NULL,
    Product_Name                VARCHAR(60),
    Category                    VARCHAR(30),
    Warehouse                   VARCHAR(20),
    Zone                        VARCHAR(30),                          -- e.g. 'Z2 Reserve'
    Rack                        VARCHAR(10),
    Bin                         VARCHAR(20)   NOT NULL,
    System_Qty                  INTEGER       NOT NULL,
    Physical_Qty                INTEGER       NOT NULL,
    Unit_Cost_INR               DECIMAL(10,2) NOT NULL,
    Last_Count_Date             DATE,
    Movement_Qty_30D            INTEGER,
    Inbound_Tx_30D              INTEGER,
    Outbound_Tx_30D             INTEGER,
    Return_Tx_30D               INTEGER,
    Adjustment_Tx_90D           INTEGER,
    Initial_Reason_Code         VARCHAR(30),
    Confirmed_Root_Cause        VARCHAR(30),                          -- synthetic post-investigation label
    Process_Area                VARCHAR(20),
    Shift                       VARCHAR(10),
    Reconciliation_Status       VARCHAR(15),
    Previous_Variance_Count_90D INTEGER
);

DROP TABLE IF EXISTS sku_master;
CREATE TABLE sku_master (
    SKU_ID        VARCHAR(10) NOT NULL PRIMARY KEY,
    Product_Name  VARCHAR(60),
    Category      VARCHAR(30),
    Unit_Cost_INR DECIMAL(10,2),
    Source        VARCHAR(12)
);

DROP TABLE IF EXISTS reason_code_lookup;
CREATE TABLE reason_code_lookup (
    Confirmed_Root_Cause VARCHAR(30) NOT NULL PRIMARY KEY,
    Process_Area         VARCHAR(20),
    Definition           VARCHAR(150)
);

DROP TABLE IF EXISTS movement_summary_90d;
CREATE TABLE movement_summary_90d (
    SKU_ID           VARCHAR(10),
    Warehouse        VARCHAR(20),
    Units_Out_90D    INTEGER,
    Units_In_90D     INTEGER,
    Return_Units_90D INTEGER
);

-- Risk-score parameters. These match the yellow cells on the Excel 'Parameters' sheet.
-- The two movement thresholds are the 50th and 80th percentile of Movement_Qty_30D
-- (Excel: PERCENTILE). Percentile functions differ between databases, so they are stored here.
DROP TABLE IF EXISTS risk_parameters;
CREATE TABLE risk_parameters (
    param_name  VARCHAR(40) NOT NULL PRIMARY KEY,
    param_value DECIMAL(14,4) NOT NULL,
    note        VARCHAR(120)
);
INSERT INTO risk_parameters VALUES ('w_history',            0.30,   'weight: variance history');
INSERT INTO risk_parameters VALUES ('w_value',              0.30,   'weight: variance value');
INSERT INTO risk_parameters VALUES ('w_movement',           0.20,   'weight: movement tier');
INSERT INTO risk_parameters VALUES ('w_age',                0.20,   'weight: days since last count');
INSERT INTO risk_parameters VALUES ('move_medium_units',    496,    '50th percentile of Movement_Qty_30D (Excel Parameters!B12)');
INSERT INTO risk_parameters VALUES ('move_high_units',      1122.6, '80th percentile of Movement_Qty_30D (Excel Parameters!B13)');
INSERT INTO risk_parameters VALUES ('high_cost_inr',        300,    'unit cost at or above = High value');
INSERT INTO risk_parameters VALUES ('repeat_min_events',    3,      'variance events for a repeat-variance bin');
INSERT INTO risk_parameters VALUES ('band_critical',        65,     'risk score at or above');
INSERT INTO risk_parameters VALUES ('band_high',            45,     'risk score at or above');
INSERT INTO risk_parameters VALUES ('band_medium',          25,     'risk score at or above');
INSERT INTO risk_parameters VALUES ('policy_days_high',     30,     'count policy for High movers');
INSERT INTO risk_parameters VALUES ('policy_days_medium',   45,     'count policy for Medium movers');
INSERT INTO risk_parameters VALUES ('policy_days_low',      60,     'count policy for Low movers');
INSERT INTO risk_parameters VALUES ('hist_min_events',      2,      'holdout check: earlier variance events for the history group');
