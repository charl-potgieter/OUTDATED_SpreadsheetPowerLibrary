let
    Source = Excel.CurrentWorkbook(){[Name="tbl_Example_ChartOfAccounts"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"Account Code", type text}, {"Account Description", type text}, {"Account Code and Description", type text}, {"Account Category 1", type text}, {"Account Category 2", type text}, {"Account Category 3", type text}, {"Account Category 4", type text}, {"Account Category 5", type text}})
in
    ChangedType