// Query name: SKUMaster
let
    Source   = Csv.Document(File.Contents(RepoPath & "data\raw\sku_master.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Typed    = Table.TransformColumnTypes(Promoted, {{"SKU_ID", type text}, {"Product_Name", type text}, {"Category", type text}, {"Unit_Cost_INR", type number}, {"Source", type text}}, "en-US"),
    Distinct = Table.Distinct(Typed, {"SKU_ID"})
in
    Distinct
