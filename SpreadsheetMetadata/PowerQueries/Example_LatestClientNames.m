let
    Source = Excel.CurrentWorkbook(){[Name="tbl_ClientNames"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"Date", type date}, {"Customer ID", type text}, {"Customer Name", type text}})
in
    ChangedType