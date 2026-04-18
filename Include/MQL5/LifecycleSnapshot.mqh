//+------------------------------------------------------------------+
//| LifecycleSnapshot.mqh                                           |
//| Execution-level trade lifecycle snapshot (MM-LOG-01)            |
//+------------------------------------------------------------------+
#ifndef __LIFECYCLE_SNAPSHOT_MQH__
#define __LIFECYCLE_SNAPSHOT_MQH__

#include <MyInclude\NNFX\TradeEngine\LifecycleTypes.mqh>

static const int LIFECYCLE_SNAPSHOT_VERSION = 1;
struct LifecycleSnapshot
{
   // -------------------------------------------------
   // Identity & Timing
   // -------------------------------------------------
   long              trade_id;          // Stable trade identifier
   string            symbol;            // Instrument
   datetime          timestamp;         // Snapshot time (terminal / tester time)

   // -------------------------------------------------
   // Lifecycle Context
   // -------------------------------------------------
   LifecycleState    lifecycle_state;   // Current state at snapshot time
   LifecycleAction   lifecycle_action;  // Action being attempted / executed
   int               rejection_reason;  // RejectionReason enum (0 if none)

   // -------------------------------------------------
   // Pricing & Position State (Execution Reality)
   // -------------------------------------------------
   double            entry_price;       // Executed entry price
   double            current_price;     // Bid or Ask used at snapshot time
   double            stop_loss;          // Current SL (0 if none)
   double            take_profit;        // Current TP (0 if none)
   double            position_size;      // Open volume (lots)

   // -------------------------------------------------
   // Risk & P/L
   // -------------------------------------------------
   double            floating_pnl;       // Unrealized P/L
   double            realized_pnl;       // Closed P/L so far
   double            risk_percent;       // Risk % or R-equivalent

   // -------------------------------------------------
   // Money Management Context
   // -------------------------------------------------
   int               mm_action;          // NONE / BE / SCALE / TRAIL
};
#endif // __LIFECYCLE_SNAPSHOT_MQH__