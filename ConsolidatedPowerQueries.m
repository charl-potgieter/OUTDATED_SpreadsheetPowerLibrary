[fn_std_DateTable = let


    // -----------------------------------------------------------------------------------------------------------------------------------------
    //                      Documentation
    // -----------------------------------------------------------------------------------------------------------------------------------------
    
    Documentation_ = [
        Documentation.Name =  " fn_std_DateTable", 
        Documentation.Description = " Creates a standard date table." , 
        Documentation.LongDescription = " Creates a standard date table.", 
        Documentation.Category = " Table", 
        Documentation.Source = " tba", 
        Documentation.Author = " Charl Potgieter"
        ],


    // -----------------------------------------------------------------------------------------------------------------------------------------
    //                      Function code
    // -----------------------------------------------------------------------------------------------------------------------------------------

    fn_ = (DateFrom as date, DateTo as date)=>
    let
        
        // For debugging
        //DateFrom = #date(2016,5,4),
        //DateTo = #date(2017,8,15),

        // Get daylist
        YearStart = Date.StartOfYear(DateFrom),
        YearEnd = Date.EndOfYear(DateTo),
        DayCount = Duration.Days(YearEnd - YearStart) +1,
        DayList =  List.Dates(YearStart, DayCount, #duration(1,0,0,0)),
        DayTable = Table.FromList(DayList, Splitter.SplitByNothing()),
        RenamedCols = Table.RenameColumns(DayTable, {"Column1", "Date"}),
        ChangedType = Table.TransformColumnTypes(RenamedCols, {{"Date", type date}}),

        //Insert year, qtr, month, day number
        InsertYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date]), Int64.Type),
        InsertQuarter = Table.AddColumn(InsertYear, "QuarterOfYear", each Date.QuarterOfYear([Date]), Int64.Type),
        InsertMonth = Table.AddColumn(InsertQuarter, "MonthOfYear", each Date.Month([Date]), Int64.Type),
        InsertDay = Table.AddColumn(InsertMonth, "DayOfMonth", each Date.Day([Date]), Int64.Type),

        //Insert end of Periods
        InsertEndOfYear = Table.AddColumn(InsertDay, "EndOfYear", each Date.EndOfYear([Date]), type date),
        InsertEndOfQtr = Table.AddColumn(InsertEndOfYear, "EndOfQtr", each Date.EndOfQuarter([Date]), type date),
        InsertEndOfMonth = Table.AddColumn(InsertEndOfQtr, "EndOfMonth", each Date.EndOfMonth([Date]), type date),
        InsertEndOfWeek = Table.AddColumn(InsertEndOfMonth, "EndOfWeek", each Date.EndOfWeek([Date]), type date),
        
        //Inset tests for end of periods
        InsertIsYearEnd = Table.AddColumn(InsertEndOfWeek, "IsEndOfYear", each [Date] = [EndOfYear], type logical),
        InsertIsQtrEnd = Table.AddColumn(InsertIsYearEnd, "IsEndOfQtr", each [Date] = [EndOfQtr], type logical),
        InsertIsMonthEnd = Table.AddColumn(InsertIsQtrEnd, "IsEndOfMonth", each [Date] = [EndOfMonth], type logical),
        InsertIsWeekEnd = Table.AddColumn(InsertIsMonthEnd, "IsEndOfWeek", each [Date] = [EndOfWeek], type logical),


        //Insert sundry fields
        InsertDateInt = Table.AddColumn(InsertIsWeekEnd, "DateInt", each ([Year] * 10000 + [MonthOfYear] * 100 + [DayOfMonth]), Int64.Type),
        InsertMonthName = Table.AddColumn(InsertDateInt, "MonthName", each Date.ToText([Date], "MMMM"), type text),
        InsertDayName = Table.AddColumn(InsertMonthName, "DayName", each Date.ToText([Date], "dddd"), type text),
        InsertCalendarMonth = Table.AddColumn(InsertDayName, "MonthInCalender", each (try(Text.Range([MonthName], 0, 3)) otherwise [MonthName]) & "-" & Text.End(Number.ToText([Year]), 2), type text),
        InsertCalendarQtr = Table.AddColumn(InsertCalendarMonth, "QuarterInCalendar", each "Q" & Number.ToText([QuarterOfYear]) &" " & Number.ToText([Year]), type text),
        InsertDayInWeek = Table.AddColumn(InsertCalendarQtr, "DayInWeek", each Date.DayOfWeek([Date]), Int64.Type)

    in
        InsertDayInWeek,


