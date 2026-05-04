//+------------------------------------------------------------------+
//| MM_LogSchema_v1_1.mqh                                           |
//| Single Source Schema Definition (MM-LOG-01 Enforcement)         |
//| Aligned with: MM_Snapshot_Schema_v1.1.md                        |
//| Marteo Cosme                                                    |
//+------------------------------------------------------------------+
#property strict
#ifndef __MM_LOG_SCHEMA_V1_1_MQH__
#define __MM_LOG_SCHEMA_V1_1_MQH__

class MM_LogSchemaV11
{
public:

   // ============================================================
   // ✅ SCHEMA VERSION (for future validation / parsing)
   // ============================================================
   static string Version()
   {
      return "v1.1";
   }

   // ============================================================
   // ✅ HEADER WRITER (Single Source of Truth)
   // ============================================================
   static void WriteHeader(const int h)
   {
      FileWrite(
         h,

         // --- Meta ---
         "debug_event_id",
         "trade_id",
         "ticket",
         "timestamp",
         "symbol",
         "record_type",
         "mm_phase",
         "mm_event",

         // --- Account ---
         "balance",
         "equity",
         "free_margin",

         // --- Exposure ---
         "current_position_lots",
         "current_risk_exposure",

         // --- Market Context ---
         "current_price",
         "atr_value",

         // --- Execution ---
         "take_profit",
         "pnl",

         // --- Risk Geometry ---
         "stoploss_points",
         "value_per_point",

         // --- Scale Context ---
         "scale_atr_multiple",
         "scale_fraction"
      );
   }

   // ============================================================
   // ✅ OPTIONAL: COLUMN COUNT (for validation later)
   // ============================================================
   static int ColumnCount()
   {
      return 21;
   }
};

#endif // __MM_LOG_SCHEMA_V1_1_MQH__
//+------------------------------------------------------------------+
