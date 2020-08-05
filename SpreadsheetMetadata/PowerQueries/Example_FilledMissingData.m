let

  /*
    Underlying data for this query contains 3 columns, Date, Item and Amount.  The data has missing rows for certain
    dates.  This query operates on an Item basis to fill down amounts for missing dates.

    Operation is as follows:
    - Read source data 
    - Group source data by item to get the minimum and maximum dates per item
    - Use the List.Accumulate function to call an accumulator function which does the following for each item:
       - Creates a table of dates between min and max date for given item
       - Joins this with the original table containing values
       - Fill down for missing values
  */


  fn_Accumulator = 
  (state, CurrentItem) =>
  let
    MinDate = Table.SelectRows(BufferedGroupedByItems, each [Item] = CurrentItem)[MinDate]{0},
    MaxDate = Table.SelectRows(BufferedGroupedByItems, each [Item] = CurrentItem)[MaxDate]{0},
    ListDates = List.Dates(MinDate, Number.From(MaxDate - MinDate)+1, #duration(1, 0, 0, 0)),
    DateTable = Table.FromList(ListDates, Splitter.SplitByNothing(), {"Date"}),
    AddItemCol = Table.AddColumn(DateTable, "Item", each CurrentItem, type text),
    JoinwithValues = Table.NestedJoin(AddItemCol, {"Date", "Item"}, BufferedSource, {"Date", "Item"}, "tbl", JoinKind.LeftOuter),
    Expanded = Table.ExpandTableColumn(JoinwithValues, "tbl", {"Amount"}, {"Amount"}),
    SortedByDate = Table.Sort(Expanded,{{"Date", Order.Ascending}}),
    FilledDown = Table.FillDown(SortedByDate,{"Amount"}),
    ReturnValue = state & FilledDown
  in
    ReturnValue,


  Source = Excel.CurrentWorkbook(){[Name="tbl_DataToBeFilled"]}[Content],
  ChangedType = Table.TransformColumnTypes(Source,{{"Date", type date}, {"Item", type text}, {"Amount", type number}}),
  BufferedSource = Table.Buffer(ChangedType),
  GroupedByItems = Table.Group(BufferedSource, {"Item"}, {{"MinDate", each List.Min([Date]), type date}, {"MaxDate", each List.Max([Date]), type date}}),
  BufferedGroupedByItems = Table.Buffer(GroupedByItems),
  DistinctItemList = List.Distinct(BufferedSource[Item]),
  EmptyTable = #table({},{}),
  Return = List.Accumulate(DistinctItemList, EmptyTable, fn_Accumulator),
    ChangedType2 = Table.TransformColumnTypes(Return,{{"Date", type date}, {"Item", type text}, {"Amount", type number}})


in
  ChangedType2