//+------------------------------------------------------------------+
//| MM_SNAPSHOT_BEFORE                                               |
//| Captures state immediately BEFORE MM decision                    |
//+------------------------------------------------------------------+
struct MM_SNAPSHOT_BEFORE
{
   // --- Identity & Timing ---
   datetime timestamp;
   string   symbol;
   ENUM_TIMEFRAMES timeframe;
   ulong     trade_context_id;

   // --- Lifecycle Context ---
   string   mm_phase;           // e.g. MM_PHASE_ENTRY
   string   mm_event_intent;    // e.g. MM_EVENT_ENTRY

   // --- Account State ---
   double   balance;
   double   equity;
   double   free_margin;

   // --- Exposure State ---
   int      open_positions_count;
   double   current_position_lots;   // 0.0 during ENTRY
   double   current_risk_exposure;    // aggregate risk (% or amount)

   // --- Market Context (Schema v1.1) ---
   double current_price;   // Bid/Ask at MM decision time
   double atr_value;       // ATR value actually use

   // --- Risk Context ---
   string   risk_model;         // FIXED_PERCENT, FIXED_AMOUNT, etc.
   double   risk_value;         // e.g. 1.0 (%), or fixed amount

   // --- Price Context ---
   double   planned_entry_price;
   double   stoploss_price;
   double   stoploss_points;
   double   take_profit;
   double   floating_pnl;


   // --- Risk Calculation Inputs ---
   double value_per_point;
   double risk_amount_used;

   // SCALE_OUT context (MM-LOG-01)
   double scale_atr_multiple;   // e.g. 1.0, 2.0
   double scale_fraction;       // e.g. 0.50

};

//+------------------------------------------------------------------+
//| MM_SNAPSHOT_AFTER                                                |
//| Captures state immediately AFTER MM decision                     |
//+------------------------------------------------------------------+
struct MM_SNAPSHOT_AFTER
{
   // --- Identity ---
   datetime timestamp;
   string   symbol;
   ENUM_TIMEFRAMES timeframe;
   ulong     trade_context_id;

   // --- Lifecycle Result ---
   string   mm_phase;           // phase after MM completes
   string   mm_event_result;    // ENTRY_PLACED, SCALE_OUT_DONE, etc.

   // --- MM Output ---
   double   calculated_risk_amount;
   double   calculated_lot_size;

   // --- Constraints Applied ---
   bool     min_lot_applied;
   bool     max_lot_applied;
   bool     rounding_applied;

   // --- Exposure After ---
   double   resulting_position_lots;
   double   resulting_risk_exposure;

   // --- Order State ---
   ulong    order_ticket;       // 0 if not applicable

   // --- Risk Calculation Inputs ---
   double   stoploss_points;
   double   value_per_point;
   double   risk_amount_used;

   double   take_profit;
   double   realized_pnl;

};
//+------------------------------------------------------------------+
