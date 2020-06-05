let

    tbl = Table.FromRecords({
        [Data Type = "Balance Sheet", Time Class = "Point in time", Calculation method = "Point in time", Minimum time granularity = "Date", Default = false], 
        [Data Type = "Journals", Time Class = "Time period", Calculation method = "Sum of transactions", Minimum time granularity = "Month", Default = false], 
        [Data Type = "P&L (from tb)", Time Class = "Time period", Calculation method = "Difference between points in time", Minimum time granularity = "Month", Default = true], 
        [Data Type = "P&L (from jnls)", Time Class = "Time Period", Calculation method = "Sum of transactions", Minimum time granularity = "Month", Default = false], 
        [Data Type = "Trial Balance", Time Class = "Point in time", Calculation method = "Point in time", Minimum time granularity = "Date", Default = false],
        [Data Type = "Customer Count", Time Class = "Time period", Calculation method = "Sum of transactions", Minimum time granularity = "Date", Default = false]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Data Type", type text},
            {"Time Class", type text},  
            {"Calculation method", type text},
            {"Minimum time granularity", type text},
            {"Default", type logical}

        }),
    SortRows = Table.Sort(ChangedType,{{"Data Type", Order.Ascending}})

in
    SortRows