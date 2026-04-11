//+------------------------------------------------------------------+
//|                                       libCTrailingStopEngine.mqh |
//|                    Progressive ATREntry Trailing Stop (SRP compliant) |
//|                                          Marteo Cosme 04/02/2026 |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCTRAILINGSTOPENGINE_MQH__
#define __LIBCTRAILINGSTOPENGINE_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCTradeContext.mqh>

class CTrailingStopEngine
{
public:
   // ------------------------------------------------------------
   // Evaluate trailing stop
   // Returns true if SL should be updated, outputs newSL
   // ------------------------------------------------------------
   bool Evaluate(const TradeContext &ctx,
                 const double trailStartATR,
                 const double trailATR,
                 double &outNewSL) const
   {
      if(!PositionSelect(ctx.Symbol))
         return false;

      if(!ctx.ATREntry.IsValid || ctx.ATREntry.Value <= 0.0)
         return false;

      long type = PositionGetInteger(POSITION_TYPE);
      enum_position dir = (type == POSITION_TYPE_BUY ? Long : Short);

      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);

      double price = (dir == Long
                      ? SymbolInfoDouble(ctx.Symbol, SYMBOL_BID)
                      : SymbolInfoDouble(ctx.Symbol, SYMBOL_ASK));

      double moved = MathAbs(price - entry);
      if(moved < ctx.ATREntry.Value * trailStartATR)
         return false;

      int digits = (int)SymbolInfoInteger(ctx.Symbol, SYMBOL_DIGITS);

      double newSL;
      if(dir == Long)
      {
         newSL = price - ctx.ATREntry.Value * trailATR;
         if(newSL <= sl) return false;
      }
      else
      {
         newSL = price + ctx.ATREntry.Value * trailATR;
         if(sl > 0 && newSL >= sl) return false;
      }

      outNewSL = NormalizeDouble(newSL, digits);
      return true;
   }
};

#endif // __LIBCTRAILINGSTOPENGINE_MQH__



/*
✅ Execution Flow (Per Tick or Per Candle)

if(position open)
{
   if(BE not applied yet)
      try BE
   else
      try Trailing
}


✅ Member variables
CBreakEvenEngine   m_be;
CTrailingStopEngine m_trail;
CContextLogger      m_logger;

✅ Init()
m_be.SetATRRiskTracker(m_atrTracker);

✅ After entry decision (log context)

m_logger.LogCSV(ctx);
m_logger.LogJSON(ctx);

✅ Every tick / new candle (manage open trades)

if(PositionSelect(_Symbol))
{
   // Break Even
   m_be.Apply(ctx, inpBEATRxBEXplier, inpXtraPipBE);

   // Trailing Stop
   m_trail.Apply(ctx, inpTSxThrshld, inpTSxATRxplier);
}





✅ Updated BE + Trailing Integration (Correct Logic)
✅ Engine‑side Management (Pseudo‑code)


long ticket = (long)PositionGetInteger(POSITION_TICKET);

double newSL;

// Step 1️ Break Even (only once)
if(!atrTracker.IsBEApplied(ticket))
{
   if(beEngine.Evaluate(ctx, beATRMult, extraPips, newSL))
   {
      if(exec.ModifyStopLoss(ctx.Symbol, newSL))
      {
         atrTracker.MarkBEApplied(ticket);
      }
      return; // ✅ stop here, no trailing this tick
   }
}

// Step 2️ Trailing Stop (only after BE)
if(trailEngine.Evaluate(ctx, trailStartATR, trailATR, newSL))
{
   exec.ModifyStopLoss(ctx.Symbol, newSL);
}
``



✅ Guaranteed precedence
✅ Guaranteed BE one‑time
✅ Clean behavior

*/