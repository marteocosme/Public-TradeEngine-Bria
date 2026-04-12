//+------------------------------------------------------------------+
//|                                         libCTradeContext.mqh     |
//|                  Unified Trade Decision Context (Snapshot)       |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCTRADECONTEXT_MQH__
#define __LIBCTRADECONTEXT_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>

//TopdownSettings inpTopdown; //NEED TO FIX HAZARD TO DECLARE CGLOBALLY


// ------------------------------------------------------------------
// TradeContext
// A single snapshot of "what the engines saw" on BAR_SIGNAL.
// This merges: Baseline + Confirmation + Volume + ATR (+ Exit optional)
// and computes a derived EntryBias + IsTradeable flag.
// ------------------------------------------------------------------
struct TradeContext
{

   // -----------------------------
   // New fields for Strategy Decision Spec v1.1 —
   // -----------------------------
   double BaselineEntryPrice;   // numeric baseline value at BAR_SIGNAL
   enum_position BaselineCrossDirection; // Baseline cross event (used by Baseline Cross strategy)


   // -----------------------------
   // Identity / Timing
   // -----------------------------
   string          Symbol;
   ENUM_TIMEFRAMES EntryPeriod;      // trade execution timeframe (e.g., M15)
   ENUM_TIMEFRAMES TopdownPeriod;    // higher timeframe for top-down trend (e.g., D1)
   datetime        Time;         // time of BAR_SIGNAL on EntryPeriod

   // -----------------------------
   // Engine Outputs (raw results)
   // -----------------------------

   BaselineResult      BaselineEntry;        // baseline result on EntryPeriod (entry)
   BaselineResult      BaselineTopdown;      // baseline result on TopdownPeriod (top-down)

   ConfirmationResult  ConfirmEntry;         // dual confirmation result on EntryPeriod
   ConfirmationResult  ConfirmTopdown;       // dual confirmation result on TopdownPeriod
   VolumeResult        VolumeEntry;          // TTMS squeeze ON/OFF on EntryPeriod
   VolumeResult        VolumeTopdown;        // TTMS squeeze ON/OFF on TopdownPeriod
   ATRResult           ATREntry;             // ATR on EntryPeriod (used for SL/TP sizing)
   ATRResult           ATRTopdown;           // ATR on TopdownPeriod (used for SL/TP sizing)

   // Optional: Exit engine output (not required for entry decision)
   ExitResult          Exit;

   // -----------------------------
   // Derived / Decision Fields
   // -----------------------------
   enum_position   EntryBias;          // Long/Short/NoTrade (final entry direction)
   bool            VolumeGatePassed;   // Option A gate: TTMS squeeze must be ON
   bool            IsTradeable;        // final decision flag (gate + confirmation + score)

   // -----------------------------
   // --- Policy / Control
   // -----------------------------
   int             MinConfirmScore;    // default threshold (engine can override)
   bool            RequireVolumeGate;  // default true for Option A
   bool            EnableTopDown;        // <--- NEW
   bool            RequireTopDownAlign;  // <--- NEW (strictness)
   bool            TopDownAligned;       // <--- NEW (computed)


   // -----------------------------
   // Reset all fields to safe defaults
   // -----------------------------
   void Reset()
   {
      Symbol = "";
      EntryPeriod = PERIOD_CURRENT;
      TopdownPeriod = PERIOD_CURRENT;
      Time = 0;

      // Baseline defaults

      BaselineEntry.signal = SigNone;
      BaselineEntry.trend  = TrendNone;

      BaselineTopdown.signal = SigNone;
      BaselineTopdown.trend  = TrendNone;

      //## NOTES" Need to rewire with inpSetting"
      EnableTopDown = false;
      RequireTopDownAlign = true;
      TopDownAligned = true; // default true when top-down is off



      // Confirmation defaults
      ConfirmEntry.Signal = NoTrade;
      ConfirmEntry.Trend  = NoTrade;
      ConfirmEntry.IsValid = false;
      ConfirmEntry.Time = 0;
      ConfirmEntry.PrimarySource = CONF_NONE;
      ConfirmEntry.SecondarySource = CONF_NONE;
      ConfirmEntry.Score = 0;

      ConfirmTopdown.Signal = NoTrade;
      ConfirmTopdown.Trend  = NoTrade;
      ConfirmTopdown.IsValid = false;
      ConfirmTopdown.Time = 0;
      ConfirmTopdown.PrimarySource = CONF_NONE;
      ConfirmTopdown.SecondarySource = CONF_NONE;
      ConfirmTopdown.Score = 0;

      // Volume defaults
      VolumeEntry.Reset();

      // ATR defaults
      ATREntry.Reset();

      // Exit defaults
      Exit.ShouldExit = false;
      Exit.Reason = EXIT_NONE;
      Exit.Time = 0;

      // Derived defaults
      EntryBias = NoTrade;
      VolumeGatePassed = false;
      IsTradeable = false;

      // Policy defaults (tunable from engine)
      MinConfirmScore = 60;       // recommended starting threshold
      RequireVolumeGate = true;   // Option A: TTMS must be ON
   }

