//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//  MM_LogSnapshotBefore  (v2.0)
//  FULL-STATE snapshot BEFORE
//+------------------------------------------------------------------+

struct MM_LogSnapshotBefore
{
   // --- Meta ---
   ulong correlation_id;

   // --- Identity (v2.0) ---
   int   cycle_id;
   long  internal_trade_id;
   ulong ticket;
   long  position_id;
   string position_type; // "LONG" | "SHORT" | "NA"

   // --- Identity & Timing ---
   datetime timestamp;
   string   symbol;
   ENUM_TIMEFRAMES timeframe;

   // --- Classification ---
   string mm_phase;
   string mm_event;          // intent for BEFORE
   // record_type is written by logger as "MM_SNAPSHOT_BEFORE"

   // --- Account (Full-State) ---
   double balance;
   double equity;
   double free_margin;

   // --- Exposure (Full-State) ---
   double current_position_lots;
   double current_risk_exposure;

   // --- Market Context (Full-State) ---
   double current_price;
   double atr_value;

   // --- Execution State ---
   double take_profit;
   double floating_pnl;
   double realized_pnl;      // usually 0 in BEFORE

   // --- Risk Geometry ---
   double stoploss_points;
   double value_per_point;

   // --- MM Inputs actually used ---
   string risk_model;
   double risk_value;
   double risk_amount_used;

   // --- Scale Context (N/A=0) ---
   double scale_atr_multiple;
   double scale_fraction;

   // --- Execution Outcome (neutral defaults in BEFORE) ---
   bool   action_executed;
   string execution_reason;
   double previous_stoploss;
   double new_stoploss;
   double closed_lots;
   string event_outcome;     // "", or "SUCCESS \ FAIL \ SKIP" (prefer "" in BEFORE)

};


//+------------------------------------------------------------------+
//  MM_LogSnapshotAfter  (v2.0)
//  FULL-STATE snapshot AFTER
//+------------------------------------------------------------------+


struct MM_LogSnapshotAfter
{
   // --- Meta ---
   ulong correlation_id;

   // --- Identity (v2.0) ---
   int   cycle_id;
   long  internal_trade_id;
   ulong ticket;
   long  position_id;
   string position_type; // "LONG" | "SHORT" | "NA"

   // --- Identity & Timing ---
   datetime timestamp;
   string   symbol;
   ENUM_TIMEFRAMES timeframe;

   // --- Classification ---
   string mm_phase;
   string mm_event;          // result for AFTER
   // record_type is written by logger as "MM_SNAPSHOT_AFTER"

   // --- Account (Full-State) ---
   double balance;
   double equity;
   double free_margin;

   // --- Exposure (Full-State) ---
   double current_position_lots;
   double current_risk_exposure;

   // --- Market Context (Full-State) ---
   double current_price;
   double atr_value;

   // --- Execution State ---
   double take_profit;
   double floating_pnl;
   double realized_pnl;

   // --- Risk Geometry ---
   double stoploss_points;
   double value_per_point;

   // --- MM Inputs actually used ---
   string risk_model;
   double risk_value;
   double risk_amount_used;

   // --- Scale Context (N/A=0) ---
   double scale_atr_multiple;
   double scale_fraction;

   // --- Execution Outcome (always populated) ---
   bool   action_executed;
   string execution_reason;
   double previous_stoploss;
   double new_stoploss;
   double closed_lots;
   string event_outcome;     // "SUCCESS" | "FAIL" | "SKIP"
};
//+------------------------------------------------------------------+
