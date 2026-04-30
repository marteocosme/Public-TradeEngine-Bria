//+------------------------------------------------------------------+
//|                                              libCTradeEngine.mqh |
//|                                                     Marteo Cosme |
//|                               Updated: 2026-04-03 (TradeContext) |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBCTRADEENGINE_MQH__
#define __LIBCTRADEENGINE_MQH__

#include <Trade\Trade.mqh>

// --- Core enums & utilities
#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>
#include <MyInclude\NNFX\CDebug.mqh>

// --- Signal engines
#include <MyInclude\NNFX\libCBaseline.mqh>
#include <MyInclude\NNFX\libCConfirmation.mqh>
#include <MyInclude\NNFX\libCVolume.mqh>
#include <MyInclude\NNFX\libCATRSignal.mqh>
#include <MyInclude\NNFX\libCExitSignal.mqh>

// --- Management engines
#include <MyInclude\NNFX\libCPartialCloseEngine.mqh>
#include <MyInclude\NNFX\libCBreakEvenEngine.mqh>
#include <MyInclude\NNFX\libCTrailingStopEngine.mqh>
#include <MyInclude\\NNFX\\libCEntryStrategyEngine.mqh>

// --- Risk & execution
#include <MyInclude\NNFX\libCRiskEngine.mqh>
#include <MyInclude\NNFX\libCATRRiskTracker.mqh>
#include <MyInclude\NNFX\libCTradeExecution.mqh>



// ---- Context & visualization
#include <MyInclude\NNFX\libCTradeContext.mqh>
#include <MyInclude\NNFX\libCTradeVisualizer.mqh>
#include <MyInclude\NNFX\libCUnifiedTradeLogger.mqh>
#include <MyInclude\NNFX\TradeEngine\TradeLifecycleController.mqh>


//#include <MyInclude\NNFX\libCContextLogger.mqh>


// --------------------------------------------------
// MM Snapshot (Phase 5 / MM-LOG-01 — incremental stub)
// --------------------------------------------------
struct MM_SNAPSHOT_BEFORE;
struct MM_SNAPSHOT_AFTER;




// ================================================================
// Scaling stages (ATREntry-based)
// ================================================================
ScaleStage g_scaleStages[] =
{
   { 1.0, 0.50 },
   { 2.0, 0.25 }
};
#define SCALE_STAGE_COUNT (ArraySize(g_scaleStages))

// ================================================================
// INPUTS
// ================================================================

// ---- Execution / Top-Down
input group "Timeframes"                                 // Timeframe Settings
input ENUM_TIMEFRAMES inpEntryPeriod = PERIOD_M15;       // LTF Period
input ENUM_TIMEFRAMES inpTopdownPeriod = PERIOD_D1;      // HTF Period
input bool inpEnableTopDown = false;                     // Enable Topdown in Analysis
input bool inpRequireTopDownAlign = true;                // Required Topdown
/* Behavior:
inpEnableTopDown=false → ignore Trend TF baseline
inpEnableTopDown=true → compute Trend TF baseline and apply alignment rule
inpRequireTopDownAlign=true → require HTF trend not neutral (TrendNone fails)
inpRequireTopDownAlign=false → HTF TrendNone allowed
*/
input group "-----"

// ---- Risk
input group "Risk Settings"                           // Parameter for Risks Settings
input enum_riskMethod inpRiskMethod = RISK_BALANCE;   // Risk Source Method
input double inpRiskPercent = 0.005;                  // Risk Percent per trade
input double inpRiskFixAmount = 100.0;                // Risk Fix Amount
input double inpSLxATRxPlier = 1.5;                   // Stoploss x ATR multiplier (Risk in Pips) default=1.5
input uint   inpMaxOpenPosition = 1;                  // Maximum open position on trade
input bool   inpEnableScalingOut = true;              // Emable Scaling Out
input group "-----"
input group "Anti Martingale"                         // Parameter for Anti Martigale Trading
input bool   inpEnableAntiMartingale = false;         // Enable Anti Martingale with Risk%
input double inpRiskStep = 0.005;                     // Risk% Step up
input double inpRiskMax  = 0.05;                      // Max Risk% per trade
input group "-----"

// ---- ATR
input group "ATR Settings"                            // Parameter for ATR Settings
input uint   inpATRinterval = 14;                     // ATR period input
input double inpTPxATRxPlier = 3.0;                   // Takeprofit x ATR multiplier (Profit in Pips)
input double inpBLxATRxPlier = 1.0;                   // Baseline: Upper / Lower multiplier (Default: 1.0 | Disable: 0)
input group "-----"

// ---- Baseline
input group "Baseline Settings"                       // Parameter for Baseline Setting
input enum_Baseline inpBaselineInd = MA;              // Baseline Indicator
input group "-- Baseline - iMA"
input uint inpIMA_Period = 6;                         // -- iMA period
input uint inpIMA_Shift  = 0;                         // -- iMA Shift
input ENUM_MA_METHOD inpIMA_Method = MODE_SMA;        // -- iMA Method
input ENUM_APPLIED_PRICE inpIMA_AppliedPrice = PRICE_CLOSE; // -- iMA Applied Price
input group "--  Baseline - SWMA"
input uint inpSWMA_Period = 15;                             // -- SWMA period
input ENUM_APPLIED_PRICE inpSWMA_AppliedPrice = PRICE_CLOSE; // -- SWMA Applied Price
input group "-----"

