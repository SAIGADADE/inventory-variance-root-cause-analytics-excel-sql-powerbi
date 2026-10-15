// Query name: BinRisk   (one row per SKU-bin: the Power Query version of the Excel Bin_Risk sheet and SQL view v_priority_queue)
// Uses Table.Group, the Power Query equivalent of GROUP BY. STATUS: written but not yet run in Power BI Desktop.
let
    Source  = CountEvents,
    AsOf    = Params[AsOfDate],
    Grouped = Table.Group(Source, {"Bin"}, {
        {"SKU_ID",                 each List.Min([SKU_ID]), type text},
        {"Product_Name",           each List.Min([Product_Name]), type text},
        {"Warehouse",              each List.Min([Warehouse]), type text},
        {"Zone_Name",              each List.Min([Zone_Name]), type text},
        {"Counts",                 each Table.RowCount(_), Int64.Type},
        {"Variance_Events",        each List.Sum([Variance_Flag]), Int64.Type},
        {"Events_90D",             each Table.RowCount(Table.SelectRows(_, each [Variance_Flag] = 1 and [Count_Date] > Date.AddDays(AsOf, -90) and [Count_Date] <= AsOf)), Int64.Type},
        {"Total_Variance_Value",   each List.Sum([Variance_Value_INR]), type number},
        {"Last_Count_Date",        each List.Max([Count_Date]), type date},
        {"Movement_30D_Latest",    each Table.Max(_, "Count_Date")[Movement_Qty_30D], Int64.Type}
    }),
    AvgVal  = Table.AddColumn(Grouped, "Avg_Abs_Variance_Value", each [Total_Variance_Value] / [Counts], type number),
    DaysSince = Table.AddColumn(AvgVal, "Days_Since_Last_Count", each Duration.Days(AsOf - [Last_Count_Date]), Int64.Type),
    MoveTier = Table.AddColumn(DaysSince, "Movement_Tier", each if [Movement_30D_Latest] >= Params[MoveHigh] then "High" else if [Movement_30D_Latest] >= Params[MoveMedium] then "Medium" else "Low", type text),
    SHist   = Table.AddColumn(MoveTier, "Score_History",  each if [Events_90D] >= 3 then 100 else if [Events_90D] >= 2 then 67 else if [Events_90D] >= 1 then 33 else 0, Int64.Type),
    SValue  = Table.AddColumn(SHist,   "Score_Value",    each if [Avg_Abs_Variance_Value] >= 3000 then 100 else if [Avg_Abs_Variance_Value] >= 1000 then 67 else if [Avg_Abs_Variance_Value] >= 250 then 33 else 0, Int64.Type),
    SMove   = Table.AddColumn(SValue,  "Score_Movement", each if [Movement_Tier] = "High" then 100 else if [Movement_Tier] = "Medium" then 50 else 0, Int64.Type),
    SAge    = Table.AddColumn(SMove,   "Score_Age",      each if [Days_Since_Last_Count] >= 90 then 100 else if [Days_Since_Last_Count] >= 60 then 67 else if [Days_Since_Last_Count] >= 30 then 33 else 0, Int64.Type),
    Score   = Table.AddColumn(SAge,    "Risk_Score",     each Number.Round(Params[W_History] * [Score_History] + Params[W_Value] * [Score_Value] + Params[W_Movement] * [Score_Movement] + Params[W_Age] * [Score_Age], 1), type number),
    Band    = Table.AddColumn(Score,   "Priority",       each if [Risk_Score] >= Params[BandCritical] then "Critical" else if [Risk_Score] >= Params[BandHigh] then "High" else if [Risk_Score] >= Params[BandMedium] then "Medium" else "Low", type text),
    Sorted  = Table.Sort(Band, {{"Risk_Score", Order.Descending}, {"Total_Variance_Value", Order.Descending}, {"Bin", Order.Descending}}),
    Ranked  = Table.AddIndexColumn(Sorted, "Priority_Rank", 1, 1, Int64.Type)
in
    Ranked
