//+------------------------------------------------------------------+
//|                                              libCTradeEngine.mqh |
//|                                                     Marteo Cosme |
//|                               Updated: 2026-04-03 (TradeContext) |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBCTRADEENGINE_MQH__
#define __LIBCTRADEENGINE_MQH__



// ================================================================
// Compile-time Feature Gate: TradeLifecycleController (Default ON)
// DISABLED BUILD: set DISABLE_LIFECYCLE_CONTROLLER
// ================================================================

// --- FORCE DISABLE (comment out to re-enable)
#define DISABLE_LIFECYCLE_CONTROLLER

// Default: ENABLED unless explicitly disabled
#ifndef DISABLE_LIFECYCLE_CONTROLLER
#define ENABLE_LIFECYCLE_CONTROLLER
#endif


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
#include <MyInclude\NNFX\libCATREntryTracker.mqh>
#include <MyInclude\NNFX\libCTradeExecution.mqh>



// ---- Context & visualization
#include <MyInclude\NNFX\libCTradeContext.mqh>
#include <MyInclude\NNFX\libCTradeVisualizer.mqh>
#include <MyInclude\NNFX\libCUnifiedTradeLogger.mqh>
#include <MyInclude\NNFX\TradeEngine\TradeLifecycleController.mqh>




// --------------------------------------------------
// MM Snapshot (Phase 5 / MM-LOG-01 — incremental stub)
// --------------------------------------------------
struct MM_SNAPSHOT_BEFORE;
struct MM_SNAPSHOT_AFTER;


struct SymbolCache
{
   string symbol;
   double bid;
   double ask;
   double tick_value;
   double tick_size;
};


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

// ---- Volume
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

// ---- Diagnostics
input group "Diagnostics"
input bool inpEnableTradeVisualizer = false; // Enable chart drawings (debug/visual only)
input group "-----"

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
   CATREntryTracker     m_atrTracker;
   CTradeExecution      m_exec;

   CEntryStrategyEngine m_entryStrategy;
   enum_entryStrategy m_activeStrategy;

   CBreakEvenEngine     m_be;
   CPartialCloseEngine  m_scale;
   CTrailingStopEngine  m_trail;
   CExitSignal          m_exit;


   CTradeVisualizer     m_viz;
   CUnifiedTradeLogger  m_logger;

   int                  m_cycle_id;
   datetime             m_lastCandleTime;

   //Lifecycle Summary Event
   int                  m_scale_count;
   int                  m_trail_count;
   bool                 m_be_triggered;

   double               m_entry_price;
   datetime             m_entry_time;
   double               m_cycle_realized_pnl; // ✅ NEW: tracks total pnl per cycle
   double               m_cycle_traded_volume; // ✅ NEW: total traded volume per cycle

   // --------------------------------------------------
   // Phase 5 — Trade Lifecycle Orchestration
   // Step 3: Embedded controller (unused for now)
   // --------------------------------------------------

#ifdef ENABLE_LIFECYCLE_CONTROLLER
   TradeLifecycleController m_lifecycleController;
#endif


// ======================================
// CLOSE EVENT TRACKING (Step C1)
// ======================================
   bool  m_was_position_open;
   ulong m_last_ticket;
   double m_last_volume;
   long m_last_position_id;   // POSITION_IDENTIFIER (lifecycle id)


// ============================================================
// INF-3 Snapshot Enforcement State
// ============================================================
   bool m_before_emitted;
   bool m_after_emitted;
   ENUM_MM_EVENT_TYPE m_current_event;

   ulong m_next_correlation_id;
   ulong m_current_correlation_id;

