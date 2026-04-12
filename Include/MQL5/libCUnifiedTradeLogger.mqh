//+------------------------------------------------------------------+
//| libCUnifiedTradeLogger.mqh                                       |
//| Unified Trade Logger — Phase 4.3.x Aligned                       |
//| Marteo Cosme                                                     |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBC_UNIFIED_TRADE_LOGGER_MQH__
#define __LIBC_UNIFIED_TRADE_LOGGER_MQH__

#include <MyInclude\\NNFX\\libEnum.mqh>

// ==================================================================
// Canonical Money Management Logging Payload (Phase 3 / 4.2)
// ==================================================================
struct MM_LogEventBase
{
   datetime            event_time;   // Supplied by producer (bar/tick time)
   ENUM_MM_EVENT_TYPE  event_type;   // Phase-3 contract enum
   ENUM_MM_PHASE       phase;        // Trade Lifecycle phase
   string              symbol;       // Symbol (e.g. EURUSD)
   ENUM_TIMEFRAMES     timeframe;    // Strategy timeframe
   long                trade_id;     // Deterministic internal ID
   ulong               ticket;       // Broker ticket (0 if N/A)
};



// ==================================================================
// Unified Trade Logger (Passive)
// ==================================================================
class CUnifiedTradeLogger
{
private:
   string m_csv;
   string m_json;

   // Debug-only, non-contractual metadata
   static ulong s_globalEventId;


   ulong NextDebugEventId()
   {
      return ++s_globalEventId;
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
   // Money Management Logging Entry Point (Phase 4.2)
   // ================================================================
   void LogMMEventBase(const MM_LogEventBase &evt)
   {
      LogMMEventCSV(evt);
      LogMMEventJSON(evt);
   }

private:

   // ================================================================
   // Internal CSV Writer (MM only)
   // ================================================================
   void LogMMEventCSV(const MM_LogEventBase &evt)
   {
      int h = FileOpen(
         m_csv,
         FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON
      );
      if(h == INVALID_HANDLE)
         return;

      FileSeek(h, 0, SEEK_END);

      FileWrite(
         h,
         NextDebugEventId(),              // DEBUG ONLY
         evt.trade_id,
         evt.ticket,
         TimeToString(evt.event_time, TIME_DATE | TIME_SECONDS),
         evt.symbol,
         EnumToString(evt.event_type),
         EnumToString(evt.phase),
         EnumToString(evt.timeframe)
      );

      FileClose(h);
   }
   
   // ================================================================
   // Internal JSON Writer (MM only)
   // ================================================================
   void LogMMEventJSON(const MM_LogEventBase &evt)
   {
      int h = FileOpen(
         m_json,
         FILE_READ | FILE_WRITE | FILE_TXT | FILE_COMMON
      );
      if(h == INVALID_HANDLE)
         return;

      FileSeek(h, 0, SEEK_END);

      string json =
         "{"
         "\"debug_event_id\":" + (string)NextDebugEventId() + ","
         "\"trade_id\":" + (string)evt.trade_id + ","
         "\"ticket\":" + (string)evt.ticket + ","
         "\"time\":\"" + TimeToString(evt.event_time, TIME_DATE | TIME_SECONDS) + "\","
         "\"symbol\":\"" + evt.symbol + "\","
         "\"event_type\":\"" + EnumToString(evt.event_type) + "\","
         "\"phase\":\"" + EnumToString(evt.phase) + "\","
         "\"timeframe\":\"" + EnumToString(evt.timeframe) + "\""
         "}\n";

      FileWriteString(h, json);
      FileClose(h);
   }
   
public:
   // ================================================================
   // Signal Logging (Pre-trade, Approved Exception)
   // ================================================================
   void LogSignal(const SignalSnapshot &s)
   {
      int h = FileOpen(
         m_csv,
         FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON
      );
      if(h == INVALID_HANDLE)
         return;

      FileSeek(h, 0, SEEK_END);

      FileWrite(
         h,
         NextDebugEventId(),    // DEBUG ONLY
         0,                     // trade_id (N/A)
         0,                     // ticket (N/A)
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
};

// ==================================================================
// Static Definition (EA / Translation Unit)
// ==================================================================
// ulong CUnifiedTradeLogger::s_globalEventId = 0;

#endif // __LIBC_UNIFIED_TRADE_LOGGER_H__

