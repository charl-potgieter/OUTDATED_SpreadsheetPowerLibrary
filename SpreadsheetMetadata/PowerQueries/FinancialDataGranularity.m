let

    tbl = Table.FromRecords({
        [Granularity = "Journal level"], 
        [Granularity = "Account level"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Granularity", type text}

        })

in
    ChangedType