// ============================================================
// v2.0 Outcome Buffer (Option C1: SUCCESS/FAIL/SKIP)
// Filled by action block, consumed by EmitSnapshotAfter()
// ============================================================
   bool   m_out_action_executed;
   string m_out_execution_reason;
   double m_out_previous_stoploss;
   double m_out_new_stoploss;
   double m_out_closed_lots;
   string m_out_event_outcome;      // "SUCCESS" | "FAIL" | "SKIP"

   string m_last_position_type;     // "LONG" | "SHORT" | "NA"





   void BeginMMCycle(ENUM_MM_EVENT_TYPE evt)
   {
      m_current_event = evt;
      m_before_emitted = false;
      m_after_emitted  = false;
      m_current_correlation_id = ++m_next_correlation_id;


// Reset v2.0 outcome buffer (Option C1)
      m_out_previous_stoploss   = 0.0;
      m_out_new_stoploss        = 0.0;
      m_out_closed_lots         = 0.0;
      m_out_execution_reason    = "NOT_ELIGIBLE";
      m_out_event_outcome       = "SKIP";  // default until proven SUCCESS or FAI
      m_out_action_executed     = false;

   }

   void AssignCloseCorrelationId(MM_LogEventBase &evt)
   {
      // Preserve correlation only when CLOSE is the broker-confirmed result
      // of an explicit engine-driven EXIT action.
      const bool preserve_exit_correlation =
         (m_current_event == MM_EVENT_EXIT &&
          evt.close_reason == "MM_EXPERT: Exit Signal");

      if(preserve_exit_correlation)
         return;

      // Broker-driven or externally detected closes must get their own
      // action-level correlation_id.
      m_current_correlation_id = ++m_next_correlation_id;
      evt.correlation_id = m_current_correlation_id;
   }


   string PositionTypeToString(const enum_position p) const
   {
      if(p == Long)  return "LONG";
      if(p == Short) return "SHORT";
      return "NA"; // NoTrade or any other value
   }

   enum_position GetLivePositionDirection(const string symbol) const
   {
      if(!PositionSelect(symbol))
         return NoTrade;

      const long ptype = (long)PositionGetInteger(POSITION_TYPE);
      return (ptype == POSITION_TYPE_BUY ? Long : Short);
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

   void EmitSnapshotBefore(const MM_SNAPSHOT_BEFORE &snap)
   {
      MM_LogSnapshotBefore rec;
      ZeroMemory(rec);

      // Timing / classification
      rec.timestamp = snap.timestamp;
      rec.symbol    = snap.symbol;
      enum_position liveDir = GetLivePositionDirection(rec.symbol);
      string pt = PositionTypeToString(liveDir);
      rec.position_type = (pt != "NA" ? pt : m_last_position_type);
      rec.timeframe = snap.timeframe;

      // Correlation
      rec.correlation_id = m_current_correlation_id;

      // Identity (v2.0)
      rec.cycle_id = (snap.cycle_id > 0 ? snap.cycle_id : m_cycle_id);
      rec.internal_trade_id = (long)rec.cycle_id;

      // Ticket/PositionId from LIVE state if possible (now rec.symbol is set)
      ulong live_ticket = 0;
      long  live_posid  = 0;
      if(TryGetLiveIdentity(rec.symbol, live_ticket, live_posid))
         {
         rec.ticket = live_ticket;
         rec.position_id = live_posid;
         }
      else
         {
         // fallback to cached
         rec.ticket = m_last_ticket;
         rec.position_id = m_last_position_id;
         }

      // Classification
      rec.mm_phase  = snap.mm_phase;
      rec.mm_event  = snap.mm_event_intent;

      // Full-state (already present in BEFORE snap)
      rec.balance = snap.balance;
      rec.equity  = snap.equity;
      rec.free_margin = snap.free_margin;

      rec.current_position_lots = snap.current_position_lots;
      rec.current_risk_exposure = snap.current_risk_exposure;

      rec.current_price = snap.current_price;
      rec.atr_value      = snap.atr_value;

      rec.take_profit   = snap.take_profit;
      rec.floating_pnl  = snap.floating_pnl;
      rec.realized_pnl  = 0.0;

      rec.stoploss_points = snap.stoploss_points;
      rec.value_per_point = snap.value_per_point;

      // Risk inputs actually used (you already set these in ENTRY snap)
      rec.risk_model = CurrentRiskModelString();
      rec.risk_value = CurrentRiskValue();
      rec.risk_amount_used = snap.current_risk_exposure;

      rec.scale_atr_multiple = snap.scale_atr_multiple;
      rec.scale_fraction     = snap.scale_fraction;

      // Outcome defaults for BEFORE (neutral)
      rec.action_executed   = false;
      rec.execution_reason  = "";
      rec.previous_stoploss = 0.0;
      rec.new_stoploss      = 0.0;
      rec.closed_lots       = 0.0;
      rec.event_outcome     = "";

      m_logger.LogMMSnapshotBefore(rec);
      m_before_emitted = true;

   }

   void EmitSnapshotAfter(const MM_SNAPSHOT_AFTER &snap)
   {
      MM_LogSnapshotAfter rec;
      ZeroMemory(rec);

      // Timing
      rec.timestamp = snap.timestamp;
      rec.symbol    = snap.symbol;
      enum_position liveDir = GetLivePositionDirection(rec.symbol);
      string pt = PositionTypeToString(liveDir);
      rec.position_type = (pt != "NA" ? pt : m_last_position_type);
      rec.timeframe = snap.timeframe;

      // Correlation
      rec.correlation_id = m_current_correlation_id;

      // Identity (v2.0)
      rec.cycle_id = (m_cycle_id);                    // lifecycle grouping
      rec.internal_trade_id = (long)m_cycle_id;       // temporary: internal == cycle

      ulong live_ticket = 0;
      long  live_posid  = 0;
      if(TryGetLiveIdentity(rec.symbol, live_ticket, live_posid))
         {
         rec.ticket = live_ticket;
         rec.position_id = live_posid;
         }
      else
         {
         rec.ticket = m_last_ticket;
         rec.position_id = m_last_position_id;
         }

      // Classification
      rec.mm_phase  = snap.mm_phase;
      rec.mm_event  = snap.mm_event_result;

      // FULL-STATE: account always available
      rec.balance = AccountInfoDouble(ACCOUNT_BALANCE);
      rec.equity  = AccountInfoDouble(ACCOUNT_EQUITY);
      rec.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      // FULL-STATE: derive from live position if exists
      bool pos_exists = PositionSelect(rec.symbol);
      rec.current_position_lots = pos_exists ? PositionGetDouble(POSITION_VOLUME) : 0.0;
      rec.current_risk_exposure = snap.current_risk_exposure;

      // Market context
      double bid = SymbolInfoDouble(rec.symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(rec.symbol, SYMBOL_ASK);
      if(pos_exists)
         {
         bool is_buy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
         rec.current_price = is_buy ? bid : ask;
         }
      else
         {
         rec.current_price = bid; // fallback
         }

      // ATR anchor: use tracker when possible
      if(rec.ticket > 0)
         {
         if(rec.mm_event == "MM_EVENT_ENTRY")
            rec.atr_value = snap.atr_value;
         else if(rec.ticket > 0)
            rec.atr_value = m_atrTracker.GetATR(rec.ticket);
         else
            rec.atr_value = 0.0;
         }

      // Guard against invalid/sentinel values such as DBL_MAX
      if(rec.atr_value <= 0.0 || rec.atr_value >= 1e100)
         {
         rec.atr_value = 0.0;
         }

      // Execution state
      rec.take_profit  = pos_exists ? PositionGetDouble(POSITION_TP) : snap.take_profit;
      rec.floating_pnl = pos_exists ? PositionGetDouble(POSITION_PROFIT) : 0.0;
      rec.realized_pnl = snap.realized_pnl;

      rec.stoploss_points = snap.stoploss_points;
      rec.value_per_point = snap.value_per_point;

      // Risk inputs actually used (best-effort; fill from config + last computed)
      rec.risk_model = CurrentRiskModelString();
      rec.risk_value = CurrentRiskValue();
      rec.risk_amount_used = rec.current_risk_exposure;

      // Scale context: if not applicable, keep 0
      rec.scale_atr_multiple = 0.0;
      rec.scale_fraction     = 0.0;


      // v2.0 Outcome (Option C1)
      rec.action_executed   = m_out_action_executed;
      rec.execution_reason  = m_out_execution_reason;
      rec.previous_stoploss = m_out_previous_stoploss;
      rec.new_stoploss      = m_out_new_stoploss;
      rec.closed_lots       = m_out_closed_lots;
      rec.event_outcome     = m_out_event_outcome;

      // Safety normalization
      if(rec.execution_reason == "")
         {
         // If not executed, reason must not be blank
         if(!rec.action_executed)
            rec.execution_reason = "NOT_ELIGIBLE";
         }
      if(rec.event_outcome == "")
         rec.event_outcome = "SKIP";

      m_logger.LogMMSnapshotAfter(rec);
      m_after_emitted = true;

   }

   void EmitCloseEvent(const string symbol)
   {

      if(m_last_ticket <= 0)
         return;

      MM_LogEventBase evt;
      InitMMEvent(evt, MM_EVENT_CLOSE, MM_PHASE_EXIT, symbol, m_last_ticket, TimeCurrent());
      evt.action_summary = "Closed Trade (engine-detected)";

      // ✅ Always set a non-blank default (ZeroMemory makes string "")
      evt.close_reason = "UNKNOWN";

      // fetch broker-confirmed deal info
      ulong  deal_id = 0;
      double price   = 0.0;
      double profit  = 0.0;
      double volume  = 0.0;
      string reason  = "UNKNOWN";

      bool found = GetLastCloseDealByPosition(m_last_position_id, deal_id, price, profit, volume, reason);

      // evt.scale_steps = 0;
      // evt.scale_fraction_total = 0.0;

      // ✅ E2 fields (safe placeholders for now)
      // defaults (must NOT be blank)

      evt.close_price  = 0.0;
      evt.close_profit = 0.0;
      evt.close_volume = 0.0;
      evt.deal_id      = 0;

      if(found)
         {
         // ✅ Guard against empty reason coming from anywhere
         if(reason == "")
            reason = "UNKNOWN";

         evt.close_reason = reason;
         // evt.close_reason = (reason == "" ? "UNKNOWN" : reason);
         evt.close_price  = price;
         evt.close_profit = profit;
         m_cycle_realized_pnl += profit; // ✅ add final leg pnl
         evt.close_volume = volume;
         m_cycle_traded_volume += volume; // ✅ final volume
         evt.deal_id      = deal_id;
         }
      else
         {
         // keep UNKNOWN (not blank)
         // evt.close_reason = "UNKNOWN";
         evt.close_price  = SymbolInfoDouble(symbol, SYMBOL_BID);
         evt.close_profit = 0.0;
         evt.close_volume = m_last_volume;
         evt.deal_id      = 0;
         }

      AssignCloseCorrelationId(evt);
      Print("CLOSE DEBUG -> reason=[", evt.close_reason, "] deal=", evt.deal_id,
            " price=", evt.close_price, " profit=", evt.close_profit);

      m_logger.LogMMEventBase(evt);

      Print("✅ MM_EVENT_CLOSE emitted | Ticket=", m_last_ticket,
            " Cycle=", m_cycle_id);


      // ============================================
      // ✅ CYCLE SUMMARY AT CLOSE (CORRECT LOCATION)
      // ============================================

      MM_LogCycleSummary summary;
      ZeroMemory(summary);


      // --- Identity ---
      summary.cycle_id = m_cycle_id;
      summary.internal_trade_id = (long)m_cycle_id;   // v2.1 rule: internal_trade_id == cycle_id for now
      summary.trade_id = (long)m_last_ticket;         // legacy-compatible alias
      summary.ticket = m_last_ticket;
      summary.position_id = m_last_position_id;
      summary.position_type = (m_last_position_type == "" ? "NA" : m_last_position_type);

      // --- Symbol / Lifecycle Timing ---
      summary.symbol = symbol;
      summary.entry_time = m_entry_time;
      summary.exit_time = TimeCurrent();

      summary.duration_sec = (int)(summary.exit_time - summary.entry_time);
      if(summary.duration_sec < 0)
         summary.duration_sec = 0;

      // --- Price / PnL ---
      summary.entry_price = m_entry_price;
      summary.exit_price = evt.close_price;
      // summary.pnl = evt.close_profit; // ❌ BUG
      summary.pnl = m_cycle_realized_pnl; // ✅ FIXED

      // --- Lifecycle Aggregates ---
      summary.scale_count = m_scale_count;
      summary.trail_count = m_trail_count;
      summary.be_triggered = m_be_triggered;
      // summary.total_traded_volume = m_cycle_traded_volume;

      // --- Broker Close Evidence ---
      summary.close_reason = (evt.close_reason == "" ? "UNKNOWN" : evt.close_reason);
      summary.close_volume = m_cycle_traded_volume;
      summary.deal_id = evt.deal_id;

      // --- Lifecycle Status ---
      summary.lifecycle_status = "CLOSED";

      // ✅ Emit
      m_logger.LogCycleSummary(summary);

   }

   bool GetLastCloseDeal__DEPRECATED(const string symbol,
                                     ulong &deal_id,
                                     double &price,
                                     double &profit,
                                     double &volume,
                                     string &reason)
   {
      datetime to   = TimeCurrent();
      datetime from = to - 86400; // last 24 hours

      if(!HistorySelect(from, to))
         return false;

      int total = HistoryDealsTotal();

      for(int i = total - 1; i >= 0; i--)
         {
         ulong deal_ticket = HistoryDealGetTicket(i);

         if(deal_ticket <= 0)
            continue;

         string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
         if(deal_symbol != symbol)
            continue;

         int entry_type = (int)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);

         // ✅ Only closing deals
         if(entry_type != DEAL_ENTRY_OUT)
            continue;

         // ✅ We found the CLOSE deal
         deal_id = deal_ticket;
         price   = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
         profit  = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
         volume  = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);

         const int reason_code = (int)HistoryDealGetInteger(deal_ticket, DEAL_REASON);

         reason = MapDealReasonToString(reason_code, REASON_CTX_CLOSE);
         if (reason == "") reason = "UNKNOWN";

         return true;
         }

      return false;
   }

   bool GetLastCloseDealByPosition(const long position_id,
                                   ulong &deal_id,
                                   double &price,
                                   double &profit,
                                   double &volume,
                                   string &reason)
   {
      deal_id = 0;
      price = 0.0;
      profit = 0.0;
      volume = 0.0;
      reason = "UNKNOWN";

      if(position_id <= 0)
         return false;

      // Load only deals/orders for this position identifier
      if(!HistorySelectByPosition((ulong)position_id))
         return false; // HistorySelectByPosition failed (position-scoped history not available

      const int total = (int)HistoryDealsTotal();
      ulong best_ticket = 0;
      long  best_time_msc = -1;

      for(int i = 0; i < total; i++)
         {
         const ulong t = HistoryDealGetTicket(i);
         if(t == 0) continue;

         const long entry = HistoryDealGetInteger(t, DEAL_ENTRY);
         if(!IsClosingDealEntry(entry))
            continue;

         const long tmsc = HistoryDealGetInteger(t, DEAL_TIME_MSC);
         if(tmsc > best_time_msc)
            {
            best_time_msc = tmsc;
            best_ticket = t;
            }
         }

      if(best_ticket == 0)
         return false;

      // Extract broker-confirmed deal details
      deal_id = best_ticket;
      price   = HistoryDealGetDouble(best_ticket, DEAL_PRICE);
      profit  = HistoryDealGetDouble(best_ticket, DEAL_PROFIT);
      volume  = HistoryDealGetDouble(best_ticket, DEAL_VOLUME);

      const int reason_code = (int)HistoryDealGetInteger(best_ticket, DEAL_REASON);
      reason = MapDealReasonToString(reason_code, REASON_CTX_CLOSE);
      if(reason == "") reason = "UNKNOWN";

      return true;
   }


   bool GetRecentPartialCloseDeal(const long position_id,
                                  const double expected_volume,
                                  const int lookback_sec,
                                  ulong &deal_id,
                                  double &price,
                                  double &profit,
                                  double &volume,
                                  string &reason)
   {
      deal_id = 0;
      price = 0.0;
      profit = 0.0;
      volume = 0.0;
      reason = "UNKNOWN";

      if(position_id <= 0 || expected_volume <= 0.0)
         return false;

      if(!HistorySelectByPosition((ulong)position_id))
         return false; // HistorySelectByPosition failed.

      const long now_msc = (long)TimeCurrent() * 1000;
      const long min_msc = now_msc - (long)lookback_sec * 1000;

      ulong best_ticket = 0;
      long  best_time_msc = -1;

      const int total = (int)HistoryDealsTotal();
      for(int i = 0; i < total; i++)
         {
         const ulong t = HistoryDealGetTicket(i);
         if(t == 0) continue;

         const long entry = HistoryDealGetInteger(t, DEAL_ENTRY);
         if(!IsClosingDealEntry(entry))
            continue;

         const long tmsc = HistoryDealGetInteger(t, DEAL_TIME_MSC);
         if(tmsc < min_msc)
            continue;

         const double v = HistoryDealGetDouble(t, DEAL_VOLUME);

         // Small tolerance for broker rounding
         if(MathAbs(v - expected_volume) > 0.0000001)
            continue;

         if(tmsc > best_time_msc)
            {
            best_time_msc = tmsc;
            best_ticket = t;
            }
         }

      if(best_ticket == 0)
         return false;

      deal_id = best_ticket;
      price   = HistoryDealGetDouble(best_ticket, DEAL_PRICE);
      profit  = HistoryDealGetDouble(best_ticket, DEAL_PROFIT);
      volume  = HistoryDealGetDouble(best_ticket, DEAL_VOLUME);

      const int reason_code = (int)HistoryDealGetInteger(best_ticket, DEAL_REASON);
      reason = MapDealReasonToString(reason_code, REASON_CTX_SCALEOUT);
      if(reason == "") reason = "UNKNOWN";

      return true;
   }


   enum ENUM_REASON_CONTEXT
   {
      REASON_CTX_CLOSE,
      REASON_CTX_SCALEOUT
   };


   string MapDealReasonToString(const int reason_code, const ENUM_REASON_CONTEXT ctx)
   {
      switch(reason_code)
         {
         case DEAL_REASON_CLIENT:
            return "MANUAL_DESKTOP_TERMINAL";
         case DEAL_REASON_MOBILE:
            return "MANUAL_MOBILE_APP";
         case DEAL_REASON_WEB:
            return "MANUAL_WEB_PLATFORM";
         case DEAL_REASON_EXPERT:
            if(ctx == REASON_CTX_CLOSE)    return "MM_EXPERT: Exit Signal";
            if(ctx == REASON_CTX_SCALEOUT) return "MM_EXPERT: Scale Out";
            return "MM_EXPERT";
         case DEAL_REASON_TP:
            return "TP_HIT";
         case DEAL_REASON_SL:
            return "SL_HIT";
         case DEAL_REASON_SO:
            return "STOP_OUT Event";
         case DEAL_REASON_ROLLOVER:
            return "ROLLOVER";
         case DEAL_REASON_VMARGIN:
            return "VARIATION_MARGIN";
         case DEAL_REASON_CORPORATE_ACTION:
            return "CORPORATE_ACTION";
         case DEAL_REASON_SPLIT:
            return "SPLIT_ANNOUNCEMENT";
         default:
            return "UNKNOWN";
         }
   }



   static bool IsClosingDealEntry(const long entry)
   {
      // OUT = standard close
      // OUT_BY = close-by (hedging)
      // INOUT = reversal (netting)
      return (entry == DEAL_ENTRY_OUT ||
              entry == DEAL_ENTRY_OUT_BY ||
              entry == DEAL_ENTRY_INOUT);
   }