// ---- Confirmation
input group "Confirmation Settings"
input enum_Confirmation inpConfirmPrimary   = PSAR;            // Confirmation Indicator(Main)
input enum_Confirmation inpConfirmSecondary = RVI;             // Confirmation Indicator(Second)
input group "-- Parabolic Stop and Reverse (PSAR)"
input double inpPSAR_Steps = 0.04;                             // -- -- PSAR - Step
input double inpPSAR_Max = 0.2;                                // -- -- PSAR - Maximum
input group "-- Relative Vigor Index"
input uint inpRVI_Period = 10;                                 // -- -- RVI - period
input group "-----"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group "Volume Indicator Settings"                        // ---- Volume (TTMS Option‑A Gate)
input group "Volume (TTMS)"
input ENUM_VOL_IND inpVolInd = ENUM_VOL_IND::TTMS;             // Volume Indicator
input uint inpBBperiod = 20;                                   // -- TTMS - BB Period
input double inpBBdeviation = 2.0;                             // -- TTMS - BB Deviation
input uint inpKperiod = 20;                                    // -- TTMS - Keltner Smooth Period
input ENUM_MA_METHOD inpKmethod = MODE_SMA;                    // -- TTMS - Keltner Smooth Method
input double inpKdeviation = 2.0;                              // -- TTMS - Keltner

input group "-----"

// ---- Break Even / Trailing / Scaling
input group "Trade Management"
input double inpBE_ATR = 1.0;                                  // ATR x BE Multiplier
input double inpBE_ExtraPips = 2.0;                            // Add extra PIPs on top of Break Even

input double inpScaleATR = 1.0;                                // Scaleout Multiplier
input double inpScaleFraction = 0.5;                           // Scale Ratio
input double inpTrailStartATR = 2.0;                           // Trail Stop Multiplier
input double inpTrailATR = 1.5;                                // Threshold when to trigger the Trail Stop
input group "-----"



// ---- Exit
input group "Exit Settings"                                    // Exit Settings
input enum_Confirmation inpExitIndicator = RVI;                // Exit Indicator
input enum_exitMode inpExitMode = EXIT_MODE_CROSS;             // Exit Mode
input group "-----"


// ================================================================
// Trade Engine
// ================================================================
class CTradeEngine
{
private:
   CDebugPrint          m_debug;

   CBaseline            m_baseline;
   CConfirmation        m_confirm;
   CVolumeSignal        m_volume;
   CATRSignal           m_atr;

   CRiskEngine          m_risk;
   CATRRiskTracker      m_atrTracker;
   CTradeExecution      m_exec;

   CEntryStrategyEngine m_entryStrategy;
   enum_entryStrategy m_activeStrategy;

   CBreakEvenEngine     m_be;
   CPartialCloseEngine  m_scale;
   CTrailingStopEngine  m_trail;
   CExitSignal          m_exit;


   CTradeVisualizer     m_viz;
   CUnifiedTradeLogger  m_logger;
   //CContextLogger       m_logger;

   datetime             m_lastCandleTime;

   // --------------------------------------------------
   // Phase 5 — Trade Lifecycle Orchestration
   // Step 3: Embedded controller (unused for now)
   // --------------------------------------------------
   TradeLifecycleController m_lifecycleController;


// ============================================================
// INF-3 Snapshot Enforcement State
// ============================================================
   bool m_before_emitted;
   bool m_after_emitted;
   ENUM_MM_EVENT_TYPE m_current_event;


   void BeginMMCycle(ENUM_MM_EVENT_TYPE evt)
   {
      m_current_event = evt;
      m_before_emitted = false;
      m_after_emitted  = false;
   }

   void EndMMCycleCheck()
   {
      if(!m_before_emitted)
         {
         /* Replace Print()        
         Alert("INF-3 VIOLATION...");
         ExpertRemove(); // optional
         */
         Print("❌ INF-3 VIOLATION: BEFORE snapshot missing for event: ",
               EnumToString(m_current_event));
         }

      if(!m_after_emitted)
         {
         /* Replace Print() 
         Alert("INF-3 VIOLATION...");
         ExpertRemove(); // optional
         */
         Print("❌ INF-3 VIOLATION: AFTER snapshot missing for event: ",
               EnumToString(m_current_event));
         }
   }


//CTradeEngine::CTradeEngine()
//{
   // Existing initialization only
   // No lifecycle logic here in Step 3
//}

   void EmitSnapshotBefore(const MM_SNAPSHOT_BEFORE &snap)
   {
      MM_LogSnapshotBefore rec;

      rec.timestamp = snap.timestamp;
      rec.symbol    = snap.symbol;
      rec.timeframe = snap.timeframe;
      rec.trade_context_id = snap.trade_context_id;

      rec.mm_phase        = snap.mm_phase;
      rec.mm_event_intent = snap.mm_event_intent;

      rec.balance     = snap.balance;
      rec.equity      = snap.equity;
      rec.free_margin = snap.free_margin;

      rec.current_position_lots = snap.current_position_lots;
      rec.current_risk_exposure = snap.current_risk_exposure;

      rec.current_price = snap.current_price;
      rec.atr_value     = snap.atr_value;

      rec.take_profit  = snap.take_profit;
      rec.floating_pnl = snap.floating_pnl;

      rec.stoploss_points = snap.stoploss_points;
      rec.value_per_point = snap.value_per_point;

      rec.scale_atr_multiple = snap.scale_atr_multiple;
      rec.scale_fraction     = snap.scale_fraction;

      m_logger.LogMMSnapshotBefore(rec);

      m_before_emitted = true;

   }