// -----------------------------------------------------------------------------------------------------------------------------------------
//                      Output
// -----------------------------------------------------------------------------------------------------------------------------------------

    type_ = type function (
        DateFrom as (type date),
        DateTo as (type date)
        )
        as table meta Documentation_,

    // Replace the extisting type of the function with the individually defined
    Result =  Value.ReplaceType(fn_, type_)
 
 in 
    Result,fn_std_ConsolidatedFilesInFolder = (
    FolderPath as text, 
    fn_SingleFile as function, 
    LoadData as logical,
    optional fn_FilterBasedOnFileName as function,
    optional FilterFromValue,
    optional FilterToValue,
    optional Additional_fn_SingleFileParameter as text      // utilsed for example to specify specific sheet name or table in fn_SingleFile
)=>
let

    // Get folder contents and filter out Readme, .sql and temporary files starting with tildas
    FolderContents = Folder.Files(FolderPath),
    FilteredOutReadMeAndSQL = Table.SelectRows(FolderContents, each (Text.Upper([Name]) <> "README.TXT") and (Text.Upper([Extension]) <> ".SQL")),
    FilteredOutTildas = Table.SelectRows(FilteredOutReadMeAndSQL, each Text.Start([Name], 1) <> "~"),

    //Restrict to one file if no data load
    ReturnOnlyIfLoadRequested = if LoadData then FilteredOutTildas else Table.FirstN(FilteredOutTildas, 1),

    //Filter Files based on filter function
    FilteredFile = if (fn_FilterBasedOnFileName <> null and Table.RowCount(ReturnOnlyIfLoadRequested) > 1 ) then
        Table.SelectRows(ReturnOnlyIfLoadRequested, each fn_FilterBasedOnFileName([Name], FilterFromValue, FilterToValue))
    else
        ReturnOnlyIfLoadRequested,

    // Add single file tables, remove excess columns and expand
    AddTableCol = if Additional_fn_SingleFileParameter = null then
            Table.AddColumn(FilteredFile, "tbl", each fn_SingleFile([Folder Path], [Name]))
        else
            Table.AddColumn(FilteredFile, "tbl", each fn_SingleFile([Folder Path], [Name], Additional_fn_SingleFileParameter)),
    RemoveCols = Table.RemoveColumns(AddTableCol, {"Content", "Extension", "Date accessed", "Date modified", "Date created", "Attributes"}),
    Expanded = Table.ExpandTableColumn(RemoveCols, "tbl", Table.ColumnNames(AddTableCol[tbl]{0})),

    // Filter at a data row level if required
    ReturnOnlyOneDataRowIfRequired = if LoadData then Expanded else Table.FirstN(Expanded, 1)

in
    ReturnOnlyOneDataRowIfRequired,fn_std_DatesBetween = // ****************************************************************************************
// Credit for below codes = Imke Feldman Imke Feldmann: www.TheBIccountant.com
// ****************************************************************************************


