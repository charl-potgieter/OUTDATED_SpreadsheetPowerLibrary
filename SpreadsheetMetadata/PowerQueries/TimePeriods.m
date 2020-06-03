let

    tbl = Table.FromRecords({
        [Time Period = "MTD", Time Period Sort By Col = "1"], 
        [Time Period = "QTD", Time Period Sort By Col = "2"], 
        [Time Period = "YTD", Time Period Sort By Col = "3"], 
        [Time Period = "PY", Time Period Sort By Col = "4"], 
        [Time Period = "Total", Time Period Sort By Col = "5"], 
        [Time Period = "Point in time", Time Period Sort By Col = "6"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Time Period", type text},
            {"Time Period Sort By Col", Int64.Type}

        })

in
    ChangedType