   void EmitSnapshotAfter(const MM_SNAPSHOT_AFTER &snap)
   {
      MM_LogSnapshotAfter rec;

      // --- Identity & Timing ---
      rec.timestamp        = snap.timestamp;
      rec.symbol           = snap.symbol;
      rec.timeframe        = snap.timeframe;
      rec.trade_context_id = snap.trade_context_id;

      // --- Exposure Result ---
      rec.calculated_lot_size   = snap.calculated_lot_size;
      rec.calculated_risk_amount = snap.calculated_risk_amount;

      // --- Execution Outcome ---
      rec.take_profit  = snap.take_profit;
      rec.realized_pnl = snap.realized_pnl;

      // --- Risk Geometry ---
      rec.stoploss_points = snap.stoploss_points;
      rec.value_per_point = snap.value_per_point;

      // ✅ Send to UnifiedTradeLogger
      m_logger.LogMMSnapshotAfter(rec);

      m_after_emitted = true;
   }

public:
   CTradeEngine() : m_lastCandleTime(0) {}

   CTradeEngine::~CTradeEngine()
   {
      // Clean up if needed
   }


   void Init()
   {

      // ✅ Entry strategy selection (v1.1)
      m_activeStrategy = ENTRY_STANDARD;

      // ✅ Engines that actually track ticket state
      m_scale.SetATRRiskTracker(m_atrTracker);
      m_exec.SetATRRiskTracker(m_atrTracker);

      // ✅ Debug configuration
      m_debug.SetTag("TradeEngine");
      m_debug.SetLevel(DBG_INFO);

      DebugPrint(m_debug, "Trade Engine initialized", DBG_INFO);
   }

   void OnDeinit()
   {
      m_confirm.Reset();
   }

   // To be called in OnTick EA
   void OnTick(const string symbol)
   {
      if(symbol == "") return;
      ManageExit(symbol); // Manage exits continuously (optional: only on new candle)

      if(!IsNewCandle(symbol, inpEntryPeriod)) return; // Only evaluate entry on new candle (BAR_SIGNAL is stable)

      m_atrTracker.PruneClosedTickets(); // Maintain ATR ticket list
      ManageOpenPosition(symbol);  // Manage Open Positions | ## can add input settings

      ManageEntry(symbol); // Entry logic
   }

   // ------------------------------------------------------------

   void ManageEntry(const string symbol)
   {
// --------------------------------------------------
// Cache symbol info once per tick (efficiency)
// --------------------------------------------------
      const double bid        = SymbolInfoDouble(symbol, SYMBOL_BID);
      const double ask        = SymbolInfoDouble(symbol, SYMBOL_ASK);
      const double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      const double tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

      if(PositionsTotal() >= (int)inpMaxOpenPosition)
         {
         DebugPrint(m_debug, "Max open positions reached.", DBG_WARN);
         return;
         }

      TradeContext ctx;
      if(!BuildTradeContext(ctx, symbol))
         {
         DebugPrint(m_debug, "Context not tradeable.", DBG_VERBOSE);
         return;
         }


// ----------------------------------------
// Entry Strategy Override (v1.1)
// ----------------------------------------
      EntryCandidate ec = m_entryStrategy.Evaluate(ctx, m_activeStrategy);

      if(!ec.allowed)
         {
         // Optional: log blocked reason
         return;
         }

// Override direction from strategy
      ctx.EntryBias    = ec.direction;
      ctx.IsTradeable  = true;

      RiskParams rp;
      rp.Method = inpRiskMethod;
      rp.BaseRiskPercent = inpRiskPercent;
      rp.FixedRiskAmount = inpRiskFixAmount;
      rp.EnableAntiMartingale = inpEnableAntiMartingale;
      rp.RiskStep = inpRiskStep;
      rp.MaxRiskPercent = inpRiskMax;
      rp.StopATRMultiplier = inpSLxATRxPlier;


// --- MM Snapshot BEFORE (complete risk inputs) ---
      MM_SNAPSHOT_BEFORE snap;
      snap.timestamp  = TimeCurrent();
      snap.symbol     = ctx.Symbol;
      snap.timeframe  = ctx.EntryPeriod;
      snap.trade_context_id = 0; // ticket not yet known

      snap.mm_phase        = ToMMPhaseString(MM_PHASE_ENTRY);
      snap.mm_event_intent = ToMMEventString(MM_EVENT_ENTRY);


// --- Market Context (Schema v1.1) ---
      snap.current_price =
         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         ? bid
         : ask;

// ATR value actually used by MM (NOT recomputed)
      snap.atr_value = ctx.ATREntry.Value;


      snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
      snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
      snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      snap.risk_model  = EnumToString(rp.Method);
      snap.risk_value  = rp.BaseRiskPercent;

// --- TRUE MM inputs ---
      snap.stoploss_points = ctx.ATREntry.Value * inpSLxATRxPlier;
      snap.value_per_point =
         tick_value / tick_size;

// what MM actually risks
      snap.risk_amount_used =
         m_risk.GetLastComputedRiskAmount(); // add getter if needed

      double lots = m_risk.ComputeLotSize(ctx, rp);
      if(lots <= 0)
         {
         DebugPrint(m_debug, "Lot size computation failed. Entry blocked.", DBG_WARN);
         return;
         }

// ✅ NOW snapshot what MM actually decided
      snap.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

      BeginMMCycle(MM_EVENT_ENTRY);
      EmitSnapshotBefore(snap);


// ✅ MM_SNAPSHOT_AFTER (ENTRY only)
      MM_SNAPSHOT_AFTER snap_after;
      snap_after.timestamp = TimeCurrent();
      snap_after.symbol    = ctx.Symbol;
      snap_after.timeframe = ctx.EntryPeriod;
      snap_after.mm_event_result = ToMMEventString(MM_EVENT_ENTRY);

      snap_after.calculated_lot_size = lots;
      snap_after.calculated_risk_amount =
         m_risk.GetLastComputedRiskAmount();

      snap_after.stoploss_points = snap.stoploss_points;
      snap_after.value_per_point = snap.value_per_point;

      EmitSnapshotAfter(snap_after);

      EndMMCycleCheck();

      // --------------------------------------------------
      // Phase 5 — Step 4: Lifecycle CREATE (pass-through)
      // --------------------------------------------------
      RejectionReason reject_reason = REJECT_NONE;
      m_lifecycleController.RequestAction(
         0,                    // trade_id not assigned yet
         ACTION_CREATE,
         reject_reason
      );

      // --- EXECUTE ENTRY (execution only) ---
      bool ok = m_exec.ExecuteEntry(
                   ctx,
                   lots,
                   inpSLxATRxPlier,
                   inpTPxATRxPlier
                );
      if(!ok)
         {
         DebugPrint(m_debug, "Trade execution failed.", DBG_ERROR);
         return;
         }

      // ✅ Broker accepted the order — position must exist now

      // --------------------------------------------------
      // Phase 5 — Step 4: Lifecycle ENTER (pass-through)
      // --------------------------------------------------
      m_lifecycleController.RequestAction(
         0, // existing trade_id (if already set)
         ACTION_ENTER,
         reject_reason
      );



      if(!PositionSelect(symbol))
         {
         DebugPrint(m_debug, "Entry sent but position not found.", DBG_ERROR);
         return;
         }

      // ======================================================
      // ✅ ENTRY EVENT — EXACTLY HERE (CORRECT LOCATION)
      // ======================================================
      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);
      // Track ATR at entry (must happen BEFORE logging)
      m_atrTracker.AddOrUpdate((long)ticket, ctx.ATREntry.Value);