let 
// ----------------------- Documentation ----------------------- 

    documentation_ = [
        Documentation.Name =  " Dates.DatesBetween", 
        Documentation.Description = " Creates a list of dates according to the chosen interval between Start and End. Allowed values for 3rd parameter: ""Year"", ""Quarter"", ""Month"", ""Week"" or ""Day""." , 
        Documentation.LongDescription = " Creates a list of dates according to the chosen interval between Start and End. The dates created will always be at the end of the interval, so could be in the future if today is chosen.", 
        Documentation.Category = " Table", 
        Documentation.Source = " http://www.thebiccountant.com/2017/12/11/date-datesbetween-retrieve-dates-between-2-dates-power-bi-power-query/ . ", 
        Documentation.Author = " Imke Feldmann: www.TheBIccountant.com . ", 
        Documentation.Examples = {[Description =  " Check this blogpost: http://www.thebiccountant.com/2017/12/11/date-datesbetween-retrieve-dates-between-2-dates-power-bi-power-query/ ." , 
            Code = "", 
            Result = ""]}
        ],

    // ----------------------- Function Code ----------------------- 
    
    function_ =  (From as date, To as date, optional Selection as text ) =>
    let

        // Create default-value "Day" if no selection for the 3rd parameter has been made
        TimeInterval = if Selection = null then "Day" else Selection,

        // Table with different values for each case
        CaseFunctions = #table({"Case", "LastDateInTI", "TypeOfAddedTI", "NumberOfAddedTIs"},
                {   {"Day", Date.From, Date.AddDays, Number.From(To-From)+1},
                    {"Week", Date.EndOfWeek, Date.AddWeeks, Number.RoundUp((Number.From(To-From)+1)/7)},
                    {"Month", Date.EndOfMonth, Date.AddMonths, (Date.Year(To)*12+Date.Month(To))-(Date.Year(From)*12+Date.Month(From))+1},
                    {"Quarter", Date.EndOfQuarter, Date.AddQuarters, (Date.Year(To)*4+Date.QuarterOfYear(To))-(Date.Year(From)*4+Date.QuarterOfYear(From))+1},
                    {"Year", Date.EndOfYear, Date.AddYears,Date.Year(To)-Date.Year(From)+1} 
                } ),

        // Filter table on selected case
        Case = CaseFunctions{[Case = TimeInterval]},
        
        // Create list with dates: List with number of date intervals -> Add number of intervals to From-parameter -> shift dates at the end of each respective interval	
        DateFunction = List.Transform({0..Case[NumberOfAddedTIs]-1}, each Function.Invoke(Case[LastDateInTI], {Function.Invoke(Case[TypeOfAddedTI], {From, _})}))
    in
        DateFunction,

    // ----------------------- New Function Type ----------------------- 

    type_ = type function (
        From as (type date),
        To as (type date),
        optional Selection as (type text meta [
                                Documentation.FieldCaption = "Select Date Interval",
                                Documentation.FieldDescription = "Select Date Interval, if nothing selected, the default value will be ""Day""",
                                Documentation.AllowedValues = {"Day", "Week", "Month", "Quarter", "Year"}
                                ])
            )
        as table meta documentation_,

    // Replace the extisting type of the function with the individually defined
    Result =  Value.ReplaceType(function_, type_)
 
 in 

Result,fn_std_FileNameIsInDateRangeYYYY = /*---------------------------------------------------------------------------------
    Checks wheter file name is inside date range where file name starts with YYYY
---------------------------------------------------------------------------------*/

(FileName as text, YearStart as number, YearEnd as number) =>
let
    YearFromFileName = Number.From(Text.Start(FileName, 4)),
    IsInRange = (YearFromFileName >= YearStart) and (YearFromFileName <= YearEnd)    
in
    IsInRange,fn_std_FileNameIsInDateRangeYYYYMM = /*---------------------------------------------------------------------------------
    Checks wheter file name is inside date range where file name starts with YYYYMM
---------------------------------------------------------------------------------*/

