// Query name: CountEvents
// Needs a Text parameter named RepoPath, e.g. C:\Projects\inventory-variance-root-cause-analytics-excel-sql-powerbi\   (Home > Manage Parameters)
// STATUS: written but not yet run in Power BI Desktop.
let
    Source   = Csv.Document(File.Contents(RepoPath & "data\raw\inventory_count_events.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Typed    = Table.TransformColumnTypes(Promoted, {
        {"Count_ID", type text}, {"Count_Date", type date}, {"Snapshot_Date", type date}, {"SKU_ID", type text}, {"Product_Name", type text}, {"Category", type text},
        {"Warehouse", type text}, {"Zone", type text}, {"Rack", type text}, {"Bin", type text}, {"System_Qty", Int64.Type}, {"Physical_Qty", Int64.Type},
        {"Unit_Cost_INR", type number}, {"Last_Count_Date", type date}, {"Movement_Qty_30D", Int64.Type}, {"Inbound_Tx_30D", Int64.Type}, {"Outbound_Tx_30D", Int64.Type},
        {"Return_Tx_30D", Int64.Type}, {"Adjustment_Tx_90D", Int64.Type}, {"Initial_Reason_Code", type text}, {"Confirmed_Root_Cause", type text},
        {"Process_Area", type text}, {"Shift", type text}, {"Reconciliation_Status", type text}, {"Previous_Variance_Count_90D", Int64.Type}}, "en-US"),
    // Clean text labels. The raw columns stay as they are; derived columns are added after them.
    Cleaned  = Table.TransformColumns(Typed, {{"Category", Text.Trim, type text}, {"Warehouse", Text.Trim, type text}, {"Shift", Text.Proper, type text},
                    {"Confirmed_Root_Cause", Text.Trim, type text}, {"Initial_Reason_Code", Text.Trim, type text}}),
    // Rows with a missing key, quantity or cost are dropped here (the data quality checks in SQL/Excel show there are none in this dataset).
    Valid    = Table.SelectRows(Cleaned, each [Count_ID] <> null and [System_Qty] <> null and [Physical_Qty] <> null and [Unit_Cost_INR] <> null and [Unit_Cost_INR] > 0 and [System_Qty] >= 0 and [Physical_Qty] >= 0),
    Deduped  = Table.Distinct(Valid, {"Count_ID"}),
    Match    = Table.AddColumn(Deduped,  "Record_Match_Flag",        each if [System_Qty] = [Physical_Qty] then 1 else 0, Int64.Type),
    Variance = Table.AddColumn(Match,    "Variance_Flag",            each 1 - [Record_Match_Flag], Int64.Type),
    Signed   = Table.AddColumn(Variance, "Signed_Variance_Qty",      each [Physical_Qty] - [System_Qty], Int64.Type),
    AbsQty   = Table.AddColumn(Signed,   "Absolute_Variance_Qty",    each Number.Abs([Signed_Variance_Qty]), Int64.Type),
    Value    = Table.AddColumn(AbsQty,   "Variance_Value_INR",       each [Absolute_Variance_Qty] * [Unit_Cost_INR], type number),
    SValue   = Table.AddColumn(Value,    "Signed_Variance_Value_INR", each [Signed_Variance_Qty] * [Unit_Cost_INR], type number),
    ZoneName = Table.AddColumn(SValue,   "Zone_Name",                each Text.AfterDelimiter([Zone], " "), type text),
    Tier     = Table.AddColumn(ZoneName, "Movement_Tier",            each if [Movement_Qty_30D] >= Params[MoveHigh] then "High" else if [Movement_Qty_30D] >= Params[MoveMedium] then "Medium" else "Low", type text),
    CostTier = Table.AddColumn(Tier,     "Cost_Tier",                each if [Unit_Cost_INR] >= Params[HighCostINR] then "High value" else "Standard", type text),
    InitOk   = Table.AddColumn(CostTier, "Initial_Matches_Confirmed", each if [Variance_Flag] = 1 and [Initial_Reason_Code] = [Confirmed_Root_Cause] then 1 else 0, Int64.Type)
in
    InitOk
