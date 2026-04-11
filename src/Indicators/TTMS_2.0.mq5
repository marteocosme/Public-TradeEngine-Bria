//+------------------------------------------------------------------+
//|                                                     TTMS_2.0.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.01"
#property description "John Carter TTM Squeeze Indicator (cleaned & fixed)"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   3

//--- plot 1: TTMS histogram (color by rising/falling)
#property indicator_label1  "TTMS"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLimeGreen, clrRed     // rising, falling
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot 2: Squeeze On (red dot on zero)
#property indicator_label2  "Squeeze On"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- plot 3: Squeeze Off (gray dot on zero)
#property indicator_label3  "Squeeze Off"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- inputs
input uint              InpPeriodBB       = 20;        // BB period
input double            InpDevBB          = 2.0;       // BB deviation
input uint              InpPeriodKL       = 20;        // Keltner period (midline MA)
input uint              InpPeriodSmoothKL = 20;        // ATR period for Keltner
input ENUM_MA_METHOD    InpMethodKL       = MODE_EMA;  // Keltner midline smoothing method (default MODE_EMA)
input double            InpDevKL          = 1.5;       // Keltner deviation
input uchar             InpSizeSig        = 1;         // Dot size

//--- indicator buffers
double   BufferTTMS[];        // visible histogram values
double   BufferTTMSColors[];  // color indexes for histogram (0=rise, 1=fall)
double   BufferSig[];         // squeeze ON dot (0 on zero line)
double   BufferNoSig[];       // squeeze OFF dot (0 on zero line)

//--- calc buffers (hidden)
double   BufferMABB[];        // BB midline (SMA)
double   BufferMAKL[];        // KC midline (MA)
double   BufferDEV[];         // BB StdDev
double   BufferATR[];         // ATR for Keltner

//--- globals (resolved inputs)
double   dev_bb;
double   dev_kl;
int      period_bb;
int      period_kl;
int      period_sm;
int      size_sig;

