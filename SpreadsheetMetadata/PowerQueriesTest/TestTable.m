let

    tbl = Table.FromRecords({
        [Column_1 = "1", Column_2 = "", Column_3 = "", Column_4 = "", Column_5 = ""], 
        [Column_1 = "2", Column_2 = "", Column_3 = "", Column_4 = "", Column_5 = ""], 
        [Column_1 = "3", Column_2 = "", Column_3 = "", Column_4 = "", Column_5 = ""], 
        [Column_1 = "4", Column_2 = "", Column_3 = "", Column_4 = "", Column_5 = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Column_1", type text},
            {"Column_2", type text},
            {"Column_3", type text},
            {"Column_4", type text},
            {"Column_5", type text}

        })

in
    ChangedType