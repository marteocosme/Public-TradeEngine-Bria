//+------------------------------------------------------------------+
//| MM_LogTypes.mqh                                                  |
//| 05/05/2026                                                       |
//| Marteo Cosme                                                     |
//+------------------------------------------------------------------+

struct MM_LogCycleSummary
{
   int      cycle_id;
   long     trade_id;
   string   symbol;

   datetime entry_time;
   datetime exit_time;

   double   entry_price;
   double   exit_price;

   double   pnl;

   int      scale_count;
   int      trail_count;

   bool     be_triggered;
};