//--- indicator handles
int      handle_mabb = INVALID_HANDLE;
int      handle_makl = INVALID_HANDLE;
int      handle_dev  = INVALID_HANDLE;
int      handle_atr  = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
  //--- resolve inputs & guardrails
  period_bb = (int)(InpPeriodBB       < 1 ? 1 : InpPeriodBB);
  period_kl = (int)(InpPeriodKL       < 1 ? 1 : InpPeriodKL);
  period_sm = (int)(InpPeriodSmoothKL < 1 ? 1 : InpPeriodSmoothKL);
  dev_bb    = (InpDevBB < 0.1 ? 0.1 : InpDevBB);
  dev_kl    = (InpDevKL < 0.1 ? 0.1 : InpDevKL);
  size_sig  = (int)(InpSizeSig < 1 ? 1 : InpSizeSig);

  //--- map buffers
  SetIndexBuffer(0, BufferTTMS,       INDICATOR_DATA);
  SetIndexBuffer(1, BufferTTMSColors, INDICATOR_COLOR_INDEX);
  SetIndexBuffer(2, BufferSig,        INDICATOR_DATA);
  SetIndexBuffer(3, BufferNoSig,      INDICATOR_DATA);
  SetIndexBuffer(4, BufferMABB,       INDICATOR_CALCULATIONS);
  SetIndexBuffer(5, BufferMAKL,       INDICATOR_CALCULATIONS);
  SetIndexBuffer(6, BufferDEV,        INDICATOR_CALCULATIONS);
  SetIndexBuffer(7, BufferATR,        INDICATOR_CALCULATIONS);

  //--- dots as round points (Wingdings 108)
  PlotIndexSetInteger(1, PLOT_ARROW, 108);
  PlotIndexSetInteger(2, PLOT_ARROW, 108);

  //--- dot sizes
  PlotIndexSetInteger(1, PLOT_LINE_WIDTH, size_sig);
  PlotIndexSetInteger(2, PLOT_LINE_WIDTH, size_sig);

  //--- hide dot values from Data Window (optional)
  PlotIndexSetInteger(1, PLOT_SHOW_DATA, false);
  PlotIndexSetInteger(2, PLOT_SHOW_DATA, false);

  //--- indicator digits/short name
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
  string shortname = StringFormat("TTM Squeeze (BB %d/%.1f, KC %d %s x %.1f, ATR %d)",
                                  period_bb, dev_bb, period_kl,
                                  EnumToString(InpMethodKL), dev_kl, period_sm);
  IndicatorSetString(INDICATOR_SHORTNAME, shortname);

  //--- set arrays as time series
  ArraySetAsSeries(BufferTTMS,       true);
  ArraySetAsSeries(BufferTTMSColors, true);
  ArraySetAsSeries(BufferSig,        true);
  ArraySetAsSeries(BufferNoSig,      true);
  ArraySetAsSeries(BufferMABB,       true);
  ArraySetAsSeries(BufferMAKL,       true);
  ArraySetAsSeries(BufferDEV,        true);
  ArraySetAsSeries(BufferATR,        true);

  //--- zero level line for reference
  IndicatorSetInteger(INDICATOR_LEVELS, 1);
  IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.0);
  IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrSilver);

  //--- create indicator handles
  ResetLastError();
  handle_mabb = iMA(NULL, PERIOD_CURRENT, period_bb, 0, MODE_SMA, PRICE_CLOSE);
  if(handle_mabb == INVALID_HANDLE)
  {
    Print("iMA(BB mid) creation failed: ", GetLastError());
    return INIT_FAILED;
  }

  ResetLastError();
  handle_makl = iMA(NULL, PERIOD_CURRENT, period_kl, 0, InpMethodKL, PRICE_CLOSE);
  if(handle_makl == INVALID_HANDLE)
  {
    Print("iMA(KC mid) creation failed: ", GetLastError());
    return INIT_FAILED;
  }

  ResetLastError();
  handle_dev = iStdDev(NULL, PERIOD_CURRENT, period_bb, 0, MODE_SMA, PRICE_CLOSE);
  if(handle_dev == INVALID_HANDLE)
  {
    Print("iStdDev(BB) creation failed: ", GetLastError());
    return INIT_FAILED;
  }

  ResetLastError();
  handle_atr = iATR(NULL, PERIOD_CURRENT, period_sm);
  if(handle_atr == INVALID_HANDLE) // <- FIXED: check ATR handle, not DEV
  {
    Print("iATR creation failed: ", GetLastError());
    return INIT_FAILED;
  }

  //--- warm-up hide (draw begin after minimum bars)
  int min_bars = (int)MathMax(period_bb, MathMax(period_kl, period_sm)) + 2;
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, min_bars);
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, min_bars);
  PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, min_bars);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator de-initialization                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  if(handle_mabb != INVALID_HANDLE) IndicatorRelease(handle_mabb);
  if(handle_makl != INVALID_HANDLE) IndicatorRelease(handle_makl);
  if(handle_dev  != INVALID_HANDLE) IndicatorRelease(handle_dev);
  if(handle_atr  != INVALID_HANDLE) IndicatorRelease(handle_atr);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
  //--- minimum bars check (based on the longest dependency) + 2 for lookback
  int min_bars = (int)MathMax(period_bb, MathMax(period_kl, period_sm)) + 2;
  if(rates_total < min_bars || _Point == 0.0)
    return 0;

  //--- first run or incremental update
  bool first = (prev_calculated == 0);

  // start = how many newest bars to (re)calculate: on first run ~rates_total-2, else new bars since last call
  int start = first ? rates_total - 2 : (rates_total - prev_calculated);
  if(start < 0) start = 0;

  //--- initialize buffers only once (avoid wiping history on later recalcs)
  if(first)
  {
    ArrayInitialize(BufferTTMS,       EMPTY_VALUE);
    ArrayInitialize(BufferTTMSColors, EMPTY_VALUE);
    ArrayInitialize(BufferSig,        EMPTY_VALUE);
    ArrayInitialize(BufferNoSig,      EMPTY_VALUE);
    ArrayInitialize(BufferMABB,       EMPTY_VALUE);
    ArrayInitialize(BufferMAKL,       EMPTY_VALUE);
    ArrayInitialize(BufferDEV,        EMPTY_VALUE);
    ArrayInitialize(BufferATR,        EMPTY_VALUE);
  }

  //--- copy only what we need (+1 lookback for i+1 access)
  int copy_count = start + 2; // indices [0 .. start+1]
  if(copy_count > rates_total) copy_count = rates_total;

  int copied = 0;
  copied = CopyBuffer(handle_atr,  0, 0, copy_count, BufferATR);  if(copied != copy_count) return prev_calculated;
  copied = CopyBuffer(handle_dev,  0, 0, copy_count, BufferDEV);  if(copied != copy_count) return prev_calculated;
  copied = CopyBuffer(handle_mabb, 0, 0, copy_count, BufferMABB); if(copied != copy_count) return prev_calculated;
  copied = CopyBuffer(handle_makl, 0, 0, copy_count, BufferMAKL); if(copied != copy_count) return prev_calculated;

  //--- calculation loop (from newest bar to oldest among the updated range)
  for(int i = start; i >= 0; --i)
  {
    // Keltner bands
    double H  = BufferMAKL[i] + BufferATR[i] * dev_kl;
    double L  = BufferMAKL[i] - BufferATR[i] * dev_kl;

    // Bollinger bands (using SMA mid + StdDev)
    double D  = BufferDEV[i];
    double TL = BufferMABB[i] + dev_bb * D;
    double BL = BufferMABB[i] - dev_bb * D;

    // basic validity checks
    if(!MathIsValidNumber(H) || !MathIsValidNumber(L) ||
       !MathIsValidNumber(TL) || !MathIsValidNumber(BL))
      continue;

    // Histogram value: ratio of KC width to BB width, centered at zero
    // BufferTTMS = (H - L) / (TL - BL) - 1
    if(TL != BL)
      BufferTTMS[i] = ( (H - L) / (TL - BL) ) - 1.0;
    else
      BufferTTMS[i] = 0.0; // avoid division by zero when StdDev==0

    // Color index: compare to previous valid bar without looking ahead
    double prev_val = (i == start ? BufferTTMS[i] : BufferTTMS[i+1]);
    BufferTTMSColors[i] = (BufferTTMS[i] > prev_val ? 0 : 1); // 0=green, 1=red

    // Squeeze state (BB inside KC): red dot when ON, gray dot when OFF
    bool squeeze_on = (TL < H && BL > L);

    if(squeeze_on)
    {
      BufferSig[i]   = 0.0;         // red dot at zero
      BufferNoSig[i] = EMPTY_VALUE;
    }
    else
    {
      BufferSig[i]   = EMPTY_VALUE;
      BufferNoSig[i] = 0.0;         // gray dot at zero
    }
  }

  //--- return the number of bars processed
  return rates_total;
}
//+------------------------------------------------------------------+