      // ✅ ENTRY LOGGING — Phase 4.4 (single source of truth)
      MM_LogEventBase evt;
      evt.event_time = ctx.Time;                 // BAR_SIGNAL time
      evt.event_type = MM_EVENT_ENTRY;
      evt.phase      = MM_PHASE_ENTRY;
      evt.symbol     = ctx.Symbol;
      evt.timeframe  = ctx.EntryPeriod;
      evt.trade_id   = (long)ticket; // Dedicated trade_id generator inside CTradeEngine (Later/Phase 5)
      evt.ticket     = ticket;

      m_logger.LogMMEventBase(evt);
   }

   void ManageOpenPosition(const string symbol)
   {

// --------------------------------------------------
// Cache symbol info once per tick (efficiency)
// --------------------------------------------------
      const double bid        = SymbolInfoDouble(symbol, SYMBOL_BID);
      const double ask        = SymbolInfoDouble(symbol, SYMBOL_ASK);
      const double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      const double tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

      if(!PositionSelect(symbol)) return;

      RejectionReason reject_reason = REJECT_NONE;
      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);
      uint seq = m_atrTracker.NextEventSeq((long)ticket);

      // ✅ ADD THIS (REQUIRED)
      enum_position dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? Long : Short);

      if(ticket <= 0) return;

      TradeContext ctx;
      ctx.Symbol = symbol;
      ctx.Time = TimeCurrent(); // Use current time for management context
      ctx.ATREntry.Value   = m_atrTracker.GetATR(ticket);
      ctx.ATREntry.IsValid = (ctx.ATREntry.Value > 0.0);

      // --- PARTIAL CLOSE
      if(inpEnableScalingOut)
         {
         for(int i = 0; i < SCALE_STAGE_COUNT; i++)
            {
            // Phase 5 — Step 5: Lifecycle MM_ACTION (Scale-Out pass-through)
            m_lifecycleController.RequestAction(
               0, //ctx.trade_id,
               ACTION_MM,
               reject_reason
            );

            double closeLots = 0.0;

// ===============================
// MM_SNAPSHOT_BEFORE — SCALE_OUT
// ===============================
            MM_SNAPSHOT_BEFORE snap;
            snap.timestamp = TimeCurrent();
            snap.symbol    = ctx.Symbol;
            snap.timeframe = ctx.EntryPeriod;

// identity
            snap.trade_context_id = ticket;

// lifecycle intent
            snap.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
            snap.mm_event_intent = ToMMEventString(MM_EVENT_SCALE_OUT);

// --- Market Context (Schema v1.1) ---
            snap.current_price =
               (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               ? bid
               : ask;

// ATR value actually used by MM (NOT recomputed)
            snap.atr_value = ctx.ATREntry.Value;

// account state
            snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
            snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
            snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

// exposure BEFORE scale-out
            snap.current_position_lots =
               PositionGetDouble(POSITION_VOLUME);

// execution-state observability
            snap.take_profit   = PositionGetDouble(POSITION_TP);
            snap.floating_pnl  = PositionGetDouble(POSITION_PROFIT);

// reference risk (ENTRY risk anchor)
            snap.current_risk_exposure =
               m_risk.GetLastComputedRiskAmount(); // still valid reference

// reconstruction inputs
            snap.stoploss_points =
               ctx.ATREntry.Value * inpSLxATRxPlier;

            snap.value_per_point = tick_value / tick_size;

// ✅ SCALE_OUT trigger (THIS was missing)
            snap.scale_atr_multiple = g_scaleStages[i].atrMultiple;
            snap.scale_fraction     = g_scaleStages[i].closeFraction;

            BeginMMCycle(MM_EVENT_SCALE_OUT);

            EmitSnapshotBefore(snap);

            if(m_scale.Evaluate(ctx, g_scaleStages[i], closeLots))
               {

               Print(
                  "[MM_SNAPSHOT_BEFORE]",
                  " event=", snap.mm_event_intent,
                  " ATRx=", snap.scale_atr_multiple,
                  " close_frac=", snap.scale_fraction
               );


               if(m_exec.PartialClose(symbol, closeLots))
                  {

// ===============================
// MM_SNAPSHOT_AFTER — SCALE_OUT
// ===============================
                  MM_SNAPSHOT_AFTER snap_after;
                  snap_after.timestamp = TimeCurrent();
                  snap_after.symbol    = ctx.Symbol;
                  snap_after.timeframe = ctx.EntryPeriod;
                  snap_after.mm_event_result = ToMMEventString(MM_EVENT_SCALE_OUT);

// exposure AFTER scale-out
                  snap_after.calculated_lot_size =
                     snap.current_position_lots - closeLots;

// risk anchor unchanged (ENTRY-based)
                  snap_after.calculated_risk_amount =
                     m_risk.GetLastComputedRiskAmount();

// reuse for reconstruction
                  snap_after.stoploss_points  = snap.stoploss_points;
                  snap_after.value_per_point  = snap.value_per_point;


                  EmitSnapshotAfter(snap_after);
                  EndMMCycleCheck();


                  // ✅ Track stage application FIRST (prevents re-trigger)
                  m_atrTracker.MarkScaleStageApplied(ticket, g_scaleStages[i].atrMultiple);

                  // ----------------------------------------------------
                  // SCALE-OUT LOGGING — Phase 4.4
                  // ----------------------------------------------------
                  MM_LogEventBase evt;
                  evt.event_time = ctx.Time;                 // BAR_SIGNAL time
                  evt.event_type = MM_EVENT_SCALE_OUT;
                  evt.phase      = MM_PHASE_MANAGE;
                  evt.symbol     = ctx.Symbol;
                  evt.timeframe  = ctx.EntryPeriod;
                  evt.trade_id   = (long)ticket; // Dedicated trade_id generator inside CTradeEngine (Later/Phase 5)
                  evt.ticket     = ticket;

                  m_logger.LogMMEventBase(evt);
                  }
               }
            }
         }

      // --- BREAK EVEN
      double newSL;
      if(!m_atrTracker.IsBEApplied(ticket))
         {
         // Phase 5 — Step 5: Lifecycle MM_ACTION (Break-Even pass-through)
         m_lifecycleController.RequestAction(
            0, //ctx.trade_id,
            ACTION_MM,
            reject_reason
         );

// ===============================
// MM_SNAPSHOT_BEFORE — BREAK EVEN
// ===============================
         MM_SNAPSHOT_BEFORE snap;
         snap.timestamp = TimeCurrent();
         snap.symbol    = ctx.Symbol;
         snap.timeframe = ctx.EntryPeriod;

// identity
         snap.trade_context_id = ticket;

// lifecycle intent
         snap.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
         snap.mm_event_intent = ToMMEventString(MM_EVENT_BE);

// --- Market Context (Schema v1.1) ---
         snap.current_price =
            (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            ? bid
            : ask;

// ATR value actually used by MM (NOT recomputed)
         snap.atr_value = ctx.ATREntry.Value;

// account state
         snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
         snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
         snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

// exposure (unchanged by BE)
         snap.current_position_lots =
            PositionGetDouble(POSITION_VOLUME);

         snap.current_risk_exposure =
            m_risk.GetLastComputedRiskAmount();

// execution‑state observability
         snap.take_profit  = PositionGetDouble(POSITION_TP);
         snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);

// geometry (ENTRY‑anchored)
         snap.stoploss_points =
            ctx.ATREntry.Value * inpSLxATRxPlier;

         snap.value_per_point =
            tick_value /
            tick_size;

         BeginMMCycle(MM_EVENT_BE);
         EmitSnapshotBefore(snap);

         if(m_be.Evaluate(ctx, inpBE_ATR, inpBE_ExtraPips, newSL))
            {

            double oldSL = PositionGetDouble(POSITION_SL);
            double tp    = PositionGetDouble(POSITION_TP);

            if(m_exec.ModifyStopLoss(symbol, newSL))
               {

               m_atrTracker.MarkBEApplied(ticket); // 1️⃣ Mark BE applied FIRST (prevents double logging)
               m_viz.DrawBreakEven(symbol, newSL); // 2️⃣ Optional visualization (safe, non‑functional)
               uint seq = m_atrTracker.NextEventSeq(ticket); // Revisit removal only in Phase 5

               // 3️⃣ BREAK-EVEN LOGGING — Phase 4.4
               MM_LogEventBase evt;
               evt.event_time = ctx.Time;              // BAR_SIGNAL time
               evt.event_type = MM_EVENT_BE;
               evt.phase      = MM_PHASE_MANAGE;
               evt.symbol     = ctx.Symbol;
               evt.timeframe  = ctx.EntryPeriod;
               evt.trade_id   = (long)ticket; // Dedicated trade_id generator inside CTradeEngine (Later/Phase 5)
               evt.ticket     = ticket;

               m_logger.LogMMEventBase(evt);


// ===============================
// MM_SNAPSHOT_AFTER — BREAK EVEN
// ===============================
               MM_SNAPSHOT_AFTER snap_after;
               snap_after.timestamp = TimeCurrent();
               snap_after.symbol    = ctx.Symbol;
               snap_after.timeframe = ctx.EntryPeriod;

// lifecycle intent
               snap_after.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
               snap_after.mm_event_result = ToMMEventString(MM_EVENT_BE);

// no exposure change
               snap_after.calculated_lot_size =
                  PositionGetDouble(POSITION_VOLUME);

// ENTRY risk anchor still valid
               snap_after.calculated_risk_amount =
                  m_risk.GetLastComputedRiskAmount();

// updated execution state
               snap_after.take_profit  = PositionGetDouble(POSITION_TP);
               snap_after.realized_pnl = PositionGetDouble(POSITION_PROFIT);

// geometry unchanged
               snap_after.stoploss_points = snap.stoploss_points;
               snap_after.value_per_point = snap.value_per_point;

               EmitSnapshotAfter(snap_after);
               EndMMCycleCheck();

               }
            // ✅ Stop after BE — no trailing this tick (your original rule)
            return;
            }
         }

      // --- TRAILING

      // Phase 5 — Step 5: Lifecycle MM_ACTION (Trailing Stop pass-through)
      m_lifecycleController.RequestAction(
         0, //ctx.trade_id,
         ACTION_MM,
         reject_reason
      );


// ==================================
// MM_SNAPSHOT_BEFORE — TRAILING STOP
// ==================================
      MM_SNAPSHOT_BEFORE snap;
      snap.timestamp = TimeCurrent();
      snap.symbol    = ctx.Symbol;
      snap.timeframe = ctx.EntryPeriod;

// identity
      snap.trade_context_id = ticket;

// lifecycle intent
      snap.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
      snap.mm_event_intent = ToMMEventString(MM_EVENT_TRAIL);

// --- Market Context (Schema v1.1) ---
      snap.current_price =
         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         ? bid
         : ask;

// ATR value actually used by MM (NOT recomputed)
      snap.atr_value = ctx.ATREntry.Value;

// account state
      snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
      snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
      snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

// exposure (unchanged by trailing)
      snap.current_position_lots =
         PositionGetDouble(POSITION_VOLUME);

      snap.current_risk_exposure =
         m_risk.GetLastComputedRiskAmount();

// execution‑state observability
      snap.take_profit  = PositionGetDouble(POSITION_TP);
      snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);

