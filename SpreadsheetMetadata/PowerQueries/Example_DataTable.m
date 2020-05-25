let

    tbl = Table.FromRecords({
        [Date = "42400", Description = "blah", SubCategory = "A", Amount = "1234"], 
        [Date = "42794", Description = "hello", SubCategory = "A", Amount = "100"], 
        [Date = "42400", Description = "blah", SubCategory = "A", Amount = "13334"], 
        [Date = "43220", Description = "hello", SubCategory = "B", Amount = "1550"], 
        [Date = "42400", Description = "zzzz", SubCategory = "A", Amount = "1034"], 
        [Date = "42794", Description = "hello", SubCategory = "A", Amount = "1500"], 
        [Date = "42400", Description = "zzzz", SubCategory = "A", Amount = "1734"], 
        [Date = "43220", Description = "hello", SubCategory = "B", Amount = "10"], 
        [Date = "43705", Description = "blah", SubCategory = "B", Amount = "1454"], 
        [Date = "43982", Description = "hello", SubCategory = "B", Amount = "1560"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Date", type text},
            {"Description", type text},
            {"SubCategory", type text},
            {"Amount", type number}

        })

in
    ChangedType