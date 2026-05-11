//+------------------------------------------------------------------+
//| MM_LogSchema.mqh                                           |
//| Single Source Schema Definition (MM-LOG-01 Enforcement)         |
//| Aligned with: MM_Snapshot_Schema_v1.1.md                        |
//| Marteo Cosme                                                    |
//+------------------------------------------------------------------+
#property strict
#ifndef __MM_LOG_SCHEMA_MQH__
#define __MM_LOG_SCHEMA_MQH__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MM_LogSchema
{
public:

   // ============================================================
   // ✅ SCHEMA VERSION (for future validation / parsing)
   // ============================================================
   static string Version()
   {
      return "v2.0";
   }

   // ============================================================
   // ✅ HEADER WRITER (Single Source of Truth)
   // ============================================================
   static void SnapShotHeader(const int h)
   {
      FileWrite(
         h,
         // --- Meta ---
         "debug_event_id",
         "correlation_id",

         // --- Identity (v2.0) ---
         "cycle_id",
         "internal_trade_id",
         "ticket",
         "position_id",

         // --- Timing / Classification ---
         "timestamp",
         "symbol",
         "timeframe",
         "record_type",
         "mm_phase",
         "mm_event",

         // --- Account (Full-State) ---
         "balance",
         "equity",
         "free_margin",

         // --- Exposure (Full-State) ---
         "current_position_lots",
         "current_risk_exposure",

         // --- Market Context (Full-State) ---
         "current_price",
         "atr_value",

         // --- Execution State (Full-State) ---
         "take_profit",
         "floating_pnl",
         "realized_pnl",

         // --- Risk Geometry ---
         "stoploss_points",
         "value_per_point",

         // --- MM Inputs actually used ---
         "risk_model",
         "risk_value",
         "risk_amount_used",

         // --- Scale Context ---
         "scale_atr_multiple",
         "scale_fraction",

         // --- Execution Outcome ---
         "action_executed",
         "execution_reason",
         "previous_stoploss",
         "new_stoploss",
         "closed_lots",
         "event_outcome"
      );

   }

   // ============================================================
   // ✅ OPTIONAL: COLUMN COUNT (for validation later)
   // ============================================================
   static int SnapShotColumnCount()
   {
      return 35;
      
   }


   // ============================================================
   // ✅ Summary HEADER
   // ============================================================
   static void SummaryHeader(const int h)
   {
      FileWrite(
         h,
         "cycle_id",
         "trade_id",
         "symbol",
         "entry_time",
         "exit_time",
         "entry_price",
         "exit_price",
         "pnl",
         "scale_count",
         "trail_count",
         "be_triggered"
      );
   }

   // ============================================================
   // ✅ OPTIONAL: COLUMN COUNT (for validation later)
   // ============================================================
   static int SummaryColumnCount()
   {
      // Must match SummaryHeader() exactly
      // cycle_id, trade_id, symbol, entry_time, exit_time, entry_price, exit_price,
      // pnl, scale_count, trail_count, be_triggered
      return 11;

   }

   // ============================================================
   // ✅ Event HEADER
   // ============================================================
   static void EventHeader(const int h)
   {
      FileWrite(
         h,
         "debug_event_id",
         "correlation_id",
         "event_time",
         "symbol",
         "timeframe",
         "phase",
         "event_type",
         "cycle_id",
         "trade_id",
         "ticket",
         "action_summary",
         "scale_steps",
         "scale_fraction_total",
         "close_reason",
         "close_price",
         "close_profit",
         "close_volume",
         "deal_id"

      );
   }

   // ============================================================
   // ✅ OPTIONAL: COLUMN COUNT (for validation later)
   // ============================================================
   static int EventColumnCount()
   {
      // Must match EventHeader() exactly
      // debug_event_id, correlation_id, event_time, symbol, timeframe, phase, event_type,
      // cycle_id, trade_id, ticket, action_summary, scale_steps, scale_fraction_total,
      // close_reason, close_price, close_profit, close_volume, deal_id
      return 18;

   }

};

#endif __MM_LOG_SCHEMA_MQH__
//+------------------------------------------------------------------+