// geometry (ENTRY‑anchored)
      snap.stoploss_points =
         ctx.ATREntry.Value * inpSLxATRxPlier;

      snap.value_per_point =
         tick_value /
         tick_size;

      BeginMMCycle(MM_EVENT_TRAIL);
      EmitSnapshotBefore(snap);



      if(m_trail.Evaluate(ctx, inpTrailStartATR, inpTrailATR, newSL))
         {
         double oldSL = PositionGetDouble(POSITION_SL);
         double tp    = PositionGetDouble(POSITION_TP);

         if(m_exec.ModifyStopLoss(symbol, newSL))
            {
            // ----------------------------------------------------
            // TRAILING STOP LOGGING — Phase 4.4
            // ----------------------------------------------------
            MM_LogEventBase evt;
            evt.event_time = ctx.Time;                // BAR_SIGNAL time
            evt.event_type = MM_EVENT_TRAIL;
            evt.phase      = MM_PHASE_MANAGE;
            evt.symbol     = ctx.Symbol;
            evt.timeframe  = ctx.EntryPeriod;
            evt.trade_id   = (long)ticket; // Dedicated trade_id generator inside CTradeEngine (Later/Phase 5)
            evt.ticket     = ticket;

            m_logger.LogMMEventBase(evt);


            }


// ==================================
// MM_SNAPSHOT_AFTER — TRAILING STOP
// ==================================
         MM_SNAPSHOT_AFTER snap_after;
         snap_after.timestamp = TimeCurrent();
         snap_after.symbol    = ctx.Symbol;
         snap_after.timeframe = ctx.EntryPeriod;

// lifecycle intent
         snap_after.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
         snap_after.mm_event_result = ToMMEventString(MM_EVENT_TRAIL);

// exposure remains unchanged
         snap_after.calculated_lot_size =
            PositionGetDouble(POSITION_VOLUME);

// ENTRY risk anchor unchanged
         snap_after.calculated_risk_amount =
            m_risk.GetLastComputedRiskAmount();

// updated execution state
         snap_after.take_profit  = PositionGetDouble(POSITION_TP);
         snap_after.realized_pnl = PositionGetDouble(POSITION_PROFIT);

// geometry unchanged
         snap_after.stoploss_points = snap.stoploss_points;
         snap_after.value_per_point = snap.value_per_point;

         EmitSnapshotAfter(snap_after);
         EndMMCycleCheck();

         }
   }

   void ManageExit(const string symbol)
   {
// --------------------------------------------------
// Cache symbol info once per tick (efficiency)
// --------------------------------------------------
      const double bid        = SymbolInfoDouble(symbol, SYMBOL_BID);
      const double ask        = SymbolInfoDouble(symbol, SYMBOL_ASK);
      const double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      const double tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      if(!PositionSelect(symbol)) return;

      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);
      enum_position dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? Long : Short);

      // --- Exit signal evaluation ---
      ExitPSARParams ps{inpPSAR_Steps, inpPSAR_Max};
      ExitRVIParams rv{(int)inpRVI_Period};

      // =====================================================
      // EXIT DECISION
      // ====================================================
      if(!m_exit.Update(symbol, inpEntryPeriod, dir, inpExitIndicator, ps, rv, inpExitMode))
         return;

      TradeContext ctx;
      ctx.Symbol = symbol;
      ctx.Time   = iTime(symbol, inpEntryPeriod, BAR_CURRENT);
      ctx.Exit.ShouldExit = true;
      ctx.Exit.Reason    = EXIT_REVERSAL;
      RejectionReason reject_reason = REJECT_NONE;
