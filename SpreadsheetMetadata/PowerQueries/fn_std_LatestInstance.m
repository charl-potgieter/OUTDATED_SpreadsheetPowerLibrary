(tbl as table, id_col as text, descr_col as text, date_col as text)=>
let
    /*
        This query returns a 2 column table containing id_col and descr_col for latest available date per date_col in tbl.
        If multiple values are available at given date first item is picked.  This could be of use if multiple reports are run across 
        time where name changes for given ID and there is a need to obtain the latest description for all IDs for purposes of 
        constructing a lookup table
    */


    //Uncomment below if required for testing purposes
    /*
    tbl = Example_ClientNames,
    id_col = "Customer ID",
    descr_col = "Customer Name",
    date_col = "Date",
    */

    //Grouped by passes the table filtered by each 2nd parameter key (=id_col) to each _.  Can be witnessed by unfiltering below
    //GroupedByMaxDateTest = Table.Group(tbl, {id_col}, {{"MaxDate", each _}}),
    GroupedByMaxDate = Table.Group(tbl, {id_col}, {{"MaxDate", each List.Max(Table.Column(_, date_col)), type nullable date}}),

    //Left outer join with original data table to get items at max date only
    Join = Table.NestedJoin(GroupedByMaxDate, {id_col, "MaxDate"}, tbl, {id_col, date_col}, "NestedTbl", JoinKind.LeftOuter),

    //Pick description at latest date (if multiple pick first item)
    AddItemCol = Table.AddColumn(Join, descr_col,  each Table.Column([NestedTbl], descr_col){0}, type text),
    SelectCols = Table.SelectColumns(AddItemCol,{id_col, descr_col})
in
    SelectCols