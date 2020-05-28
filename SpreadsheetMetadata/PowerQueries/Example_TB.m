let
    Source = Excel.CurrentWorkbook(){[Name="tbl_Example_TB"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"EndOfMonth", type date}, {"Account Code", type text}, {"Amount", type number}})
in
    ChangedType