public:
   CTradeEngine() : m_lastCandleTime(0)
   {
      m_was_position_open = false;
      m_last_position_id  = 0;
      m_last_ticket = 0;
      m_last_volume = 0.0;

      m_next_correlation_id = 0;
      m_current_correlation_id = 0;
      m_last_position_type = "NA";

   }

   CTradeEngine::~CTradeEngine()
   {
      // Clean up if needed
   }


   void Init()
   {
      m_cycle_id = 0;

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

   void UpdateCloseDetection(const string symbol)
   {
      bool is_position_open = PositionSelect(symbol);

      // Detect transition: was open → now closed
      if(m_was_position_open && !is_position_open)
         {
         EmitCloseEvent(symbol);
         }

      // Update tracking state
      m_was_position_open = is_position_open;

      // Capture last known position when open
      if(is_position_open)
         {
         m_last_ticket = (ulong)PositionGetInteger(POSITION_TICKET);
         m_last_volume = PositionGetDouble(POSITION_VOLUME);
         m_last_position_id = (long)PositionGetInteger(POSITION_IDENTIFIER);

         long dir = (long)PositionGetInteger(POSITION_TYPE);
         m_last_position_type = PositionTypeToString(GetLivePositionDirection(symbol));

         }
   }


   // To be called in OnTick EA
   void OnTick(const string symbol)
   {
      if(symbol == "") return;
      SymbolCache cache;
      if(!BuildSymbolCache(symbol, cache))
         {
         // If cache can't be built, still run close detection (optional),
         // but skip trading logic that depends on valid tick_size/bid/ask.
         UpdateCloseDetection(symbol);
         return;
         }

      ManageExit(symbol, cache); // Manage exits continuously (optional: only on new candle | setup runtime gating to run OnTick/NewCandle)

      if(!IsNewCandle(symbol, inpEntryPeriod))
         {
         UpdateCloseDetection(symbol);
         return; // Only evaluate entry on new candle (BAR_SIGNAL is stable)
         }

      m_atrTracker.PruneClosedTickets(); // Maintain ATR ticket list

      ManageOpenPosition(symbol, cache);  // Manage Open Positions | ## can add input settings
      ManageEntry(symbol, cache); // Entry logic
      UpdateCloseDetection(symbol);

   }

   // --------------------------------------------------
   // ----- Manage Entry
   // --------------------------------------------------
   void ManageEntry(const string symbol, const SymbolCache &cache)
   {
      const double bid       = cache.bid;
      const double ask       = cache.ask;
      const double tick_value = cache.tick_value;
      const double tick_size = cache.tick_size;


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

      // Entry Strategy Override (v1.1)
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

      m_cycle_id++;
      m_cycle_realized_pnl = 0.0; // ✅ RESET per new cycle
      m_cycle_traded_volume = 0.0; // ✅ reset per cycle
      
      // --- MM Snapshot BEFORE (complete risk inputs) ---
      MM_SNAPSHOT_BEFORE snap;
      ZeroMemory(snap);
      snap.timestamp  = TimeCurrent();
      snap.symbol     = ctx.Symbol;
      snap.timeframe  = inpEntryPeriod;
      snap.trade_context_id = 0; // ticket not yet known
      snap.cycle_id = m_cycle_id;

      snap.mm_phase        = ToMMPhaseString(MM_PHASE_ENTRY);
      snap.mm_event_intent = ToMMEventString(MM_EVENT_ENTRY);
      snap.current_price = (ctx.EntryBias == Long) ? ask : bid;

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

      //Lifecycle Summary Event
      m_scale_count = 0;
      m_trail_count = 0;
      m_be_triggered = false;

      m_entry_price = snap.current_price;
      m_entry_time  = TimeCurrent();

      // ✅ NOW snapshot what MM actually decided
      snap.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

      // Cache intended entry direction for ENTRY BEFORE/AFTER snapshots
      m_last_position_type = PositionTypeToString(ctx.EntryBias);

      BeginMMCycle(MM_EVENT_ENTRY);
      EmitSnapshotBefore(snap);

      // Phase 5 — Step 4: Lifecycle CREATE (pass-through)
      RejectionReason reject_reason = REJECT_NONE;
#ifdef ENABLE_LIFECYCLE_CONTROLLER
      m_lifecycleController.RequestAction(
         0,                    // trade_id not assigned yet
         ACTION_CREATE,
         reject_reason
      );
#endif

      // --- EXECUTE ENTRY (execution only) ---
      bool ok = m_exec.ExecuteEntry(
                   ctx,
                   lots,
                   inpSLxATRxPlier,
                   inpTPxATRxPlier
                );

      if(ok)
         {
         m_out_action_executed  = true;
         m_out_event_outcome    = "SUCCESS";
         m_out_execution_reason = "";
         }
      else
         {
         // Entry attempt failed -> FAIL (not SKIP)
         m_out_action_executed  = false;
         m_out_event_outcome    = "FAIL";
         m_out_execution_reason = "EXECUTION_FAILED";
         }

      // ✅ MM_SNAPSHOT_AFTER (ENTRY only)
      MM_SNAPSHOT_AFTER snap_after;
      ZeroMemory(snap_after);
      snap_after.timestamp = TimeCurrent();
      snap_after.symbol    = ctx.Symbol;
      snap_after.timeframe = inpEntryPeriod;
      snap_after.mm_phase = ToMMPhaseString(MM_PHASE_ENTRY);
      snap_after.mm_event_result = ToMMEventString(MM_EVENT_ENTRY);

      snap_after.current_position_lots = lots;
      snap_after.current_risk_exposure =
         m_risk.GetLastComputedRiskAmount();
      snap_after.atr_value = ctx.ATREntry.Value;

      snap_after.stoploss_points = snap.stoploss_points;
      snap_after.value_per_point = snap.value_per_point;

      EmitSnapshotAfter(snap_after);
      EndMMCycleCheck();

      if(!ok)
         {
         DebugPrint(m_debug, "Trade execution failed.", DBG_ERROR);
         return;
         }


      // ✅ Broker accepted the order — position must exist now

      // --------------------------------------------------
      // Phase 5 — Step 4: Lifecycle ENTER (pass-through)
      // --------------------------------------------------

#ifdef ENABLE_LIFECYCLE_CONTROLLER
      m_lifecycleController.RequestAction(
         0, // existing trade_id (if already set)
         ACTION_ENTER,
         reject_reason
      );
#endif



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
      InitMMEvent(evt, MM_EVENT_ENTRY, MM_PHASE_ENTRY, ctx.Symbol, ticket, ctx.Time);
      evt.action_summary = "Open new trade";
      evt.position_type = PositionTypeToString(ctx.EntryBias);
      m_logger.LogMMEventBase(evt);
   }

   // --------------------------------------------------
   // ----- ManageOpenPosition
   // --------------------------------------------------
   void ManageOpenPosition(const string symbol, const SymbolCache &cache)
   {
      const double bid       = cache.bid;
      const double ask       = cache.ask;
      const double tick_value = cache.tick_value;
      const double tick_size = cache.tick_size;


      if(!PositionSelect(symbol)) return;

      RejectionReason reject_reason = REJECT_NONE;
      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);


      // ✅ ADD THIS (REQUIRED)
      enum_position dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? Long : Short);
      m_last_position_type = PositionTypeToString(dir);

      if(ticket <= 0) return;

      TradeContext ctx;
      ctx.Symbol = symbol;
      ctx.Time = TimeCurrent(); // Use current time for management context
      ctx.ATREntry.Value   = m_atrTracker.GetATR(ticket);
      ctx.ATREntry.IsValid = (ctx.ATREntry.Value > 0.0);

      // ------------------------------------------------
      // SCALE_OUT block (PARTIAL CLOSE)
      // ------------------------------------------------
      if(inpEnableScalingOut)
         {

         int    scale_steps = 0;
         double total_closed_fraction = 0.0;

         for(int i = 0; i < SCALE_STAGE_COUNT; i++)
            {
            // Phase 5 — Step 5: Lifecycle MM_ACTION (Scale-Out pass-through)

#ifdef ENABLE_LIFECYCLE_CONTROLLER
            m_lifecycleController.RequestAction(
               0, //ctx.trade_id,
               ACTION_MM,
               reject_reason
            );
#endif
            double closeLots = 0.0;

            // ===============================
            // MM_SNAPSHOT_BEFORE — SCALE_OUT
            // ===============================
            MM_SNAPSHOT_BEFORE snap;
            ZeroMemory(snap);
            snap.timestamp = TimeCurrent();
            snap.symbol    = ctx.Symbol;
            snap.timeframe = inpEntryPeriod;

            // identity
            snap.trade_context_id = ticket;

            // lifecycle intent
            snap.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
            snap.mm_event_intent = ToMMEventString(MM_EVENT_SCALE_OUT);

            // --- Market Context (Schema v1.1) ---
            snap.current_price = (dir == Long) ? bid : ask;

            // ATR value actually used by MM (NOT recomputed)
            snap.atr_value = ctx.ATREntry.Value;

            // account state
            snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
            snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
            snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

            // exposure BEFORE scale-out
            snap.current_position_lots = PositionGetDouble(POSITION_VOLUME);
            // reference risk (ENTRY risk anchor)
            snap.current_risk_exposure = m_risk.GetLastComputedRiskAmount(); // still valid reference

            // execution-state observability
            snap.take_profit   = PositionGetDouble(POSITION_TP);
            snap.floating_pnl  = PositionGetDouble(POSITION_PROFIT);

            // reconstruction inputs
            snap.stoploss_points = ctx.ATREntry.Value * inpSLxATRxPlier;
            snap.value_per_point = tick_value / tick_size;

            // scale context
            snap.scale_atr_multiple = g_scaleStages[i].atrMultiple;
            snap.scale_fraction     = g_scaleStages[i].closeFraction;

            // ✅ INF-3 START
            BeginMMCycle(MM_EVENT_SCALE_OUT);
            EmitSnapshotBefore(snap);

            // Default: not executed unless proven otherwise
            m_out_action_executed  = false;
            m_out_execution_reason = "NOT_ELIGIBLE";
            m_out_closed_lots      = 0.0;
            m_out_event_outcome    = "SKIP";

            // =========================
            // SAFE EXECUTION BLOCK
            // =========================
            bool scale_executed = false;

            do
               {
               if(!m_scale.Evaluate(ctx, g_scaleStages[i], closeLots))
                  {
                  m_out_action_executed  = false;
                  m_out_execution_reason = "EVALUATE_FALSE";
                  m_out_closed_lots      = 0.0;
                  m_out_event_outcome    = "SKIP";
                  break;

                  }
               if(!m_exec.PartialClose(symbol, closeLots))
                  {
                  Print("⚠️ SCALE_OUT execution failed");
                  m_out_action_executed  = false;
                  m_out_execution_reason = "EXECUTION_FAILED";
                  m_out_closed_lots      = 0.0;
                  m_out_event_outcome    = "FAIL";
                  break;
                  }

               scale_executed = true;
               m_out_action_executed  = true;
               m_out_execution_reason = "";
               m_out_closed_lots      = closeLots;
               m_out_event_outcome    = "SUCCESS";
               scale_steps++;
               m_scale_count++;
               total_closed_fraction += g_scaleStages[i].closeFraction;

               // ✅ tracker (keep this inside success)
               m_atrTracker.MarkScaleStageApplied(ticket, g_scaleStages[i].atrMultiple);


               // ----------------------------------------------------
               // SCALE-OUT LOGGING — Phase 4.4
               // ----------------------------------------------------
               // ✅ event logging (keep this inside success)
               MM_LogEventBase evt;
               InitMMEvent(evt, MM_EVENT_SCALE_OUT, MM_PHASE_MANAGE, ctx.Symbol, ticket, ctx.Time);
               evt.action_summary = "Close " + DoubleToString(total_closed_fraction * 100, 1) + "% of position";
               evt.scale_steps = scale_steps;
               evt.scale_fraction_total = total_closed_fraction;

               // ✅ Populate broker-confirmed close_* columns for SCALE_OUT
               evt.close_reason = "UNKNOWN";
               evt.close_price  = 0.0;
               evt.close_profit = 0.0;
               evt.close_volume = 0.0;
               evt.deal_id      = 0;

               ulong d = 0;
               double p = 0.0, prof = 0.0, vol = 0.0;
               string rs = "UNKNOWN";

               // Retry a couple times in case history is slightly delayed (polling model)
               bool foundDeal = false;
               for(int k = 0; k < 3 && !foundDeal; k++)
                  {
                  foundDeal = GetRecentPartialCloseDeal(m_last_position_id, closeLots, 5, d, p, prof, vol, rs);
                  if(!foundDeal) Sleep(50);
                  }

               if(foundDeal)
                  {
                  evt.deal_id      = d;
                  evt.close_price  = p;
                  evt.close_profit = prof;
                  m_cycle_realized_pnl += prof; // ✅ accumulate partial pnl
                  evt.close_volume = vol;
                  m_cycle_traded_volume += vol; // ✅ accumulate partial volume
                  evt.close_reason = (rs == "" ? "UNKNOWN" : rs);
                  }

               // close_* fields are populated for SCALE_OUT when a broker deal is matched
               m_logger.LogMMEventBase(evt);

               }
            while(false);

            // =========================
            // ✅ ALWAYS RUN THIS
            // ========================

            // ✅ rebuild AFTER snapshot from LIVE position
            // ===============================
            // MM_SNAPSHOT_AFTER — SCALE_OUT
            // ===============================
            MM_SNAPSHOT_AFTER snap_after;
            ZeroMemory(snap_after);
            snap_after.timestamp = TimeCurrent();
            snap_after.symbol    = ctx.Symbol;
            snap_after.timeframe = inpEntryPeriod;

            // lifecycle
            snap_after.mm_phase = ToMMPhaseString(MM_PHASE_MANAGE);
            snap_after.mm_event_result = ToMMEventString(MM_EVENT_SCALE_OUT);


            // 🔥 IMPORTANT: recalc AFTER from live state
            // exposure AFTER scale-out
            snap_after.current_position_lots = PositionGetDouble(POSITION_VOLUME);
            // risk anchor unchanged (ENTRY-based)
            snap_after.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

            // outcome
            snap_after.take_profit = PositionGetDouble(POSITION_TP);
            snap_after.realized_pnl = PositionGetDouble(POSITION_PROFIT);

            // reuse for reconstruction
            snap_after.stoploss_points  = snap.stoploss_points;
            snap_after.value_per_point  = snap.value_per_point;

            // ✅ ALWAYS EXECUTE
            EmitSnapshotAfter(snap_after);
            EndMMCycleCheck();

            } //if
         }



      // ------------------------------------------------
      // BREAK EVEN Block
      // ------------------------------------------------
      double newSL;
      if(!m_atrTracker.IsBEApplied(ticket))
         {
         // Phase 5 — Step 5: Lifecycle MM_ACTION (Break-Even pass-through)

#ifdef ENABLE_LIFECYCLE_CONTROLLER

         m_lifecycleController.RequestAction(
            0, //ctx.trade_id,
            ACTION_MM,
            reject_reason
         );
#endif

         // ===============================
         // MM_SNAPSHOT_BEFORE — BREAK EVEN
         // ===============================
         MM_SNAPSHOT_BEFORE snap;
         ZeroMemory(snap);
         snap.timestamp = TimeCurrent();
         snap.symbol    = ctx.Symbol;
         snap.timeframe = inpEntryPeriod;

         // identity
         snap.trade_context_id = ticket;

         // lifecycle intent
         snap.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
         snap.mm_event_intent = ToMMEventString(MM_EVENT_BE);

         // --- Market Context (Schema v1.1) ---
         snap.current_price =
            (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            ? bid : ask;

         // ATR value actually used by MM (NOT recomputed)
         snap.atr_value = ctx.ATREntry.Value;

         // account state
         snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
         snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
         snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

         // exposure (unchanged by BE)
         snap.current_position_lots = PositionGetDouble(POSITION_VOLUME);
         snap.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

         // execution‑state observability
         snap.take_profit  = PositionGetDouble(POSITION_TP);
         snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);

         // geometry (ENTRY‑anchored)
         snap.stoploss_points = ctx.ATREntry.Value * inpSLxATRxPlier;

         snap.value_per_point = tick_value / tick_size;

         // ✅ BEGIN INF-3
         BeginMMCycle(MM_EVENT_BE);
         EmitSnapshotBefore(snap);
         m_out_action_executed     = false;
         m_out_execution_reason    = "NOT_TRIGGERED";
         m_out_previous_stoploss   = 0.0;
         m_out_new_stoploss        = 0.0;
         m_out_closed_lots         = 0.0;
         m_out_event_outcome       = "SKIP";


         // =========================
         // SAFE EXECUTION BLOCK
         // =========================
         bool be_applied = false;

         do
            {
            if(!m_be.Evaluate(ctx, inpBE_ATR, inpBE_ExtraPips, newSL))
               {
               m_out_action_executed  = false;
               m_out_execution_reason = "EVALUATE_FALSE";
               m_out_event_outcome    = "SKIP";
               break;

               }
            double oldSL = PositionGetDouble(POSITION_SL);
            if(!m_exec.ModifyStopLoss(symbol, newSL))
               {
               Print("⚠️ Break-Even execution failed");
               m_out_action_executed  = false;
               m_out_execution_reason = "EXECUTION_FAILED";
               m_out_event_outcome    = "FAIL";
               break;

               }

            m_atrTracker.MarkBEApplied(ticket); // 1️⃣ Mark BE applied FIRST (prevents double logging)
            if(inpEnableTradeVisualizer)
               m_viz.DrawBreakEven(symbol, newSL); // 2️⃣ Optional visualization (safe, non‑functional)

            // 3️⃣ BREAK-EVEN LOGGING — Phase 4.4
            MM_LogEventBase evt;
            InitMMEvent(evt, MM_EVENT_BE, MM_PHASE_MANAGE, ctx.Symbol, ticket, ctx.Time);
            evt.action_summary = "Move SL to Break Even";
            m_logger.LogMMEventBase(evt);

            be_applied = true;
            m_out_action_executed     = true;
            m_out_execution_reason    = "";
            m_out_previous_stoploss   = oldSL;
            m_out_new_stoploss        = newSL;
            m_out_event_outcome       = "SUCCESS";
            m_be_triggered = true;

            }
         while(false);

         // ===============================
         // MM_SNAPSHOT_AFTER — BREAK EVEN
         // ===============================
         MM_SNAPSHOT_AFTER snap_after;
         ZeroMemory(snap_after);
         snap_after.timestamp = TimeCurrent();
         snap_after.symbol    = ctx.Symbol;
         snap_after.timeframe = inpEntryPeriod;

         // lifecycle intent
         snap_after.mm_phase = ToMMPhaseString(MM_PHASE_MANAGE);
         snap_after.mm_event_result = ToMMEventString(MM_EVENT_BE);

         // no exposure change
         snap_after.current_position_lots = PositionGetDouble(POSITION_VOLUME);

         // ENTRY risk anchor still valid
         snap_after.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

         // updated execution state
         snap_after.take_profit  = PositionGetDouble(POSITION_TP);
         snap_after.realized_pnl = PositionGetDouble(POSITION_PROFIT);

         // geometry unchanged
         snap_after.stoploss_points = snap.stoploss_points;
         snap_after.value_per_point = snap.value_per_point;
         EmitSnapshotAfter(snap_after);
         EndMMCycleCheck();

         // ✅ preserve your logic: stop after BE
         if(be_applied)
            return;
         }

      // ------------------------------------------------
      // --- TRAILING Block
      // ------------------------------------------------
      // Phase 5 — Step 5: Lifecycle MM_ACTION (Trailing Stop pass-through)

