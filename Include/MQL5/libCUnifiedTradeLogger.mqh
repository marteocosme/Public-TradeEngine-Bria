//+------------------------------------------------------------------+
//| libCUnifiedTradeLogger.mqh                                       |
//| Unified Trade Logger — Phase 4.3.x Aligned                       |
//| Marteo Cosme                                                     |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBC_UNIFIED_TRADE_LOGGER_MQH__
#define __LIBC_UNIFIED_TRADE_LOGGER_MQH__
#define MM_EXPECTED_SNAPSHOT_COLUMNS MM_LogSchemaV11::SnapShotColumnCount()

#include <MyInclude\\NNFX\\libEnum.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\MM_LogSnapshotRecords.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\libCLogHeaderDispatcher.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\MM_LogSchema_v1_1.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\MM_LogTypes.mqh>


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

   // ✅ NEW FIELD (safe extension)
   int                 cycle_id;   // Lifecycle grouping ID
   int                 scale_steps;
   double              scale_fraction_total;
   string              action_summary;
};



// ==================================================================
// Unified Trade Logger (Passive)
// ==================================================================
class CUnifiedTradeLogger
{
private:
   CLogHeaderDispatcher m_header;
   string m_csv_snapshots;
   string m_csv_events;
   string m_csv_summary;
   string m_csv_signals;

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
      m_csv_snapshots = baseName + "_MM_Snapshots.csv";
      m_csv_events = baseName + "_MM_Events.csv";
      m_csv_signals = baseName + "_Signals.csv";
      m_csv_summary = baseName + "_MM_Cycle_Summary.csv";

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
                 m_csv_events,
                 FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON
              );
      if(h == INVALID_HANDLE)
         return;

      FileSeek(h, 0, SEEK_END);
      
      // ✅ Centralized header control
      if(m_header.NeedsHeader(m_csv_events))
         {
         MM_LogSchemaV11::EventHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_events);
         }


      int actual_columns = 21; // must match your FileWrite fields
      

      FileWrite(
         h,
         NextDebugEventId(),              // DEBUG ONLY
         evt.trade_id,
         evt.ticket,
         TimeToString(evt.event_time, TIME_DATE | TIME_SECONDS),
         evt.symbol,
         evt.cycle_id,
         evt.action_summary,
         evt.scale_steps,
         evt.scale_fraction_total,
         EnumToString(evt.event_type),
         EnumToString(evt.phase),
         EnumToString(evt.timeframe)




      );

      FileClose(h);
   }

   // ================================================================
   // Internal JSON Writer (MM only)
   // ================================================================
   void              LogMMEventJSON(const MM_LogEventBase &evt)
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
                 m_csv_signals,
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

   // --------------------------------------------------
   // MM Snapshot Logging (MM-LOG-01 / Schema v1.1)
   // --------------------------------------------------
   void LogMMSnapshotBefore(const MM_LogSnapshotBefore &rec)
   {
      int h = FileOpen(
                 m_csv_snapshots,
                 FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON
              );
      if(h == INVALID_HANDLE)
         return;

      // ✅ NOW move to end
      FileSeek(h, 0, SEEK_END);

      // ✅ Centralized header control
      if(m_header.NeedsHeader(m_csv_snapshots))
         {
         MM_LogSchemaV11::SnapShotHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_snapshots);
         }


      int actual_columns = 21; // must match your FileWrite fields

      if(actual_columns != MM_EXPECTED_SNAPSHOT_COLUMNS)
         {
         Print("❌ SCHEMA ERROR: Column mismatch. Expected=",
               MM_EXPECTED_SNAPSHOT_COLUMNS,
               " Got=", actual_columns);
         }

      FileWrite(
         h,
         NextDebugEventId(),            // debug_event_id
         rec.trade_context_id,          // trade_id
         0,                             // ticket (snapshot-level)
         TimeToString(rec.timestamp, TIME_DATE | TIME_SECONDS),
         rec.symbol,
         "MM_SNAPSHOT_BEFORE",          // ✅ STRING TAG (not enum)
         rec.mm_phase,
         rec.mm_event_intent,

         // --- Account ---
         rec.balance,
         rec.equity,
         rec.free_margin,

         // --- Exposure ---
         rec.current_position_lots,
         rec.current_risk_exposure,

         // --- Market Context ---
         rec.current_price,
         rec.atr_value,

         // --- Execution State ---
         rec.take_profit,
         rec.floating_pnl,

         // --- Risk Geometry ---
         rec.stoploss_points,
         rec.value_per_point,

         // --- SCALE_OUT context ---
         rec.scale_atr_multiple,
         rec.scale_fraction
      );
      FileClose(h);

   }

   void LogMMSnapshotAfter (const MM_LogSnapshotAfter  &rec)
   {
      int h = FileOpen(
                 m_csv_snapshots,
                 FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON
              );

      if(h == INVALID_HANDLE)
         return;

      FileSeek(h, 0, SEEK_END);

      // ✅ Centralized header control
      if(m_header.NeedsHeader(m_csv_snapshots))
         {
         MM_LogSchemaV11::SnapShotHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_snapshots);

         }


      int actual_columns = 21; // must match your FileWrite fields

      if(actual_columns != MM_EXPECTED_SNAPSHOT_COLUMNS)
         {
         Print("❌ SCHEMA ERROR: Column mismatch. Expected=",
               MM_EXPECTED_SNAPSHOT_COLUMNS,
               " Got=", actual_columns);
         }

      if(rec.mm_phase == "" || rec.mm_event_result == "")
         {
         Print("❌ INVALID SNAPSHOT AFTER: missing mm_phase/mm_event");
         }


      if(rec.symbol == "")
         {
         Print("❌ INVALID SNAPSHOT: symbol missing");
         }

      if(rec.current_position_lots < 0)
         {
         Print("❌ INVALID: negative lot size");
         }


      FileWrite( // intentionally blank fields (not required in AFTER snapshot)
         h,

         // --- Meta ---
         NextDebugEventId(),                                      // "debug_event_id", 1
         rec.trade_context_id,                                    // "trade_id", 2
         0,                                                       // ticket, 3
         TimeToString(rec.timestamp, TIME_DATE | TIME_SECONDS),   //"timestamp", 4
         rec.symbol,                                              // "symbol", 5
         "MM_SNAPSHOT_AFTER",                                     // "record_type", 6
         rec.mm_phase,                                            // "mm_phase", 7
         rec.mm_event_result,                                     // "mm_event", 8

         // --- Account ---
         "", // balance, 9 -- not require
         "", // equity, 10 -- not require
         "", // free_margin, 11 -- not require

         // --- Exposure ---
         rec.current_position_lots,                               // "current_position_lots", 12
         rec.current_risk_exposure,                               // "current_risk_exposure", 13

         // --- Market Context ---
         "", // current_price -- not require                      // "current_price", 14
         "", // atr_value -- not require                          // "atr_value", 15

         // --- Execution ---
         rec.take_profit,                                         // "take_profit", 16
         rec.realized_pnl,                                        // "pnl", 17

         // --- Risk Geometry ---
         rec.stoploss_points,                                     // "stoploss_points", 18
         rec.value_per_point,                                     // "value_per_point", 19

         // --- Scale Context ---
         "", // "scale_atr_multiple", 20
         "" // "scale_fraction", 21
      );

      FileClose(h);
   }

   bool NeedsHeader(string file_name)
   {
      int h = FileOpen(file_name, FILE_READ | FILE_CSV | FILE_COMMON);

      if(h == INVALID_HANDLE)
         return true;

      string first_col = FileReadString(h);
      FileClose(h);

      return (first_col != "debug_event_id");
   }
   void LogCycleSummary(const MM_LogCycleSummary &summary)
   {
      LogCycleSummaryCSV(summary);
   }

   void LogCycleSummaryCSV(const MM_LogCycleSummary &s)
   {
      int h = FileOpen(
                 m_csv_summary,
                 FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON
              );
      if(h == INVALID_HANDLE)
         return;

      FileSeek(h, 0, SEEK_END);

      // ✅ Centralized header control
      if(m_header.NeedsHeader(m_csv_summary))
         {
         MM_LogSchemaV11::SummaryHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_snapshots);

         }
      FileWrite(h,
                s.cycle_id,
                s.trade_id,
                s.symbol,
                s.entry_time,
                s.exit_time,
                s.entry_price,
                s.exit_price,
                s.pnl,
                s.scale_count,
                s.trail_count,
                s.be_triggered
               );
   }
};





// ==================================================================
// Static Definition (EA / Translation Unit)
// ==================================================================
ulong CUnifiedTradeLogger::s_globalEventId = 0;

#endif // __LIBC_UNIFIED_TRADE_LOGGER_H__

//+------------------------------------------------------------------+
