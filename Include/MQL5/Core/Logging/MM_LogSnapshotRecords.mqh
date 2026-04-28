
//+------------------------------------------------------------------+
//| MM_LogSnapshotBefore                                             |
//| Logger-facing DTO for MM_SNAPSHOT_BEFORE (Schema v1.1)           |
//+------------------------------------------------------------------+
struct MM_LogSnapshotBefore
{
   // --- Identity & Timing ---
   datetime         timestamp;
   string           symbol;
   ENUM_TIMEFRAMES  timeframe;
   ulong             trade_context_id;

   // --- Lifecycle Intent ---
   string           mm_phase;         // ENTRY / MANAGE / EXIT
   string           mm_event_intent;  // ENTRY / SCALE_OUT / BE / TRAIL / EXIT

   // --- Account State ---
   double           balance;
   double           equity;
   double           free_margin;      // ACCOUNT_MARGIN_FREE

   // --- Exposure State ---
   double           current_position_lots;
   double           current_risk_exposure; // ENTRY-anchored risk

   // --- Market Context (v1.1) ---
   double           current_price;    // Bid / Ask as appropriate
   double           atr_value;        // ATR value actually used by MM

   // --- Execution-State Observability ---
   double           take_profit;
   double           floating_pnl;

   // --- Risk Geometry ---
   double           stoploss_points;
   double           value_per_point;

   // --- SCALE_OUT Trigger Context (conditional) ---
   double           scale_atr_multiple; // 0 if not SCALE_OUT
   double           scale_fraction;     // 0 if not SCALE_OUT
};

//+------------------------------------------------------------------+
//| MM_LogSnapshotAfter                                              |
//| Logger-facing DTO for MM_SNAPSHOT_AFTER (Schema v1.1)            |
//+------------------------------------------------------------------+
struct MM_LogSnapshotAfter
{
   // --- Identity & Timing ---
   datetime         timestamp;
   string           symbol;
   ENUM_TIMEFRAMES  timeframe;
   ulong             trade_context_id;

   // --- Exposure Result ---
   double           calculated_lot_size;
   double           calculated_risk_amount; // ENTRY-anchored risk

   // --- Execution Outcome ---
   double           take_profit;
   double           realized_pnl;

   // --- Risk Geometry (unchanged) ---
   double           stoploss_points;
   double           value_per_point;
};
