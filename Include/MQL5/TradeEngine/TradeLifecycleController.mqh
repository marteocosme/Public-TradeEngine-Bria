#ifndef TRADE_LIFECYCLE_CONTROLLER_MQH
#define TRADE_LIFECYCLE_CONTROLLER_MQH

#include "LifecycleTypes.mqh"
#include <Arrays\ArrayLong.mqh>
#include <Arrays\ArrayInt.mqh>

static CArrayLong g_tradeIds;
static CArrayInt  g_tradeStates;

// Forward declaration only
struct TradeContext;

// ------------------------------------------------------------
// TradeLifecycleController
// Phase 5 — Step 2: Skeleton only (NO enforcement)
// ------------------------------------------------------------
class TradeLifecycleController
{
public:
   TradeLifecycleController();
   ~TradeLifecycleController();

   // Request lifecycle action (STUB — always returns true)
   bool RequestAction(
      long trade_id,
      LifecycleAction action,
      TradeContext& ctx,
      RejectionReason& reason
   )
   {
   int idx = GetOrCreateIndex(trade_id);
   int current = g_tradeStates.At(idx);
   int next = current;

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

   // ❌ Reject invalid transition
   if(reason != REJECT_NONE)
      return false;

   // IMPORTANT: even if transition is invalid, we do NOT reject yet
   g_tradeStates.Update(idx, next);

   return true; // always approve in Step 7
   };

private:
   // Internal lifecycle state storage (unused for now)
   // trade_id → lifecycle state
   // NOTE: Not enforced or validated in Step 2
   int GetOrCreateIndex(long trade_id){
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

};

#endif // TRADE_LIFECYCLE_CONTROLLER_MQH