(FileName as text, DateStart as date, DateEnd as date) =>
let
    YearFromFileName = Number.From(Text.Start(FileName, 4)),
    MonthFromFileName = Number.From(Text.Range(FileName, 4, 2)),
    MonthEndFromFileName = Date.EndOfMonth(#date(YearFromFileName, MonthFromFileName, 1)),
    IsInRange = (MonthEndFromFileName >= DateStart) and (MonthEndFromFileName <= DateEnd)    
in
    IsInRange,fn_std_MonthEndFromYYYYMM = (TextToConvert as text)=>
let
    MonthStart = #date(Number.From(Text.Start(TextToConvert, 4)), Number.From(Text.Range(TextToConvert, 4, 2)), 1),
    MonthEnd = Date.EndOfMonth(MonthStart)
in
    MonthEnd,fn_std_Single_TabularDataFirstSheet = (FolderPath as text, FileName as text)=>
let
    tbl = Excel.Workbook(File.Contents(FolderPath & FileName), true, null)[Data]{0}
in
    tbl,fn_std_Single_OnlyTableInSpreadsheet = (FolderPath as text, FileName as text) =>
let
    Source = Excel.Workbook(File.Contents(FolderPath & FileName), null, true),
    tbl = Table.SelectRows(Source, each [Kind] = "Table")[Data]{0}
in
    tbl,fn_std_Single_TabularDataNamedSheet = (FolderPath as text, FileName as text, SheetName as text)=>
let
    Source = Excel.Workbook(File.Contents(FolderPath & FileName), true, null),
    shts = Table.SelectRows(Source, each [Kind] = "Sheet"),
    tbl = Table.SelectRows(shts, each [Name] = SheetName)[Data]{0}
in
    tbl,fn_std_Single_NamedTable = (FolderPath as text, FileName as text, TableName as text)=>
let
    Source = Excel.Workbook(File.Contents(FolderPath & FileName), true, null),
    tbls = Table.SelectRows(Source, each [Kind] = "Table"),
    tbl = Table.SelectRows(tbls, each [Name] = TableName)[Data]{0}
in
    tbl,fn_std_Single_PipeDelimitedText = (FolderPath as text, FileName as text)=>
let
    Source = Csv.Document(File.Contents(FolderPath & FileName),[Delimiter="|", Encoding=1252, QuoteStyle=QuoteStyle.None]),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true])
in
    PromotedHeaders,template_fn_std_DataAccess = //Uncomment parameter once debugging complete
//(LoadData as logical)=>
let

    //Delete this once parameter is uncommented.
    LoadData  = true,

    DateStart = param_DateStart,
    DateEnd = param_DateEnd,

    YearStart = Date.Year(DateStart),
    YearEnd = Date.Year(DateEnd),

    FolderPath = "XXXXXX"
    

    // **** Uncomment one of the below options and change the last line of file  to read tblRaw***

    //No filter
    //tblRaw = fn_std_ConsolidatedFilesInFolder(FolderPath, fn_Single_XXXXX, LoadData, null, null, null, XXX_optional_sheet_or_table_name)

    //Filter files on year name
    // tblRaw = fn_std_ConsolidatedFilesInFolder(FolderPath, fn_Single_XXXXX, LoadData, fn_std_FileNameIsInDateRangeYYYY, YearStart, YearEnd, XXX_optional_sheet_or_table_name)

    //Filter files on month name 
    //tblRaw = fn_std_ConsolidatedFilesInFolder(FolderPath, fn_Single_XXXXX, LoadData, fn_std_FileNameIsInDateRangeYYYYMM, DateStart, DateEnd, XXX_optional_sheet_or_table_name)

in
    FolderPath,Example_LookupTable = let

    tbl = Table.FromRecords({
        [Primary Key = "blah", Full Description = "This is blah"], 
        [Primary Key = "hello", Full Description = "This is hello"], 
        [Primary Key = "zzzz", Full Description = "This is zzzz"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Primary Key", type text},
            {"Full Description", type text}

        })

in
    ChangedType,Example_DataTable = let

    tbl = Table.FromRecords({
        [Date = "42400", Foreign Key = "blah", SubCategory = "A", Amount = "1234"], 
        [Date = "42794", Foreign Key = "hello", SubCategory = "A", Amount = "100"], 
        [Date = "42400", Foreign Key = "blah b", SubCategory = "A", Amount = "13334"], 
        [Date = "43220", Foreign Key = "hello", SubCategory = "B", Amount = "1550"], 
        [Date = "42400", Foreign Key = "zzzz", SubCategory = "A", Amount = "1034"], 
        [Date = "42794", Foreign Key = "hello", SubCategory = "A", Amount = "1500"], 
        [Date = "42400", Foreign Key = "zzzz", SubCategory = "A", Amount = "1734"], 
        [Date = "43220", Foreign Key = "hello b", SubCategory = "B", Amount = "10"], 
        [Date = "43705", Foreign Key = "blah", SubCategory = "B", Amount = "1454"], 
        [Date = "43982", Foreign Key = "hello", SubCategory = "B", Amount = "1560"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Date", type text},
            {"Foreign Key", type text},
            {"SubCategory", type text},
            {"Amount", type number}

        })

in
    ChangedType,Example_TB = let
    Source = Excel.CurrentWorkbook(){[Name="tbl_Example_TB"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"EndOfMonth", type date}, {"Account Code", type text}, {"Amount", type number}})
in
    ChangedType,Example_Jnls = let
    Source = Excel.CurrentWorkbook(){[Name="tbl_Example_Jnls"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"EndOfMonth", type date}, {"Jnl ID", type text}, {"Account Code", type text}, {"Jnl Description", type text}, {"Jnl Amount", type number}})
