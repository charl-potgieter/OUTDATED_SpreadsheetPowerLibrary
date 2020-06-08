let

    tbl = Table.FromRecords({
        [PandL_CalcSource = "TB"], 
        [PandL_CalcSource = "Journals"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"PandL_CalcSource", type text}

        })

in
    ChangedType