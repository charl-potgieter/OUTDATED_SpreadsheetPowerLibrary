let
    Source = Excel.CurrentWorkbook(){[Name="tbl_Example_Jnls"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"EndOfMonth", type date}, {"Jnl ID", type text}, {"Account Code", type text}, {"Jnl Description", type text}, {"Jnl Amount", type number}})
in
    ChangedType