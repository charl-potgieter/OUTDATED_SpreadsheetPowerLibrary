let

    tbl = Table.FromRecords({
        [Data Type = "Balance Sheet", Time Class = "Point in time", Calculation method = "Point in time", Default = false], 
        [Data Type = "Journals", Time Class = "Time Period", Calculation method = "Sum of transactions", Default = false], 
        [Data Type = "P&L (from tb)", Time Class = "Time Period", Calculation method = "Difference between points in time", Default = true], 
        [Data Type = "P&L (from jnls)", Time Class = "Time Period", Calculation method = "Sum of transactions", Default = false], 
        [Data Type = "Trial Balance", Time Class = "Point in time", Calculation method = "Point in time", Default = false]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Data Type", type text},
            {"Time Class", type text},  
            {"Calculation method", type text},  
            {"Default", type logical}

        }),
    SortRows = Table.Sort(ChangedType,{{"Data Type", Order.Ascending}})

in
    SortRows