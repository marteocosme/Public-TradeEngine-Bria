//+------------------------------------------------------------------+
//|                                       libCPartialCloseEngine.mqh |
//|          ATREntry-based Partial Close (Scaling Out) SRP & Parser-safe |
//|                                                     Marteo Cosme |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCPARTIALCLOSEENGINE_MQH__
#define __LIBCPARTIALCLOSEENGINE_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCTradeContext.mqh>
#include <MyInclude\NNFX\libCATRRiskTracker.mqh>

// ------------------------------------------------------------
// Scaling stage definition
// ------------------------------------------------------------
struct ScaleStage
{
   double atrMultiple;     // e.g. 1.0, 2.0
   double closeFraction;   // e.g. 0.5 = 50%
};

// ------------------------------------------------------------
// Partial Close Engine (LOGIC ONLY)
// ------------------------------------------------------------
class CPartialCloseEngine
{
private:
   CATRRiskTracker *m_tracker;   // injected, not owned

public:
   CPartialCloseEngine()
   {
      m_tracker = NULL;
   }

   void SetATRRiskTracker(CATRRiskTracker &tracker)
   {
      m_tracker = &tracker;
   }

   // ---------------------------------------------------------
   // Evaluate scaling-out condition
   // Returns true if partial close should occur now
   // ---------------------------------------------------------
   bool Evaluate(const TradeContext &ctx,
                 const ScaleStage &stage,
                 double &outCloseLots) const
   {
      if(m_tracker == NULL)
         return false;

      if(!PositionSelect(ctx.Symbol))
         return false;

      if(!ctx.ATREntry.IsValid || ctx.ATREntry.Value <= 0.0)
         return false;

      long ticket = (long)PositionGetInteger(POSITION_TICKET);
      if(ticket <= 0)
         return false;

      // ✅ Parser-safe pointer usage
      if((*m_tracker).IsScaleStageApplied(ticket, stage.atrMultiple))
         return false;

      long posType = PositionGetInteger(POSITION_TYPE);
      enum_position dir = (posType == POSITION_TYPE_BUY ? Long : Short);

      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double price =
         (dir == Long)
         ? SymbolInfoDouble(ctx.Symbol, SYMBOL_BID)
         : SymbolInfoDouble(ctx.Symbol, SYMBOL_ASK);

      double moved = MathAbs(price - entry);
      double requiredMove = ctx.ATREntry.Value * stage.atrMultiple;

      if(moved < requiredMove)
         return false;

      double volume = PositionGetDouble(POSITION_VOLUME);
      if(volume <= 0.0)
         return false;

      double closeLots = NormalizeDouble(volume * stage.closeFraction,2);
      double minLot = SymbolInfoDouble(ctx.Symbol, SYMBOL_VOLUME_MIN);

      if(closeLots < minLot)
         closeLots = minLot;

      if(closeLots >= volume)
         return false; // never close entire position here

      outCloseLots = closeLots;
      return true;
   }
};

#endif // __LIBCPARTIALCLOSEENGINE_MQH__




/* 
1️⃣ Partial‑Close Design (Professional Rules)
✅ Scaling‑Out Model (ATREntry‑Milestones)
Each trade has N stages, defined as:

Stage       Trigger              Action
1           Price ≥ ATREntry * X1     Close 30–50%
2           Price ≥ ATREntry * X2     Close next portion
Final       Let runner ride      Managed by trailing stop


✅ Partial closes happen once per stage
✅ Never close more than remaining volume
✅ Never conflict with BE / Trailing logic

2️⃣ New File — libCPartialCloseEngine.mqh
✅ Responsibilities

Evaluate if a partial close should happen now
Decide how much to close
Does not execute the close (SRP)
Uses ATREntry distance + ticket state

*/