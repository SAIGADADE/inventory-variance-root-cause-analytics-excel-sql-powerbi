// Query name: Params   (a record, not a table; reference it as Params[MoveHigh])
// Same values as the yellow cells on the Excel 'Parameters' sheet and the risk_parameters table in sql/01.
// STATUS: written but not yet run in Power BI Desktop.
let
    Params = [
        AsOfDate     = #date(2026, 10, 1),
        W_History    = 0.30,
        W_Value      = 0.30,
        W_Movement   = 0.20,
        W_Age        = 0.20,
        MoveMedium   = 496,        // 50th percentile of Movement_Qty_30D
        MoveHigh     = 1122.6,     // 80th percentile of Movement_Qty_30D
        HighCostINR  = 300,
        BandCritical = 65,
        BandHigh     = 45,
        BandMedium   = 25
    ]
in
    Params