// ==========================
// MM_SNAPSHOT_BEFORE — EXIT
// ==========================
      MM_SNAPSHOT_BEFORE snap;
      snap.timestamp = TimeCurrent();
      snap.symbol    = ctx.Symbol;
      snap.timeframe = ctx.EntryPeriod;

// identity
      snap.trade_context_id = ticket;

// lifecycle intent
      snap.mm_phase        = ToMMPhaseString(MM_PHASE_EXIT);
      snap.mm_event_intent = ToMMEventString(MM_EVENT_EXIT);

// --- Market Context (Schema v1.1) ---
      snap.current_price =
         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         ? bid
         : ask;

// ATR value actually used by MM (NOT recomputed)
      snap.atr_value = ctx.ATREntry.Value;

// account state
      snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
      snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
      snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

// exposure before exit
      snap.current_position_lots =
         PositionGetDouble(POSITION_VOLUME);

      snap.current_risk_exposure =
         m_risk.GetLastComputedRiskAmount();

// execution‑state observability
      snap.take_profit  = PositionGetDouble(POSITION_TP);
      snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);

// geometry (ENTRY‑anchored)
      snap.stoploss_points =
         ctx.ATREntry.Value * inpSLxATRxPlier;

      snap.value_per_point = tick_value / tick_size;

      BeginMMCycle(MM_EVENT_EXIT);
      EmitSnapshotBefore(snap);

      // Phase 5 — Step 6: Lifecycle EXIT (pass-through)
      m_lifecycleController.RequestAction(
         0,               // trade_id not enforced yet
         ACTION_EXIT,
         reject_reason
      );

      // ✅ ACTUAL CLOSE
      if(!m_exec.ExecuteExit(ctx))
         return;


