;;; -*- lexical-binding: t; byte-compile-warnings: (not docstrings docstrings-wide) -*-

;;; ===
;;; =========================
;;; ===== PowerLanguage =====
;;; =========================

(my-init--with-duration-measured-section
 t
 "PowerLanguage"

 ;; PowerLanguage mode
 ;; PowerLanguage is the Multicharts dialect of Easy Language.
 ;; Tied to .pwl files. Self-contained: no dependency on a separate
 ;; Easy Language base mode (the EL keyword set is bundled below).

 (setq powerlanguage--keywords
       '(;;
         ;; logic
         "AND" "OR"
         ;;
         ;; crosses
         "crosses above" "crosses over"
         "crosses below" "crosses under"
         ;;
         ;; declarations
         "Inputs" "Input"
         "Variables" "Variable" "Vars" "Var"
         "Arrays" "Array"
         ;;
         ;; special
         "IntraBarPersist"
         ;;
         ;; control structures
         "If" "Then" "Else"
         "Begin" "End"
         "Once"
         "switch" "default" "case"
         "for" "to" "downto"
         "while"
         "repeat" "until"
         ;;
         ;; trading
         "Buy" "SellShort" "Sell" "BuyToCover"
         "Cancel"
         "Market"
         "Stop" "Limit"
         "next" "this" "bar"
         "shares" "contracts"
         "SetStopLoss"
         "SetProfitTarget"
         "SetBreakEven"
         "SetDollarTrailing"
         "SetPercentTrailing"
         "SetStopPosition" "SetStopShare" "SetStopContract"
         "SetRouteName" "SetShowOnly" "SetPeg"
         ;;
         ;; skip words
         "on" "at" "of" "than" "from" "an" "the" "is"
         ;;
         ;; for functions
         "numeric" "numericseries" "numericsimple" "NumericRef"
         "TrueFalse" "truefalsesimple" "truefalseseries" "TrueFalseRef"
         "string" "stringsimple" "stringseries" "StringRef"
         "NumericArray" "NumericArrayRef"
         "TrueFalseArray" "TrueFalseArrayRef"
         "StringArray" "StringArrayRef"))

 (setq powerlanguage--types '("tobefilled12345"))

 (setq powerlanguage--constants
       '(;;
         ;; booleans
         "TRUE" "FALSE"
         ;;
         ;; meta
         "Symbol"
         "BarType" "BarInterval" "CurrentBar" "BarNumber" "BarStatus" "IntradayBarNumber"
         "MaxBarsBack"
         "SessionStartTime" "SessionEndTime"
         "BigPointValue" "PriceScale" "MinMove"
         ;;
         ;; bar
         "Close" "C" "High" "H" "Low" "L" "Open" "O"
         "Volume" "V"
         "Date" "D" "Time" "T"
         "CurrentDate" "CurrentTime"
         ;;
         ;; quote fields
         "High52Wk" "Low52Wk"
         "VWAP"
         ;;
         ;; strings
         "Newline"
         ;;
         ;; colors
         "Black" "Blue" "Cyan" "Green" "Magenta" "Red" "Yellow" "White"
         "DarkBlue" "DarkCyan" "DarkGreen" "DarkMagenta" "DarkRed"
         "DarkBrown" "DarkGray" "LightGray"
         ;;
         ;; weekdays
         "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"
         ;;
         ;; program start
         "LegacyColorValue"
         "IntrabarOrderGeneration"
         "InfiniteLoopDetection"
         ;;
         ;; built-in variables
         "Condition0" "Condition1" "Condition2" "Condition3" "Condition4" "Condition5"
         "Condition6" "Condition7" "Condition8" "Condition9" "Condition10"
         "DisplayName"
         "ToolTip"
         "Value0" "Value1" "Value2" "Value3" "Value4" "Value5"
         "Value6" "Value7" "Value8" "Value9" "Value10"
         ;;
         ;; alerts
         "AlertEnabled" "CheckAlert"
         ;;
         ;; commentary
         "AtCommentaryBar" "CommentaryEnabled"
         ;;
         ;; other
         "LastBarOnChart"
         "Printer"
         ;;
         ;; trade tracking
         "MarketPosition"
         "BarsSinceEntry"
         "AvgEntryPrice"
         "BarsSinceExit"
         "CurrentShares"
         "CurrentContracts"
         "EntryName" "EntryDate" "EntryTime"
         "ExitName" "ExitDate" "ExitTime"
         ;;
         ;; strategy performance tracking
         "NetProfit"
         "OpenPositionProfit"
         "GrossProfit"
         "GrossLoss"
         "NumWinTrades"
         "NumLosTrades"
         "PercentProfit"
         "TotalTrades"
         ;;
         ;; GetAppInfo values
         "aiApplicationType"
         "aiOptimizing"
         "aiOptionStationPane"
         "aiSpaceToRight"
         "aiPercentChange"
         "aiStrategyAuto"
         "aiStrategyAutoConf"
         "aiIntrabarOrder"
         "aiRealTimeCalc"))

 (setq powerlanguage--events '("tobefilled12345"))

 (setq powerlanguage--functions
       '(;;
         ;; plotting
         "Plot1" "Plot2" "Plot3" "Plot4" "Plot5"
         "SetPlotColor"
         "SetPlotBGColor"
         "SetPlotWidth"
         "PlotPB"
         "NoPlot"
         ;;
         ;; colors
         "RGB" "GradientColor"
         ;;
         ;; log & file & commentary
         "Print"
         "File" "FileAppend" "FileDelete"
         "Commentary"
         ;;
         ;; alerts
         "Alert"
         ;;
         ;; numeric
         "absvalue"
         "squareroot"
         "expvalue" "log"
         "sine" "cosine"
         "Tangent" "ArcTangent" "ArcSine" "ArcCosine"
         "maxlist" "minlist"
         "Sign" "Round" "IntPortion" "FracPortion" "Floor" "Ceiling"
         "Power" "Mod"
         "Random" "IsNullKeyword"
         ;;
         ;; date / time
         "CalcDate" "CalcTime"
         "DateToJulian" "JulianToDate"
         "TimeToMinutes" "MinutesToTime"
         "DayOfMonth" "DayOfWeek" "Month" "Year"
         ;;
         ;; string
         "NumToStr" "StrToNum" "Spaces"
         "LeftStr" "RightStr" "MidStr"
         "StrLen" "InStr"
         "UpperStr" "LowerStr"
         "StrAfter" "StrBefore"
         ;;
         ;; arrays
         "SummationArray" "SortArray" "AverageArray"
         "Sort2DArray" "HighestArray" "LowestArray"
         "Array_SetMaxIndex"
         "Array_Sum" "Array_Sort" "Array_Compare" "Array_Copy"
         ;;
         ;; time series
         "Highest" "HighestBar"
         "Lowest" "LowestBar"
         "Summation"
         "XAverage"
         "StdDev" "Variance" "Correlation" "Median"
         "LinearRegValue" "LinearRegSlope" "LinearRegAngle"
         "RateOfChange" "MidPoint"
         "TrueHigh" "TrueLow" "TrueRange" "AvgTrueRange"
         "Pivot" "PivotHighVS" "PivotLowVS"
         "CountIF"
         ;;
         ;; technical analysis indicators
         "Average"
         "ADX"
         "Aroon"
         "BollingerBand"
         "CCI"
         "ChaikinOsc"
         "Divergence"
         "DMI"
         "DonchianChannel"
         "KeltnerChannel"
         "MACD"
         "Momentum"
         "MoneyFlow"
         "OnBalanceVolume"
         "ParabolicSAR"
         "RSI"
         "Stochastic" "SlowK" "SlowD" "FastK" "FastD"
         "WilliamsR"
         "AvgPrice" "MedianPrice" "TypicalPrice" "WeightedClose"
         ;;
         ;; account info
         "GetAccountID"
         "GetBDAccountNetWorth"
         "GetRTAccountNetWorth"
         "GetRTDayTradingBuyingPower"
         "GetRTPurchasingPower"
         "GetAccountStatus"
         "GetBDCashBalance"
         "GetBDAccountEquity"
         "GetRTCashBalance"
         "GetRTAccountEquity"
         ;;
         ;; open positions info
         "GetPositionQuantity"
         "GetPositionAveragePrice"
         "GetPositionOpenPL"
         "GetNumPositions"
         "GetPositionsSymbol"
         ;;
         ;; drawings / text
         "Text_New"
         "Text_SetLocation"
         "Text_Delete"
         "Text_SetStyle"
         "Text_SetColor"
         "Text_SetString"
         "Text_GetString"
         ;;
         ;; drawings / trend lines
         "TL_New"
         "TL_SetBegin"
         "TL_SetEnd"
         "TL_Delete"
         "TL_SetSize"
         "TL_SetColor"
         "TL_SetExtRight"
         "TL_SetExtLeft"
         "TL_GetFirst"
         "TL_GetNext"
         "TL_GetValue"
         "TL_GetBeginDate"
         "TL_GetBeginTime"
         "TL_GetBeginVal"
         "TL_GetEndDate"
         "TL_GetEndTime"
         "TL_GetEndVal"
         "TL_GetColor"
         ;;
         ;; GetAppInfo
         "GetAppInfo"
         ;;
         ;; misc
         "PlaySound" "Reset"))

 (setq powerlanguage--font-lock-keywords
       (let* ((x-keywords-regexp  (regexp-opt powerlanguage--keywords  'words))
              (x-types-regexp     (regexp-opt powerlanguage--types     'words))
              (x-constants-regexp (regexp-opt powerlanguage--constants 'words))
              (x-events-regexp    (regexp-opt powerlanguage--events    'words))
              (x-functions-regexp (regexp-opt powerlanguage--functions 'words)))
         `((,x-types-regexp     . font-lock-type-face)
           (,x-constants-regexp . font-lock-constant-face)
           (,x-events-regexp    . font-lock-builtin-face)
           (,x-functions-regexp . font-lock-function-name-face)
           (,x-keywords-regexp  . font-lock-keyword-face)
           ;; note: order above matters, because once colored, that part won't change.
           ;; in general, put longer words first
           )))

 (defconst powerlanguage--mode-syntax-table
   (let ((table (make-syntax-table)))
     ;; " is a string delimiter
     (modify-syntax-entry ?\" "\""    table)
     ;; { ... }   — block comment (style a, the default — spans newlines)
     (modify-syntax-entry ?{  "<"     table)
     (modify-syntax-entry ?}  ">"     table)
     ;; // ... \n  — line comment (style b, so \n closes only the line
     ;; comment and not an open { ... } block)
     (modify-syntax-entry ?/  ". 12b" table)
     (modify-syntax-entry ?\n "> b"   table)
     table))

 (define-derived-mode powerlanguage-mode fundamental-mode "PowerLanguage"
   "Major mode for editing Multicharts PowerLanguage (.pwl) files."
   :syntax-table powerlanguage--mode-syntax-table
   (setq font-lock-defaults '(powerlanguage--font-lock-keywords nil t)))

 (add-hook 'powerlanguage-mode-hook
           (lambda ()
             (setq outline-regexp "// === ")
             (outline-minor-mode)
             (display-line-numbers-mode 1)))

 (defhydra hydra-powerlanguage (:exit t :hint nil)
   "
^PowerLanguage hydra:
^--------------------
outline : _o_ hide & _a_ show-all
"
   ("a" #'outline-show-all)
   ("o" #'outline-hide-body))

 ) ; end of init section

;;; end of init--lang-powerlanguage.el
