#ifndef TRADE_LIFECYCLE_CONTROLLER_MQH
#define TRADE_LIFECYCLE_CONTROLLER_MQH

#include "LifecycleTypes.mqh"

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
   );

private:
   // Internal lifecycle state storage (unused for now)
   // trade_id → lifecycle state
   // NOTE: Not enforced or validated in Step 2
};

#endif // TRADE_LIFECYCLE_CONTROLLER_MQH