   // ---------------------------------------------------------------
   // Apply Volume Gate (Option A):
   // TTMS Squeeze must be ON to allow entries.
   // ---------------------------------------------------------------
   void ApplyVolumeGateOptionA()
   {
      // If volume result isn't valid, fail the gate (safer)
      if(!VolumeEntry.IsValid)
         {
         VolumeGatePassed = false;
         return;
         }

      VolumeGatePassed = (VolumeEntry.State == VOL_STATE_ON);
   }

   // ---------------------------------------------------------------
   // Resolve Entry Bias:
   // This merges Baseline trend with Confirmation signal+trend.
   //
   // Recommended rule:
   // - Long entry when Baseline trend is up AND confirmation signal+trend are Long
   // - Short entry when Baseline trend is down AND confirmation signal+trend are Short
   // Else: NoTrade
   // ---------------------------------------------------------------
   void ResolveEntryBias()
   {
      EntryBias = NoTrade;

      // Require confirmation validity for bias resolution
      if(!ConfirmEntry.IsValid)
         return;

      // Entry uses Execution TF baseline trend (BaselineEntry)
      if(BaselineEntry.trend == TrendUp &&
            ConfirmEntry.Signal == Long &&
            ConfirmEntry.Trend  == Long)
         {
         EntryBias = Long;
         return;
         }

      if(BaselineEntry.trend == TrendDown &&
            ConfirmEntry.Signal == Short &&
            ConfirmEntry.Trend  == Short)
         {
         EntryBias = Short;
         return;
         }
   }
   void EvaluateTopDownAlignment()
   {
      // If top-down is disabled, treat as aligned
      if(!EnableTopDown)
         {
         TopDownAligned = true;
         return;
         }

      // If we don't have an EntryBias yet, can't align
      if(EntryBias == NoTrade)
         {
         TopDownAligned = false;
         return;
         }

      // Flexible rule:
      // - Allow TrendNone (neutral HTF) to pass unless RequireTopDownAlign is strict
      if(BaselineTopdown.trend == TrendNone)
         {
         TopDownAligned = !RequireTopDownAlign ? true : false;
         return;
         }

      if(EntryBias == Long  && BaselineTopdown.trend == TrendUp)   TopDownAligned = true;
      else if(EntryBias == Short && BaselineTopdown.trend == TrendDown) TopDownAligned = true;
      else TopDownAligned = false;
   }










   // ---------------------------------------------------------------
   // Finalize:
   // Computes IsTradeable based on:
   // - EntryBias != NoTrade
   // - Confirmation score >= MinConfirmScore
   // - Volume gate (if enabled)
   // ---------------------------------------------------------------

