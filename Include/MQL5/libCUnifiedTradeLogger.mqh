//+------------------------------------------------------------------+
//| libCUnifiedTradeLogger.mqh                                       |
//| Unified Trade Logger — Phase 4.3.x Aligned                       |
//| Marteo Cosme                                                     |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBC_UNIFIED_TRADE_LOGGER_MQH__
#define __LIBC_UNIFIED_TRADE_LOGGER_MQH__
#define MM_EXPECTED_SNAPSHOT_COLUMNS MM_LogSchema::SnapShotColumnCount()

#include <MyInclude\\NNFX\\libEnum.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\MM_LogSnapshotRecords.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\libCLogHeaderDispatcher.mqh>
#include <MyInclude\\NNFX\\Core\\Logging\\MM_LogSchema.mqh>
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
   string              position_type;// "LONG" | "SHORT" | "NA"

   // ✅ NEW FIELD (safe extension)
   int                 cycle_id;   // Lifecycle grouping ID
   ulong               correlation_id;
   int                 scale_steps;
   double              scale_fraction_total;
   string              action_summary;

   // ✅ E2 Fields
   string              close_reason;
   double              close_price;
   double              close_profit;
   double              close_volume;
   ulong               deal_id;

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
         MM_LogSchema::EventHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_events);
         }


      //int actual_columns = 17; // must match your FileWrite fields

      double close_price   = evt.close_price;
      double close_profit  = evt.close_profit;
      double close_volume  = evt.close_volume;
      ulong  deal_id       = evt.deal_id;
      string close_reason = evt.close_reason;

      if(evt.event_type == MM_EVENT_CLOSE && close_reason == "")
         close_reason = "UNKNOWN";


      bool allow_close_fields =
         (evt.event_type == MM_EVENT_CLOSE) ||
         (evt.event_type == MM_EVENT_SCALE_OUT);


// ✅ sanitize invalid values
      // if(evt.event_type != MM_EVENT_CLOSE)
      if(!allow_close_fields)
         {
         close_price  = 0.0;
         close_profit = 0.0;
         close_volume = 0.0;
         deal_id      = 0;
         close_reason = "";

         }


      FileWrite(
         h,
         NextDebugEventId(),              // DEBUG ONLY
         evt.correlation_id,              // NEW correlation_id
         TimeToString(evt.event_time, TIME_DATE | TIME_SECONDS),
         evt.symbol,
         EnumToString(evt.timeframe),
         EnumToString(evt.phase),
         EnumToString(evt.event_type),
         evt.cycle_id,
         evt.trade_id,
         evt.ticket,
         evt.position_type,
         evt.action_summary,
         evt.scale_steps,
         evt.scale_fraction_total,
         close_reason,
         close_price,
         close_profit,
         close_volume,
         deal_id

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
         MM_LogSchema::SnapShotHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_snapshots);
         }


      int actual_columns = 36; // must match your FileWrite fields

      if(actual_columns != MM_EXPECTED_SNAPSHOT_COLUMNS)
         {
         Print("❌ SCHEMA ERROR: Column mismatch. Expected=",
               MM_EXPECTED_SNAPSHOT_COLUMNS,
               " Got=", actual_columns);
         }

      FileWrite(
         h,

         NextDebugEventId(),
         rec.correlation_id,

         rec.cycle_id,
         rec.internal_trade_id,
         rec.ticket,
         rec.position_id,
         rec.position_type,

         TimeToString(rec.timestamp, TIME_DATE | TIME_SECONDS),
         rec.symbol,
         EnumToString(rec.timeframe),
         "MM_SNAPSHOT_BEFORE",
         rec.mm_phase,
         rec.mm_event,

         rec.balance,
         rec.equity,
         rec.free_margin,

         rec.current_position_lots,
         rec.current_risk_exposure,

         rec.current_price,
         rec.atr_value,

         rec.take_profit,
         rec.floating_pnl,
         rec.realized_pnl,

         rec.stoploss_points,
         rec.value_per_point,

         rec.risk_model,
         rec.risk_value,
         rec.risk_amount_used,

         rec.scale_atr_multiple,
         rec.scale_fraction,

         rec.action_executed,
         rec.execution_reason,
         rec.previous_stoploss,
         rec.new_stoploss,
         rec.closed_lots,
         rec.event_outcome

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
         MM_LogSchema::SnapShotHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_snapshots);

         }


      int actual_columns = 36; // must match your FileWrite fields

      if(actual_columns != MM_EXPECTED_SNAPSHOT_COLUMNS)
         {
         Print("❌ SCHEMA ERROR: Column mismatch. Expected=",
               MM_EXPECTED_SNAPSHOT_COLUMNS,
               " Got=", actual_columns);
         }

      if(rec.mm_phase == "" || rec.mm_event == "")
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
         NextDebugEventId(),
         rec.correlation_id,

         rec.cycle_id,
         rec.internal_trade_id,
         rec.ticket,
         rec.position_id,
         rec.position_type,

         TimeToString(rec.timestamp, TIME_DATE | TIME_SECONDS),
         rec.symbol,
         EnumToString(rec.timeframe),
         "MM_SNAPSHOT_AFTER",
         rec.mm_phase,
         rec.mm_event,

         rec.balance,
         rec.equity,
         rec.free_margin,

         rec.current_position_lots,
         rec.current_risk_exposure,

         rec.current_price,
         rec.atr_value,

         rec.take_profit,
         rec.floating_pnl,
         rec.realized_pnl,

         rec.stoploss_points,
         rec.value_per_point,

         rec.risk_model,
         rec.risk_value,
         rec.risk_amount_used,

         rec.scale_atr_multiple,
         rec.scale_fraction,

         rec.action_executed,
         rec.execution_reason,
         rec.previous_stoploss,
         rec.new_stoploss,
         rec.closed_lots,
         rec.event_outcome

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
         MM_LogSchema::SummaryHeader(h);

         // ✅ IMPORTANT: mark as written
         m_header.MarkHeaderWritten(m_csv_summary);

         }
      FileWrite(h,
                // --- Identity ---
                s.cycle_id,
                s.internal_trade_id,
                s.trade_id,
                s.ticket,
                s.position_id,
                s.position_type,
                // --- Symbol / Lifecycle Timing ---
                s.symbol,
                TimeToString(s.entry_time, TIME_DATE | TIME_SECONDS),
                TimeToString(s.exit_time, TIME_DATE | TIME_SECONDS),
                s.duration_sec,
                // --- Price / PnL ---
                s.entry_price,
                s.exit_price,
                s.pnl,
                // --- Lifecycle Aggregates ---
                s.scale_count,
                s.trail_count,
                s.be_triggered,
                
                // total_traded_volume:
                // Aggregated lifecycle volume = sum of SCALE_OUT + CLOSE volumes
                // DO NOT confuse with close_volume (final CLOSE only)
                s.total_traded_volume,
                
                // --- Broker Close Evidence ---
                s.close_reason,
                s.close_volume,
                s.deal_id,
                // --- Lifecycle Status ---
                s.lifecycle_status

               );
      FileClose(h);

   }

};





// ==================================================================
// Static Definition (EA / Translation Unit)
// ==================================================================
ulong CUnifiedTradeLogger::s_globalEventId = 0;

#endif // __LIBC_UNIFIED_TRADE_LOGGER_H__

//+------------------------------------------------------------------+
