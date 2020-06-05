let

    tbl = Table.FromRecords({
        [DisplayBehaviour = "Display MTD at non-month end date", SortByCol = 1], 
        [DisplayBehaviour = "Display QTD at non-qtr end point", SortByCol = 2], 
        [DisplayBehaviour = "Display YTD at non-year end point", SortByCol = 3], 
        [DisplayBehaviour = "Display MTD at max day for month displayed only", SortByCol = 4], 
        [DisplayBehaviour = "Display QTD at max month for qtr displayed only", SortByCol = 5], 
        [DisplayBehaviour = "Display YTD for max month of year displayed only", SortByCol = 6],
        [DisplayBehaviour = "Restrict hierarchy levels", SortByCol = 7]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"DisplayBehaviour", type text}, 
            {"SortByCol", Int64.Type}

        })

in
    ChangedType