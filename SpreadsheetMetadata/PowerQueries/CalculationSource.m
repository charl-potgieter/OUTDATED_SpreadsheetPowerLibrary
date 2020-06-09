let

    tbl = Table.FromRecords({
        [CalcSource = "TB"], 
        [CalcSource = "Journals"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"CalcSource", type text}

        })

in
    ChangedType