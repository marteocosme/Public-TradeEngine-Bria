//+------------------------------------------------------------------+
//|                                          libCBreakEvenEngine.mqh |
//|                     Break-Even Engine (ATREntry-based, SRP compliant) |
//|                                          Marteo Cosme 04/02/2026 |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCBREAKEVENENGINE_MQH__
#define __LIBCBREAKEVENENGINE_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCTradeContext.mqh>

class CBreakEvenEngine
{
public:
   // ------------------------------------------------------------
   // Evaluate Break-Even
   // Returns true if BE should be applied, and outputs newSL
   // ------------------------------------------------------------
   bool Evaluate(const TradeContext &ctx,
                 const double beATRMultiplier,
                 const double extraPips,
                 double &outNewSL) const
   {
      if(!PositionSelect(ctx.Symbol))
         return false;

      if(!ctx.ATREntry.IsValid || ctx.ATREntry.Value <= 0.0)
         return false; //Posible fail point

      long type = PositionGetInteger(POSITION_TYPE);
      enum_position dir = (type == POSITION_TYPE_BUY ? Long : Short);

      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);

      double price = (dir == Long
                      ? SymbolInfoDouble(ctx.Symbol, SYMBOL_BID)
                      : SymbolInfoDouble(ctx.Symbol, SYMBOL_ASK));

      // Distance required to trigger BE
      double triggerDist = ctx.ATREntry.Value * beATRMultiplier;
      double moved = MathAbs(price - entry);

      if(moved < triggerDist)
         return false; //Posible fail point

      double point = SymbolInfoDouble(ctx.Symbol, SYMBOL_POINT);
      int digits   = (int)SymbolInfoInteger(ctx.Symbol, SYMBOL_DIGITS);
      double extraPrice = extraPips * point;

      double newSL = entry;

      if(dir == Long)
      {
         if(sl >= entry) return false; // already BE or better
         newSL = entry + extraPrice;
      }
      else
      {
         if(sl <= entry && sl > 0) return false;
         newSL = entry - extraPrice;
      }

      outNewSL = NormalizeDouble(newSL, digits);
      return true;
   }
   
};

#endif // __LIBCBREAKEVENENGINE_MQH__


