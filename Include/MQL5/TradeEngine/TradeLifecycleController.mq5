#include "TradeLifecycleController.mqh"

// ------------------------------------------------------------
// Constructor / Destructor
// ------------------------------------------------------------
TradeLifecycleController::TradeLifecycleController()
{
   // No initialization logic in Step 2
}

TradeLifecycleController::~TradeLifecycleController()
{
   // No cleanup logic in Step 2
}

// ------------------------------------------------------------
// RequestAction — STUB IMPLEMENTATION
// ------------------------------------------------------------
bool TradeLifecycleController::RequestAction(
   long trade_id,
   LifecycleAction action,
   TradeContext& ctx,
   RejectionReason& reason
)
{
   // Step 2 behavior:
   // - Do nothing
   // - Do not inspect inputs
   // - Do not mutate state
   // - Always approve
   reason = REJECT_NONE;
   return true;
}