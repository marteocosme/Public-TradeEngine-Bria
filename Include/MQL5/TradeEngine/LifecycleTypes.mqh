//+------------------------------------------------------------------+
//| LifecycleTypes.mqh                                               |
//| Phase 5 — Trade Lifecycle Orchestration                           |
//| Step 1: Scaffolding enums ONLY                                    |
//|                                                                  |
//| NOTE:                                                            |
//| - No logic                                                       |
//| - No engine references                                           |
//| - No behavior changes                                            |
//+------------------------------------------------------------------+
#ifndef LIFECYCLE_TYPES_MQH
#define LIFECYCLE_TYPES_MQH


// ------------------------------------------------------------------
// Trade lifecycle logical states
// ------------------------------------------------------------------
enum LifecycleState
{
   LIFECYCLE_UNDEFINED = 0,   // Safety default
   LIFECYCLE_CREATED,        // Trade intent created
   LIFECYCLE_ENTERED,        // Entry executed
   LIFECYCLE_MANAGED,        // Money Management active
   LIFECYCLE_EXITED,         // Exit executed
   LIFECYCLE_CLOSED          // Lifecycle terminated
};

// ------------------------------------------------------------------
// Lifecycle actions requested by engines
// ------------------------------------------------------------------
enum LifecycleAction
{
   ACTION_NONE = 0,           // Safety default
   ACTION_CREATE,             // Create trade intent / trade_id
   ACTION_ENTER,              // Confirm entry execution
   ACTION_MM,                 // Money management action
   ACTION_EXIT,               // Request exit
   ACTION_CLOSE               // Finalize lifecycle
};

// ------------------------------------------------------------------
// Rejection reasons returned by orchestrator
// ------------------------------------------------------------------
enum RejectionReason
{
   REJECT_NONE = 0,            // No rejection
   REJECT_INVALID_STATE,       // Lifecycle state mismatch
   REJECT_MISSING_TRADE_ID,    // trade_id required but missing
   REJECT_ACTION_NOT_ALLOWED,  // Action not permitted in state
   REJECT_LIFECYCLE_CLOSED     // Trade already closed
};

#endif // LIFECYCLE_TYPES_MQH