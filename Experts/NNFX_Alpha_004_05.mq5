//+------------------------------------------------------------------+
//| NNFX_Alpha_004_05.mq5                                           |
//| Production Wiring Patch                                         |
//| Marteo Cosme                                                    |
//+------------------------------------------------------------------+
#property strict
#property copyright "Marteo Cosme"
#property version   "1.01"

// =============================
// Includes
// =============================
#include <MyInclude\NNFX\libCTradeContext.mqh>
#include <MyInclude\NNFX\libCTradeEngine.mqh>
// ==================================================================
// Static member
// ==================================================================
ulong CUnifiedTradeLogger::s_globalEventId = 0;
// =============================
// Global Engine Instance
// =============================
CTradeEngine Engine;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Engine.Init();   // ✅ Fully wires ATR tracker, execution, BE, scaling, debug
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Engine.OnDeinit(); // ✅ Safe cleanup
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // ✅ Delegate everything to the trade engine
   Engine.OnTick(_Symbol);
}
//+------------------------------------------------------------------+