#ifdef ENABLE_LIFECYCLE_CONTROLLER
      m_lifecycleController.RequestAction(
         0, //ctx.trade_id,
         ACTION_MM,
         reject_reason
      );
#endif

      // ==================================
      // MM_SNAPSHOT_BEFORE — TRAILING STOP
      // ==================================
      MM_SNAPSHOT_BEFORE snap;
      ZeroMemory(snap);
      snap.timestamp = TimeCurrent();
      snap.symbol    = ctx.Symbol;
      snap.timeframe = inpEntryPeriod;

      // identity
      snap.trade_context_id = ticket;

      // lifecycle intent
      snap.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
      snap.mm_event_intent = ToMMEventString(MM_EVENT_TRAIL);

      // --- Market Context (Schema v1.1) ---
      snap.current_price =
         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         ? bid : ask;

      // ATR value actually used by MM (NOT recomputed)
      snap.atr_value = ctx.ATREntry.Value;

      // account state
      snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
      snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
      snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      // exposure (unchanged by trailing)
      snap.current_position_lots = PositionGetDouble(POSITION_VOLUME);
      snap.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

      // execution‑state observability
      snap.take_profit  = PositionGetDouble(POSITION_TP);
      snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);

      // geometry (ENTRY‑anchored)
      snap.stoploss_points = ctx.ATREntry.Value * inpSLxATRxPlier;
      snap.value_per_point = tick_value / tick_size;

      // ✅ INF-3 START
      BeginMMCycle(MM_EVENT_TRAIL);
      EmitSnapshotBefore(snap);
      m_out_action_executed     = false;
      m_out_execution_reason    = "NOT_TRIGGERED";
      m_out_previous_stoploss   = 0.0;
      m_out_new_stoploss        = 0.0;
      m_out_closed_lots         = 0.0;
      m_out_event_outcome       = "SKIP";


      // =========================
      // SAFE EXECUTION BLOCK
      // =========================
      bool trail_applied = false;
      double oldSL = PositionGetDouble(POSITION_SL);
      do
         {
         if(!m_trail.Evaluate(ctx, inpTrailStartATR, inpTrailATR, newSL))
            {
            m_out_action_executed  = false;
            m_out_execution_reason = "EVALUATE_FALSE";
            m_out_event_outcome    = "SKIP";
            break;

            }


         if(!m_exec.ModifyStopLoss(symbol, newSL))
            {
            Print("⚠️ TRAILING execution failed");
            m_out_action_executed  = false;
            m_out_execution_reason = "EXECUTION_FAILED";
            m_out_event_outcome    = "FAIL";
            break;
            }
         else
            {
            Print("✅ TRAILING applied. SL moved from ", oldSL, " to ", newSL);
            }

         trail_applied = true;
         m_out_action_executed     = true;
         m_out_execution_reason    = "";
         m_out_previous_stoploss   = oldSL;
         m_out_new_stoploss        = newSL;
         m_out_event_outcome       = "SUCCESS";
         m_trail_count++;

         // ----------------------------------------------------
         // TRAILING STOP LOGGING — Phase 4.4
         // ----------------------------------------------------
         // ✅ event log only if success
         MM_LogEventBase evt;
         InitMMEvent(evt, MM_EVENT_TRAIL, MM_PHASE_MANAGE, ctx.Symbol, ticket, ctx.Time);
         evt.action_summary = "Trail Stop Loss";
         m_logger.LogMMEventBase(evt);

         }
      while(false);

      // ==================================
      // MM_SNAPSHOT_AFTER — TRAILING STOP
      // ==================================
      MM_SNAPSHOT_AFTER snap_after;
      ZeroMemory(snap_after);
      snap_after.timestamp = TimeCurrent();
      snap_after.symbol    = ctx.Symbol;
      snap_after.timeframe = inpEntryPeriod;

      // lifecycle intent
      snap_after.mm_phase        = ToMMPhaseString(MM_PHASE_MANAGE);
      snap_after.mm_event_result = ToMMEventString(MM_EVENT_TRAIL);

      // exposure remains unchanged
      snap_after.current_position_lots =
         PositionGetDouble(POSITION_VOLUME);

      // ENTRY risk anchor unchanged
      snap_after.current_risk_exposure =
         m_risk.GetLastComputedRiskAmount();

      // updated execution state
      snap_after.take_profit  = PositionGetDouble(POSITION_TP);
      snap_after.realized_pnl = PositionGetDouble(POSITION_PROFIT);

      // geometry unchanged
      snap_after.stoploss_points = snap.stoploss_points;
      snap_after.value_per_point = snap.value_per_point;

      // ✅ ALWAYS EXECUTE
      EmitSnapshotAfter(snap_after);
      EndMMCycleCheck();

   }

   // --------------------------------------------------
   // ----- ManageExit
   // --------------------------------------------------
   void ManageExit(const string symbol, const SymbolCache &cache)
   {

      const double bid       = cache.bid;
      const double ask       = cache.ask;
      const double tick_value = cache.tick_value;
      const double tick_size = cache.tick_size;

      if(!PositionSelect(symbol)) return;

      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);
      enum_position dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? Long : Short);
      m_last_position_type = PositionTypeToString(dir);

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

      // ✅ EXIT ATR Anchor Fix (MM-LOG-01): use entry ATR anchor from tracker
      ctx.ATREntry.Value   = m_atrTracker.GetATR(ticket);
      ctx.ATREntry.IsValid = (ctx.ATREntry.Value > 0.0);

      RejectionReason reject_reason = REJECT_NONE;


      // ==========================
      // MM_SNAPSHOT_BEFORE — EXIT
      // ==========================
      MM_SNAPSHOT_BEFORE snap;
      ZeroMemory(snap);
      snap.timestamp = TimeCurrent();
      snap.symbol    = ctx.Symbol;
      snap.timeframe = inpEntryPeriod;

      // identity
      snap.trade_context_id = ticket;

      // lifecycle intent
      snap.mm_phase        = ToMMPhaseString(MM_PHASE_EXIT);
      snap.mm_event_intent = ToMMEventString(MM_EVENT_EXIT);

      // --- Market Context (Schema v1.1) ---
      snap.current_price = snap.current_price = (dir == Long) ? bid : ask;

      // ATR value actually used by MM (NOT recomputed)
      snap.atr_value = ctx.ATREntry.Value;

      // account state
      snap.balance     = AccountInfoDouble(ACCOUNT_BALANCE);
      snap.equity      = AccountInfoDouble(ACCOUNT_EQUITY);
      snap.free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      // exposure before exit
      snap.current_position_lots = PositionGetDouble(POSITION_VOLUME);
      snap.current_risk_exposure = m_risk.GetLastComputedRiskAmount();

      // execution‑state observability
      snap.take_profit  = PositionGetDouble(POSITION_TP);
      snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);

      // geometry (ENTRY‑anchored)
      snap.stoploss_points = ctx.ATREntry.Value * inpSLxATRxPlier;
      snap.value_per_point = tick_value / tick_size;

      // ✅ INF-3 START
      BeginMMCycle(MM_EVENT_EXIT);
      EmitSnapshotBefore(snap);
      m_out_action_executed  = false;
      m_out_execution_reason = "NOT_ATTEMPTED";
      m_out_event_outcome    = "SKIP";

