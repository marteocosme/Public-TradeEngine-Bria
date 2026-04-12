//+------------------------------------------------------------------+
//| libCUnifiedTradeLogger.mqh                                       |
//| Unified Trading Event Log System (Production‑grade)              |
//| Marteo Cosme                                                     |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBC_UNIFIED_TRADE_LOGGER_MQH__
#define __LIBC_UNIFIED_TRADE_LOGGER_MQH__

#include <MyInclude\\NNFX\\libEnum.mqh>

/* Moved to libEnum.mqh                                                           
// ==================================================================
// Unified Event Definition
// ==================================================================
enum enum_tradeEvent
{
   EVT_SIGNAL,   // ✅ New
   EVT_ENTRY,
   EVT_RISK,
   EVT_BE,
   EVT_TRAIL,
   EVT_SCALE,
   EVT_EXIT,
   EVT_SUMMARY
};

*/

// ==================================================================
// Money Management Base Log Event (Phase 4.2)
// ==================================================================

struct MM_LogEventBase
{
   datetime           event_time;   // Strategy bar/tick time
   ENUM_MM_EVENT_TYPE event_type;   // MM lifecycle event
   ENUM_MM_PHASE      phase;        // Trade lifecycle phase
   string             symbol;       // Symbol (e.g. EURUSD)
   ENUM_TIMEFRAMES    timeframe;    // Strategy timeframe
   long               trade_id;     // Internal deterministic ID
   ulong              ticket;       // Broker ticket (0 if not available)
};


// ==================================================================
// Unified Logger
// ==================================================================
class CUnifiedTradeLogger
{
private:
   string m_csv;
   string m_json;

   static ulong s_globalEventId;

   ulong NextEventId()
   {
      return ++s_globalEventId;
   }

   string EventToString(const enum_tradeEvent e) const
   {
      switch(e)
         {
         case EVT_SIGNAL:
            return "SIGNAL";        
         case EVT_ENTRY:
            return "ENTRY";
         case EVT_RISK:
            return "RISK";
         case EVT_BE:
            return "BE";
         case EVT_TRAIL:
            return "TRAIL";
         case EVT_SCALE:
            return "SCALE";
         case EVT_EXIT:
            return "EXIT";
         case EVT_SUMMARY:
            return "SUMMARY";
         default:
            return "UNKNOWN";
         }
   }

   bool FileIsEmpty(int handle)
   {
      return (FileTell(handle) == 0);
   }


public:
   CUnifiedTradeLogger(const string baseName = "NNFX_TradeEvents")
   {
      m_csv  = baseName + ".csv";
      m_json = baseName + ".json";
   }

   // ================================================================
   // CORE EVENT WRITER (CSV)
   // ================================================================
   void LogCSV(
      const ulong ticket,
      const uint  eventSeq,
      const string symbol,
      const enum_tradeEvent evt,
      const enum_position dir,
      const double lots,
      const double entryPrice,
      const double sl,
      const double tp,
      const double atr,
      const double riskPct,
      const string reason,
      const double pnl = 0.0
   )
   {
      int h = FileOpen(m_csv,
                       FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
      if(h == INVALID_HANDLE) return;

      FileSeek(h, 0, SEEK_END);
      FileWrite(h,
                NextEventId(),
                eventSeq,
                ticket,
                TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                symbol,
                EventToString(evt),
                EnumToString(dir),
                lots,
                entryPrice,
                sl,
                tp,
                atr,
                riskPct,
                reason,
                pnl
               );
      FileClose(h);
   }

   // ================================================================
   // CORE EVENT WRITER (JSON)
   // ================================================================
   void LogJSON(
      const ulong ticket,
      const uint  eventSeq,
      const string symbol,
      const enum_tradeEvent evt,
      const enum_position dir,
      const double lots,
      const double entryPrice,
      const double sl,
      const double tp,
      const double atr,
      const double riskPct,
      const string reason,
      const double pnl = 0.0
   )
   {
      int h = FileOpen(m_json,
                       FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON);
      if(h == INVALID_HANDLE) return;

      FileSeek(h, 0, SEEK_END);

      string json =
         "{"
         "\"event_id\":" + (string)NextEventId() + ","
         "\"event_seq\":" + (string)eventSeq + ","
         "\"ticket\":" + (string)ticket + ","
         "\"time\":\"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\","
         "\"symbol\":\"" + symbol + "\","
         "\"event\":\"" + EventToString(evt) + "\","
         "\"direction\":\"" + EnumToString(dir) + "\","
         "\"lots\":" + DoubleToString(lots, 2) + ","
         "\"entry\":" + DoubleToString(entryPrice, 6) + ","
         "\"sl\":" + DoubleToString(sl, 6) + ","
         "\"tp\":" + DoubleToString(tp, 6) + ","
         "\"atr\":" + DoubleToString(atr, 6) + ","
         "\"risk_pct\":" + DoubleToString(riskPct, 4) + ","
         "\"reason\":\"" + reason + "\","
         "\"pnl\":" + DoubleToString(pnl, 2) +
         "}\n";

      FileWriteString(h, json);
      FileClose(h);
   }


// ================================================================
// Money Management Logging Entry Point (Phase 4.2)
// ================================================================
void LogMMEventBase(const MM_LogEventBase &evt)
{
  // Phase 4.2: intentionally empty
  // Phase 4.3+: route to CSV / JSON writers
}


   void LogSignalCSV(const SignalSnapshot &s)
   {
      int h = FileOpen(m_csv,
                       FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);

      if(h == INVALID_HANDLE) return;
      /* Temporary remove headers.
            if(FileIsEmpty(h))
               {
               FileWrite(h,
                         "event_id",
                         "eventSeq",
                         "ticket",
                         "time",
                         "symbol",
                         "event",
                         "baseline_trend",
                         "confirmation_signal",
                         "confirmation_score",
                         "volume_state",
                         "entry_allowed"
                        );
               }
      */
      FileSeek(h, 0, SEEK_END);

      FileWrite(h,
                NextEventId(),          // global event id
                0,                      // eventSeq (non-ticket)
                0,                      // ticket (none)
                TimeToString(s.time, TIME_DATE | TIME_SECONDS),
                s.symbol,
                "SIGNAL",
                EnumToString(s.baseTrend),
                EnumToString(s.confSignal),
                s.confScore,
                EnumToString(s.volState),
                s.entryAllowed
               );

      FileClose(h);
   }

   void LogSignalJSON(const SignalSnapshot &s)
   {
      int h = FileOpen(m_json,
                       FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON);

      if(h == INVALID_HANDLE) return;
      FileSeek(h, 0, SEEK_END);

      string json =
         "{"
         "\"event_id\":" + (string)NextEventId() + ","
         "\"event\":\"SIGNAL\","
         "\"time\":\"" + TimeToString(s.time, TIME_DATE | TIME_SECONDS) + "\","
         "\"symbol\":\"" + s.symbol + "\","
         "\"baseline_trend\":\"" + EnumToString(s.baseTrend) + "\","
         "\"confirmation_signal\":\"" + EnumToString(s.confSignal) + "\","
         "\"confirmation_trend\":\"" + EnumToString(s.confTrend) + "\","
         "\"confirmation_score\":" + IntegerToString(s.confScore) + ","
         "\"volume_state\":\"" + EnumToString(s.volState) + "\","
         "\"entry_allowed\":" + (s.entryAllowed ? "true" : "false") +
         "}\n";

      FileWriteString(h, json);
      FileClose(h);
   }
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


#endif // __LIBC_UNIFIED_TRADE_LOGGER_MQH__
