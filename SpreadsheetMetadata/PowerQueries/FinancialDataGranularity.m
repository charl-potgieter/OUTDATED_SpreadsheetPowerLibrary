let

    tbl = Table.FromRecords({
        [Granularity = "Journal level granularity"], 
        [Granularity = "Account level granularity"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Granularity", type text}

        })

in
    ChangedType