#ifdef ENABLE_LIFECYCLE_CONTROLLER
      // Phase 5 — Step 6: Lifecycle EXIT (pass-through)
      m_lifecycleController.RequestAction(
         0,               // trade_id not enforced yet
         ACTION_EXIT,
         reject_reason
      );
#endif

      // =========================
      // SAFE EXECUTION BLOCK
      // =========================
      bool exit_success = false;

      do
         {
         if(!m_exec.ExecuteExit(ctx))
            {
            Print("⚠️ EXIT execution fail" + " m_cycle_id: " + IntegerToString(m_cycle_id));
            m_out_action_executed  = false;
            m_out_execution_reason = "EXECUTION_FAILED";
            m_out_event_outcome    = "FAIL";
            break;

            }
         exit_success = true;
         m_out_action_executed  = true;
         m_out_execution_reason = "";
         m_out_event_outcome    = "SUCCESS";

         // ✅ EXIT LOGGING — Phase 4.4
         // ✅ log event ONLY on sucess
         MM_LogEventBase evt;
         InitMMEvent(evt, MM_EVENT_EXIT, MM_PHASE_EXIT, ctx.Symbol, ticket, ctx.Time);
         evt.action_summary = "Exit signal: " + EnumToString(inpExitIndicator) + " (" + EnumToString(inpExitMode) + ")";
         m_logger.LogMMEventBase(evt);

         }
      while(false);

      // =========================
      // MM_SNAPSHOT_AFTER — EXIT
      // =========================
      MM_SNAPSHOT_AFTER snap_after;
      ZeroMemory(snap_after);
      snap_after.timestamp = TimeCurrent();
      snap_after.symbol    = ctx.Symbol;
      snap_after.timeframe = inpEntryPeriod;

      // lifecycle intent
      snap_after.mm_phase        = ToMMPhaseString(MM_PHASE_EXIT);
      snap_after.mm_event_result = ToMMEventString(MM_EVENT_EXIT);

      // ✅ LIVE STATE (CRITICAL)
      if(PositionSelect(symbol))
         {
         // position still exists (exit failed)
         snap_after.current_position_lots =
            PositionGetDouble(POSITION_VOLUME);
         }
      else
         {
         // position closed successfully
         snap_after.current_position_lots = 0.0;
         }


