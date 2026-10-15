-- =====================================================================
-- 02 Load the CSV files from data/raw into the tables created in 01.
-- Pick the block for your database. (Nothing here runs by itself.)
-- Load order: sku_master, reason_code_lookup, inventory_count_events, movement_summary_90d.
-- =====================================================================

-- ---- SQLite (command-line shell) ----
-- .mode csv
-- .import --skip 1 data/raw/sku_master.csv sku_master
-- .import --skip 1 data/raw/reason_code_lookup.csv reason_code_lookup
-- .import --skip 1 data/raw/inventory_count_events.csv inventory_count_events
-- .import --skip 1 data/raw/movement_summary_90d.csv movement_summary_90d

-- ---- MySQL 8 ----
-- LOAD DATA LOCAL INFILE 'data/raw/inventory_count_events.csv' INTO TABLE inventory_count_events
--   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
-- (repeat for the other three files)

-- ---- SQL Server ----
-- BULK INSERT inventory_count_events FROM 'C:\path\data\raw\inventory_count_events.csv'
--   WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', FORMAT = 'CSV');
-- (or use the Import Flat File wizard in SSMS)

-- ---- PostgreSQL ----
-- \copy inventory_count_events FROM 'data/raw/inventory_count_events.csv' WITH (FORMAT csv, HEADER true)

-- After loading, expected row counts: inventory_count_events 5243, sku_master 400, reason_code_lookup 9, movement_summary_90d 570.
-- The reason_code_lookup CSV header is 'Definition (SYNTHETIC)'; the table column is named Definition.