// =========================
// MM_SNAPSHOT_AFTER — EXIT
// =========================
      MM_SNAPSHOT_AFTER snap_after;
      snap_after.timestamp = TimeCurrent();
      snap_after.symbol    = ctx.Symbol;
      snap_after.timeframe = ctx.EntryPeriod;

// lifecycle intent
      snap_after.mm_phase        = ToMMPhaseString(MM_PHASE_EXIT);
      snap_after.mm_event_result = ToMMEventString(MM_EVENT_EXIT);

// exposure after exit (zero)
      snap_after.calculated_lot_size = 0.0;

// entry risk anchor (for final audit)
      snap_after.calculated_risk_amount =
         m_risk.GetLastComputedRiskAmount();

// final outcome
      snap_after.take_profit  = snap.take_profit;
      snap_after.realized_pnl = snap.floating_pnl;

// geometry unchanged
      snap_after.stoploss_points = snap.stoploss_points;
      snap_after.value_per_point = snap.value_per_point;

      EmitSnapshotAfter(snap_after);
      EndMMCycleCheck();

      // ✅ EXIT LOGGING — Phase 4.4
      MM_LogEventBase evt;
      evt.event_time = ctx.Time;
      evt.event_type = MM_EVENT_EXIT;
      evt.phase      = MM_PHASE_EXIT;
      evt.symbol     = ctx.Symbol;
      evt.timeframe  = ctx.EntryPeriod;
      evt.trade_id   = (long)ticket; // Dedicated trade_id generator inside CTradeEngine (Later/Phase 5)
      evt.ticket     = ticket;


      m_logger.LogMMEventBase(evt);


      // Phase 5 — Step 6: Lifecycle CLOSE (pass-through)
      m_lifecycleController.RequestAction(
         0,               // trade_id not enforced yet
         ACTION_CLOSE,
         reject_reason
      );

      // ✅ Clean up tracker state
      m_atrTracker.RemoveTicket(ticket);
   }