// risk anchor remains for audit
      snap_after.current_risk_exposure =
         m_risk.GetLastComputedRiskAmount();

// final outcome
      snap_after.take_profit = snap.take_profit;
      snap_after.realized_pnl = snap.floating_pnl;

// geometry unchanged
      snap_after.stoploss_points = snap.stoploss_points;
      snap_after.value_per_point = snap.value_per_point;

// ✅ ALWAYS EXECUTE
      EmitSnapshotAfter(snap_after);
      EndMMCycleCheck();

      if(exit_success)
         {
         // lifecycle close
         // Phase 5 — Step 6: Lifecycle CLOSE (pass-through)

#ifdef ENABLE_LIFECYCLE_CONTROLLER
         m_lifecycleController.RequestAction(
            0,               // trade_id not enforced yet
            ACTION_CLOSE,
            reject_reason
         );
#endif
         // ✅ Clean up tracker state
         m_atrTracker.RemoveTicket(ticket);
         }
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

// ============================================================
// Symbol Cache
// ============================================================
   bool BuildSymbolCache(const string symbol, SymbolCache &c)
   {
      c.symbol = symbol;
      c.bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      c.ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      c.tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      c.tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

      if(c.bid <= 0.0 || c.ask <= 0.0 || c.tick_size <= 0.0)
         return false;
      return true;
   }


