//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#ifndef TRADE_LIFECYCLE_CONTROLLER_MQH
#define TRADE_LIFECYCLE_CONTROLLER_MQH

#include <MyInclude\NNFX\TradeEngine\LifecycleTypes.mqh>
#include  <MyInclude\NNFX\TradeEngine\MM_LifecycleSnapshot.mqh>
#include <MyInclude\NNFX\LifecycleSnapshot.mqh>
#include <Arrays\ArrayLong.mqh>
#include <Arrays\ArrayInt.mqh>

static CArrayLong g_tradeIds;
static CArrayInt  g_tradeStates;


// ------------------------------------------------------------
// TradeLifecycleController
// Phase 5 / MM-LOG-01 — Lifecycle transition + snapshot enforcement
// ------------------------------------------------------------
class TradeLifecycleController
{
public:
   TradeLifecycleController()
   {
   };
   ~TradeLifecycleController()
   {
   };

   bool RequestAction(
      ulong trade_id,
      LifecycleAction action,
      RejectionReason& reason
   )
   {
      int idx = GetOrCreateIndex(trade_id);
      LifecycleState current = (LifecycleState)g_tradeStates.At(idx);
      LifecycleState next = current;
      reason = REJECT_NONE;

      switch(action)
         {
         case ACTION_CREATE:
            if(current == LIFECYCLE_UNDEFINED)
               next = LIFECYCLE_CREATED;
            else
               reason = REJECT_INVALID_STATE;
            break;


         case ACTION_ENTER:
            if(current == LIFECYCLE_CREATED)
               next = LIFECYCLE_ENTERED;

            else
               reason = REJECT_INVALID_STATE;
            break;

         case ACTION_MM:
            if(current == LIFECYCLE_ENTERED || current == LIFECYCLE_MANAGED)
               next = LIFECYCLE_MANAGED;
            else
               reason = REJECT_ACTION_NOT_ALLOWED;
            break;

         case ACTION_EXIT:
            if(current == LIFECYCLE_ENTERED || current == LIFECYCLE_MANAGED)
               next = LIFECYCLE_EXITED;
            else
               reason = REJECT_ACTION_NOT_ALLOWED;
            break;

         case ACTION_CLOSE:
            if(current == LIFECYCLE_EXITED)
               next = LIFECYCLE_CLOSED;
            else
               reason = REJECT_LIFECYCLE_CLOSED;
            break;

         default:
            reason = REJECT_ACTION_NOT_ALLOWED;
            break;
         }
      // ALWAYS emit snapshot of trade lifecycle action attempt, even if invalid transition
      if(!EmitLifecycleSnapshot(trade_id, current, action, reason))
         {
         reason = REJECT_MISSING_SNAPSHOT;
         return false;
         }

      // Reject invalid transition AFTER snapshot
      // if(reason != REJECT_NONE)
      //   return false;

      // Apply valid transition
      g_tradeStates.Update(idx, next);
      return true;
   };


 
void HandleEntry()
{
     /*
   // 1. Build BEFORE snapshot
   MM_SNAPSHOT_BEFORE snap_before;
   FillSnapshotBefore_Entry(snap_before);
   EmitSnapshotBefore(snap_before);

   // 2. Money Management calculation
   MM_Result mm_result = moneyManager.CalculateEntryPosition(...);

   // 3. Build AFTER snapshot
   MM_SNAPSHOT_AFTER snap_after;
   FillSnapshotAfter_Entry(mm_result, snap_after);
   EmitSnapshotAfter(snap_after);

   // 4. Existing event log (keep this)
   EmitMMEvent(MM_EVENT_ENTRY, MM_PHASE_ENTRY);

   // 5. Order execution (OUTSIDE MM scope)
   ExecuteOrder(mm_result);
   */
}

private:
   int GetOrCreateIndex(long trade_id)
   {
      int count = g_tradeIds.Total();
      for(int i = 0; i < count; i++)
         {
         if(g_tradeIds.At(i) == trade_id)
            return i;
         }

      g_tradeIds.Add(trade_id);
      g_tradeStates.Add(LIFECYCLE_UNDEFINED);
      return g_tradeIds.Total() - 1;
   }

   bool EmitLifecycleSnapshot(
      long trade_id,
      LifecycleState state,
      LifecycleAction action,
      RejectionReason rejection
   )
   {
      LifecycleSnapshot snap;
      bool has_position = PositionSelectByTicket(trade_id);

      // -------------------------------------------------
      // Identity & Timing
      // -------------------------------------------------
      snap.trade_id  = trade_id;
      snap.symbol    =
         has_position
         ? PositionGetString(POSITION_SYMBOL)
         : Symbol();

      snap.timestamp = TimeCurrent();

      // -------------------------------------------------
      // Lifecycle Context
      // -------------------------------------------------
      snap.lifecycle_state  = state;
      snap.lifecycle_action = action;
      snap.rejection_reason = (int)rejection;

      // -------------------------------------------------
      // Pricing & Position State
      // -------------------------------------------------
      snap.entry_price   = 0.0;
      snap.current_price = 0.0;
      snap.stop_loss     = 0.0;
      snap.take_profit   = 0.0;
      snap.position_size = 0.0;

      // Query execution reality (safe no‑position defaults)
      if(has_position)
         {
         snap.entry_price   = PositionGetDouble(POSITION_PRICE_OPEN);
         snap.stop_loss     = PositionGetDouble(POSITION_SL);
         snap.take_profit   = PositionGetDouble(POSITION_TP);
         snap.position_size = PositionGetDouble(POSITION_VOLUME);

         // Use Bid/Ask depending on position type
         int type = (int)PositionGetInteger(POSITION_TYPE);
         snap.current_price =
            (type == POSITION_TYPE_BUY)
            ? SymbolInfoDouble(snap.symbol, SYMBOL_BID)
            : SymbolInfoDouble(snap.symbol, SYMBOL_ASK);
         }
      else
         {
         // No open position — still log snapshot
         snap.current_price =
            SymbolInfoDouble(snap.symbol, SYMBOL_BID);
         }

      // -------------------------------------------------
      // Risk & P/L
      // -------------------------------------------------
      snap.floating_pnl = 0.0;
      snap.realized_pnl = 0.0;
      snap.risk_percent = 0.0;

      if(PositionSelectByTicket(trade_id))
         {
         snap.floating_pnl = PositionGetDouble(POSITION_PROFIT);
         }

      // -------------------------------------------------
      // MM Context (lifecycle‑only for now)
      // -------------------------------------------------
      snap.mm_action = ACTION_NONE;

      // -------------------------------------------------
      // Emit snapshot
      // -------------------------------------------------
      /* TEMPORARY: enforcement without logger binding yet
      if(!Logger.EmitLifecycleSnapshot(snap))
      {
         // Logging failure invalidates lifecycle transition
         return false;
      }
      */
      return true;

   }


};

#endif // TRADE_LIFECYCLE_CONTROLLER_MQH