in
    ChangedType,Example_ChartOfAccounts = let
    Source = Excel.CurrentWorkbook(){[Name="tbl_Example_ChartOfAccounts"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"Account Code", type text}, {"Account Description", type text}, {"Account Code and Description", type text}, {"Account Category 1", type text}, {"Account Category 2", type text}, {"Account Category 3", type text}, {"Account Category 4", type text}, {"Account Category 5", type text}, {"Sort Order Account Category 1", Int64.Type}, {"Sort Order Account Category 2", Int64.Type}, {"Sort Order Account Category 3", Int64.Type}, {"Sort Order Account Category 4", Int64.Type}, {"Sort Order Account Category 5", Int64.Type}})
in
    ChangedType,DateTable = fn_std_DateTable(param_DateStart, param_DateEnd),Temp_SimpleRowAppend = let
    tbl = #table(
                type table
                    [
                        #"Date"=date, 
                        #"Description"=text,
                        #"SubCategory"=text,
                        #"Amount"=number
                    ], 
                {
                {#date(2016,1,31), "blah","A", 1234}
                }
                ),

    acc= List.Accumulate({1..10}, tbl, (state, current)=> Table.Combine({state, tbl}))
in
    acc,Temp_IncrementPrevious = let
    tbl = Table.FromRecords({[
                            Date = #date(2016,1,31),
                            Description = "blah",
                            SubCategory = "A",
                            Amount = 1234
                            ]}),

    fn = (state, current) =>
    let
        PreviousTableRowAsRecord = Table.Last(state),

        NewRow = Table.FromRecords({[
                                    Date = PreviousTableRowAsRecord[Date], 
                                    Description = PreviousTableRowAsRecord[Description], 
                                    SubCategory = PreviousTableRowAsRecord[SubCategory], 
                                    Amount = PreviousTableRowAsRecord[Amount] + 1
                                    ]}),


        // AppendRow = Table.FromRecords({Table.Last(state)}),
        Output = Table.Combine({state, NewRow})

    in
        Output,

    acc= List.Accumulate({1..10}, tbl, fn)
in
    acc,param_DateStart = #date(2018, 1, 1) meta [IsParameterQuery=true, Type="Date", IsParameterQueryRequired=true],param_DateEnd = #date(2020, 12, 31) meta [IsParameterQuery=true, Type="Date", IsParameterQueryRequired=true],Measures_ErrorChecks = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,Measures_Sundry = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,Measures_TimeCalcs = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,Measures_Journals = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,Measures_TrialBalance = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,Measures_PandL = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,fn_std_Parameters = let


    // -----------------------------------------------------------------------------------------------------------------------------------------
    //                      Documentation
    // -----------------------------------------------------------------------------------------------------------------------------------------
    
    Documentation_ = [
        Documentation.Name =  " fn_std_Parameters", 
        Documentation.Description = " Returns parameter value set out in  tbl_Parameters" , 
        Documentation.LongDescription = "  Returns parameter value set out in  tbl_Parameters", 
        Documentation.Category = "Text",  
        Documentation.Author = " Charl Potgieter"
        ],


    // -----------------------------------------------------------------------------------------------------------------------------------------
    //                      Function code
    // -----------------------------------------------------------------------------------------------------------------------------------------

    fn_=
    (parameter as text)=>
    let
        Source = Excel.CurrentWorkbook(){[Name = "tbl_Parameters"]}[Content],
        FilteredRows = Table.SelectRows(Source, each [Parameter] = parameter),
        ReturnValue = FilteredRows[Value]{0}
    in
        ReturnValue,




