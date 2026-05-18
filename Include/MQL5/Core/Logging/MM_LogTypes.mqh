//+------------------------------------------------------------------+
//| MM_LogTypes.mqh                                                  |
//| 05/05/2026                                                       |
//| Marteo Cosme                                                     |
//+------------------------------------------------------------------+

struct MM_LogCycleSummary
{
  // --- Identity ---
  int   cycle_id;
  long  internal_trade_id;   // v2.1: equals cycle_id for now
  long  trade_id;            // legacy-compatible; currently same as ticket
  ulong ticket;
  long  position_id;
  string position_type;      // "LONG" | "SHORT" | "NA"

  // --- Symbol / Lifecycle Timing ---
  string symbol;
  datetime entry_time;
  datetime exit_time;
  int duration_sec;

  // --- Price / PnL ---
  double entry_price;
  double exit_price;
  double pnl;

  // --- Lifecycle Aggregates ---
  int  scale_count;
  int  trail_count;
  bool be_triggered;
  double total_traded_volume;

  // --- Broker Close Evidence ---
  string close_reason;
  double close_volume;
  ulong deal_id;

  // --- Lifecycle Status ---
  string lifecycle_status;   // "CLOSED" for completed lifecycle rows

};
