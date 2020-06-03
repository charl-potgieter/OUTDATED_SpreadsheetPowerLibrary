let

    tbl = Table.FromRecords({
        [DisplayBehaviour = "Display QTD at non-qtr end point"], 
        [DisplayBehaviour = "Display YTD at non-year end point"], 
        [DisplayBehaviour = "Display QTD at max month for qtr displayed only"], 
        [DisplayBehaviour = "Display YTD for max month of year displayed only"],
        [DisplayBehaviour = "Restrict hierarchy levels"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"DisplayBehaviour", type text}

        })

in
    ChangedType