// -----------------------------------------------------------------------------------------------------------------------------------------
//                      Output
// -----------------------------------------------------------------------------------------------------------------------------------------

    type_ = type function (
        parameter as (type text)
        )
        as text meta Documentation_,

    // Replace the extisting type of the function with the individually defined
    Result =  Value.ReplaceType(fn_, type_)
 
 in 
    Result,fn_std_LatestInstance = (tbl as table, id_col as text, descr_col as text, date_col as text)=>
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
    SelectCols,NumberScale = let

    tbl = Table.FromRecords({
        [ShowValuesAs = "CCY", DivideBy = "1"], 
        [ShowValuesAs = "'000", DivideBy = "1000"], 
        [ShowValuesAs = "m", DivideBy = "1000000"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"ShowValuesAs", type text},
            {"DivideBy", type number}

        })

in
    ChangedType,TimePeriods = let

    tbl = Table.FromRecords({
        [Time Period = "MTD", Time Period Sort By Col = "1"], 
        [Time Period = "QTD", Time Period Sort By Col = "2"], 
        [Time Period = "YTD", Time Period Sort By Col = "3"], 
        [Time Period = "PY", Time Period Sort By Col = "4"], 
        [Time Period = "Total", Time Period Sort By Col = "5"], 
        [Time Period = "As at date", Time Period Sort By Col = "6"],
        [Time Period = "As at month end", Time Period Sort By Col = "7"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"Time Period", type text},
            {"Time Period Sort By Col", Int64.Type}

        })

in
    ChangedType,CalculationSource = let

    tbl = Table.FromRecords({
        [CalcSource = "TB"], 
        [CalcSource = "Journals"]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"CalcSource", type text}

        })

in
    ChangedType,Measures_BS = let

    tbl = Table.FromRecords({
        [NullHeader = ""]
        }), 

    ChangedType = Table.TransformColumnTypes(
       tbl, 
        {
            {"NullHeader", type text}

        })

in
    ChangedType,Example_FilledMissingData = let

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
  ChangedType2,Example_LatestClientNames = let
    Source = Excel.CurrentWorkbook(){[Name="tbl_ClientNames"]}[Content],
    ChangedType = Table.TransformColumnTypes(Source,{{"Date", type date}, {"Customer ID", type text}, {"Customer Name", type text}})
in
    ChangedType,Example_CallLatestInstance = let
    Source = fn_std_LatestInstance(Example_LatestClientNames, "Customer ID", "Customer Name", "Date")
in
    Source,fn_StraightLineAmortisationTable = let

    //Uncomment for debugging purposes
    OpeningBalance = 500000,
    AmortisationRatePerYear = 0.2,
    StartDate = #date(2019,1,1),

    NumberOfMonths = (1 / AmortisationRatePerYear) * 12,

    IndexList = {1..NumberOfMonths},
    ConvertToTable = Table.FromList(IndexList, Splitter.SplitByNothing(), {"Index"}),
    ChangedIndexType = Table.TransformColumnTypes(ConvertToTable,{{"Index", Int64.Type}}),
    AddEndOfMonth = Table.AddColumn(ChangedIndexType, "End Of Month", each Date.EndOfMonth(Date.AddMonths(StartDate, [Index]-1)), type date),
    AddOpeningBalance = Table.AddColumn(AddEndOfMonth, "Opening Balance", each (NumberOfMonths - ([Index]-1)) / NumberOfMonths * OpeningBalance, type number),
    AddAmortisation = Table.AddColumn(AddOpeningBalance, "Amortisation", each OpeningBalance / NumberOfMonths, type number),
    AddClosingBalance = Table.AddColumn(AddAmortisation, "Closing Balance", each [Opening Balance] - [Amortisation], type number),
    DeleteIndex = Table.RemoveColumns(AddClosingBalance,{"Index"})
in
    DeleteIndex,fn_ConvertAllColumnsToText = (tbl)=>
let
    ConversionList = List.Transform(Table.ColumnNames(tbl), each {_, type text}),
    Converted = Table.TransformColumnTypes(tbl, ConversionList)
in
    Converted]