// ============================================================
// v2.0 Snapshot Helpers (Option 2 Risk Consistency)
// ============================================================

// Always return a stable risk model string (v2.0)
   string CurrentRiskModelString() const
   {
      return EnumToString(inpRiskMethod);
   }

// Always return the configured risk value (v2.0)
// - percent model: inpRiskPercent
// - fixed model:   inpRiskFixAmount
   double CurrentRiskValue() const
   {
      // If you have enum values for fixed risk, map it here.
      // If not sure, keep percent as default and override later.
      if(inpRiskMethod == RISK_FIXED)  // adjust if your enum name differs
         return inpRiskFixAmount;
      return inpRiskPercent;
   }

// Defensive: use live ticket/position_id when possible
   bool TryGetLiveIdentity(const string symbol, ulong &ticket, long &position_id) const
   {
      if(!PositionSelect(symbol))
         return false;

      ticket = (ulong)PositionGetInteger(POSITION_TICKET);
      position_id = (long)PositionGetInteger(POSITION_IDENTIFIER);
      return true;
   }


// ============================================================
// initialize common event fields
// ============================================================

   void InitMMEvent(MM_LogEventBase &evt,
                    const ENUM_MM_EVENT_TYPE type,
                    const ENUM_MM_PHASE phase,
                    const string symbol,
                    const ulong ticket,
                    const datetime when)
   {
      ZeroMemory(evt);
      evt.event_time = when;
      evt.event_type = type;
      evt.phase      = phase;
      evt.symbol     = symbol;
      evt.timeframe  = inpEntryPeriod;

      evt.cycle_id   = m_cycle_id;
      evt.trade_id   = (long)ticket;
      evt.correlation_id = m_current_correlation_id;
      evt.ticket     = ticket;

      // Default from live position if available, otherwise fallback
      enum_position liveDir = GetLivePositionDirection(symbol);
      string pt = PositionTypeToString(liveDir);
      evt.position_type = (pt != "NA" ? pt : m_last_position_type);


      // Defaults (safe; overridden by CLOSE/SCALE_OUT when matched)
      evt.close_reason = "";
      evt.close_price  = 0.0;
      evt.close_profit = 0.0;
      evt.close_volume = 0.0;
      evt.deal_id      = 0;

      evt.scale_steps = 0;
      evt.scale_fraction_total = 0.0;
      evt.action_summary = "";
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

      return ctx.IsTradeable;

   }

};

#endif // __LIBCTRADEENGINE_MQH__
//+------------------------------------------------------------------+