   void Finalize()
   {
      // Apply volume gate if required
      if(RequireVolumeGate)
         {
         ApplyVolumeGateOptionA();
         if(!VolumeGatePassed)
            {
            IsTradeable = false;
            EntryBias = NoTrade;         // hard stop for Option A
            return;
            }
         }
      else
         {
         // if not required, still compute it (for debug)
         ApplyVolumeGateOptionA();
         }

      // Resolve direction from Baseline + Confirmation
      ResolveEntryBias();

      // Top-Down alignment (optional)
      EvaluateTopDownAlignment();
      if(EnableTopDown && !TopDownAligned)
         {
         IsTradeable = false;
         EntryBias = NoTrade;
         return;
         }

      // Score gate
      if(EntryBias == NoTrade)
         {
         IsTradeable = false;
         return;
         }

      if(ConfirmEntry.Score < MinConfirmScore)
         {
         IsTradeable = false;
         EntryBias = NoTrade;  // optional: enforce "no-trade" when score is low
         return;
         }

      // All checks passed
      IsTradeable = true;
   }
};


// ---------------------------------------------------------------
// Build Signal Snapshot (Decision Telemetry)
// ---------------------------------------------------------------
SignalSnapshot BuildSignalSnapshot(const TradeContext &ctx)
{
   SignalSnapshot s;

   s.time   = ctx.Time;
   s.symbol = ctx.Symbol;

// Baseline
   s.baseTrend = ctx.BaselineEntry.trend;

// Confirmation
   s.confSignal = ctx.ConfirmEntry.Signal;
   s.confTrend  = ctx.ConfirmEntry.Trend;
   s.confScore  = ctx.ConfirmEntry.Score;

// Volume
   s.volState = ctx.VolumeEntry.State;

// Final decision
   s.entryAllowed = ctx.IsTradeable;

   return s;
}


#endif // __LIBCTRADECONTEXT_MQH__/


/*
✅ How to Use This in Your Trade Engine (Recommended Flow)
In your BuildTradeContext() inside CSignalEngine (or equivalent), you’d do:

TradeContext ctx;
ctx.Reset();

ctx.Symbol  = _Symbol;
ctx.EntryPeriod  = inpTradeExecutionPeriod;
ctx.TopdownPeriod = inpTrendAnalysisPeriod;
ctx.Time    = iTime(_Symbol, inpTradeExecutionPeriod, BAR_SIGNAL);

// 1) Baseline
ctx.Baseline = baselineSignal.GetBaselineStatus(
                 _Symbol, ctx.EntryPeriod, BAR_SIGNAL,
                 inpBaselineInd,
                 (uint)inpIMA_Period,
                 (uint)inpIMA_Shift,
                 inpIMA_Method,
                 inpIMA_AppliedPrice,
                 (uint)inpATRinterval,
                 inpBLxATRxPlier
              );

// 2) Volume (TTMS gate)
TTMSParams tp;
tp.bbPeriod = (int)inpBBperiod;
tp.bbDev    = inpBBdeviation;
tp.kPeriod  = (int)inpKperiod;
tp.kMethod  = inpKmethod;
tp.kDev     = inpKdeviation;

volumeSignal.UpdateTTMS(_Symbol, ctx.EntryPeriod, tp);
ctx.Volume = volumeSignal.Result();

// 3) Confirmation
PSARParams ps; ps.step = inpPSAR_Steps; ps.max = inpPSAR_Max;
RVIParams  rv; rv.period = (int)inpRVI_Period;
KuskusParams ku; ku.rPeriod=0; ku.pSmooth=0; ku.iSmooth=0;

confirmSignal.UpdateDual(_Symbol, ctx.EntryPeriod,
                         inpConfirmPrimary, inpConfirmSecondary,
                         ps, rv, ku);

// Apply volume to confirmation (gate+boost already inside ApplyVolumeGate in your confirmation file)
confirmSignal.ApplyVolumeGate(ctx.Volume);
ctx.Confirm = confirmSignal.Result();

// 4) ATR
atrSignal.Update(_Symbol, ctx.EntryPeriod, (int)inpATRinterval, BAR_SIGNAL);
ctx.ATR = atrSignal.Result();

// 5) Decide
ctx.RequireVolumeGate = true;  // Option A
ctx.MinConfirmScore   = 60;    // tune
ctx.Finalize();
``

Now your EA can simply do:
// if(ctx.IsTradeable && ctx.EntryBias == Long) { /* Buy */ // }
// if(ctx.IsTradeable && ctx.EntryBias == Short){ /* Sell */ }






//+------------------------------------------------------------------+