private:
   // ============================================================
   // Candle detection
   // ============================================================
   bool IsNewCandle(const string symbol, ENUM_TIMEFRAMES tf)
   {
      datetime t = iTime(symbol, tf, BAR_CURRENT);
      if(t > m_lastCandleTime)
         {
         m_lastCandleTime = t;
         return true;
         }
      return false;
   }

   bool BuildTradeContext(TradeContext &ctx, const string symbol)
   {
      ctx.Reset();
      ctx.Symbol = symbol;
      ctx.EntryPeriod = inpEntryPeriod;
      ctx.TopdownPeriod = inpTopdownPeriod;
      ctx.Time    = iTime(symbol, inpEntryPeriod, BAR_SIGNAL);

      // 1) Baseline
      uint period = (inpBaselineInd == MA ? inpIMA_Period : inpSWMA_Period);
      ENUM_MA_METHOD meth = (inpBaselineInd == MA ? inpIMA_Method : (ENUM_MA_METHOD)0);
      ENUM_APPLIED_PRICE pr = PRICE_CLOSE;
      // ---- Entry TF baseline ----
      if(!m_baseline.Update(symbol, inpEntryPeriod, inpBaselineInd, period, inpIMA_Shift, meth, pr, inpATRinterval, inpBLxATRxPlier))
         return false;

      ctx.BaselineEntry = m_baseline.Result();
      ctx.BaselineEntryPrice = m_baseline.Base();  // ✅ NEW

// -------------------------------------------------
// Baseline Cross Detection (BAR_PREVIOUS → BAR_SIGNAL)
// -------------------------------------------------
      double prevClose = iClose(symbol, inpEntryPeriod, BAR_PREVIOUS);
      double currClose = iClose(symbol, inpEntryPeriod, BAR_SIGNAL);
      double baseline  = ctx.BaselineEntryPrice;

      ctx.BaselineCrossDirection = NoTrade;

      if(prevClose < baseline && currClose > baseline)
         {
         ctx.BaselineCrossDirection = Long;
         }
      else if(prevClose > baseline && currClose < baseline)
         {
         ctx.BaselineCrossDirection = Short;
         }
      // ---- Topdown TF baseline ----
      if(!m_baseline.Update(symbol, inpTopdownPeriod, inpBaselineInd, period, inpIMA_Shift, meth, pr, inpATRinterval, inpBLxATRxPlier))
         return false;

      ctx.BaselineTopdown = m_baseline.Result();



      // 2) Volume (TTMS gate)
      TTMSParams tp;
      tp.bbPeriod = (int)inpBBperiod;
      tp.bbDev    = inpBBdeviation;
      tp.kPeriod  = (int)inpKperiod;
      tp.kMethod  = inpKmethod;
      tp.kDev     = inpKdeviation;
      if(!m_volume.UpdateTTMS(symbol, inpEntryPeriod, tp))
         {
         DebugPrint(m_debug, "TTMS update failed.", DBG_WARN);
         // Gate fails safe inside ctx.Finalize()
         }
      ctx.VolumeEntry = m_volume.Result();

      // 3) Confirmation
      PSARParams ps;
      ps.step = inpPSAR_Steps;
      ps.max = inpPSAR_Max;
      RVIParams  rv;
      rv.period = (int)inpRVI_Period;
      KuskusParams ku;
      ku.rPeriod = 0;
      ku.pSmooth = 0;
      ku.iSmooth = 0;

      if(!m_confirm.UpdateDual(symbol, inpEntryPeriod,
                               inpConfirmPrimary, inpConfirmSecondary,
                               ps, rv, ku))
         {
         DebugPrint(m_debug, "Confirmation update failed.", DBG_WARN); // ctx.Finalize() will block if Confirm.IsValid false
         return false;
         };

      // Apply volume to confirmation (gate+boost already inside ApplyVolumeGate in your confirmation file)
      m_confirm.ApplyVolumeGate(ctx.VolumeEntry);
      ctx.ConfirmEntry = m_confirm.Result();

      // 4) ATR (for sizing)
      if(!m_atr.Update(symbol, inpEntryPeriod, (int)inpATRinterval, BAR_SIGNAL))
         {
         DebugPrint(m_debug, "ATR update failed.", DBG_WARN);
         return false;
         }
      ctx.ATREntry = m_atr.Result();

      // 5) Decide
      ctx.RequireVolumeGate = true;  // Option A
      ctx.MinConfirmScore   = 60;    // tune if needed
      ctx.EnableTopDown       = inpEnableTopDown;
      ctx.RequireTopDownAlign = inpRequireTopDownAlign;
      ctx.Finalize();

      // 6) SIGNAL SNAPSHOT — exactly once per candle
      SignalSnapshot snap = BuildSignalSnapshot(ctx);



      /*
      ctx.EntryBias = (ctx.BaselineEntry.trend == TrendUp ? Long :
                       ctx.BaselineEntry.trend == TrendDown ? Short : NoTrade);
      ctx.IsTradeable = (ctx.EntryBias != NoTrade);
      */
      return ctx.IsTradeable;

   }

};

#endif // __LIBCTRADEENGINE_MQH__







/*
✅ What Changed vs Your Old Engine (High-Level)
✅ Entry is now fully TradeContext-driven

Baseline computed once → stored in ctx.Baseline
Volume TTMS computed once → stored in ctx.Volume
Confirmation dual computed once → stored in ctx.Confirm
Volume gate applied inside confirmation + again inside ctx.Finalize() for deterministic blocking
ATREntry computed once → stored in ctx.ATREntry
ctx.Finalize() sets:

ctx.EntryBias
ctx.IsTradeable



✅ Volume Option A is enforced end-to-end
If TTMS squeeze is OFF, entry is blocked.
✅ Risk sizing is now deterministic and ATREntry-based

Stop distance = ATREntry * inpSLxATRxPlier
Lots = RiskAmount / (StopPoints * valuePerPoint)

✅ Exit uses your preferred mode: RVI CROSS
And supports PSAR reversal exit as well.

Integration in Your EA (Example)
In your EA .mq5:

#include <MyInclude\libCTradeEngine.mqh>

CTradeEngine engine;

int OnInit()
{
   engine.Init();
   return INIT_SUCCEEDED;
}

void OnTick()
{
   engine.OnTick(_Symbol);
}







*/
//+------------------------------------------------------------------+
