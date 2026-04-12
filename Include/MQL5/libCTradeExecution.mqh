//+------------------------------------------------------------------+
//|                                     libCTradeExecution.mqh       |
//|                  Trade Execution Wrapper (Context-based)         |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCTRADEEXECUTION_MQH__
#define __LIBCTRADEEXECUTION_MQH__

#include <Trade\Trade.mqh>

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCTradeContext.mqh>
#include <MyInclude\NNFX\libCATRRiskTracker.mqh>

// ------------------------------------------------------------------
// CTradeExecution
// - Owns all broker interaction (CTrade)
// - Executes entries, exits, SL/TP modifications
// - SRP compliant: NO indicator logic here
// ------------------------------------------------------------------
class CTradeExecution
{
private:
   CTrade            m_trade;
   CATRRiskTracker  *m_atrTracker;   // injected, NOT owned
   //CContextLogger    m_logger;
   ulong             m_magic;
   string            m_comment;


public:
   CTradeExecution()
   {
      m_magic      = 0;
      m_comment    = "CTX_TRADE";
      m_atrTracker = NULL;
   }

   // ---------------------------------------------------------------
   // Configuration
   // ---------------------------------------------------------------
   void SetMagicNumber(const ulong magic)
   {
      m_magic = magic;
      m_trade.SetExpertMagicNumber((int)magic);
   }

   void SetComment(const string comment)
   {
      m_comment = comment;
   }

   void SetATRRiskTracker(CATRRiskTracker &tracker)
   {
      m_atrTracker = &tracker;
   }

   // ---------------------------------------------------------------
   // ENTRY EXECUTION
   // ---------------------------------------------------------------
   bool ExecuteEntry(const TradeContext &ctx,
                     const double lots,
                     const double slATRMultiplier,
                     const double tpATRMultiplier)
   {
      if(!ctx.IsTradeable)                    return false;
      if(ctx.EntryBias != Long && ctx.EntryBias != Short) return false;
      if(!ctx.ATREntry.IsValid || ctx.ATREntry.Value <= 0.0)        return false;
      if(lots <= 0.0)                      return false;

      string symbol = ctx.Symbol;

      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      if(ask <= 0 || bid <= 0)              return false;

      double entryPrice = (ctx.EntryBias == Long ? ask : bid);

      double slDist = ctx.ATREntry.Value * slATRMultiplier;
      double tpDist = ctx.ATREntry.Value * tpATRMultiplier;

      double sl = 0.0, tp = 0.0;
      if(ctx.EntryBias == Long)
         {
         sl = entryPrice - slDist;
         tp = entryPrice + tpDist;
         }
      else
         {
         sl = entryPrice + slDist;
         tp = entryPrice - tpDist;
         }

      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      sl = NormalizeDouble(sl, digits);
      tp = NormalizeDouble(tp, digits);

      bool sent =
         (ctx.EntryBias == Long)
         ? m_trade.Buy(lots, symbol, 0.0, sl, tp, m_comment)
         : m_trade.Sell(lots, symbol, 0.0, sl, tp, m_comment);

      if(!sent) return false;

      // ------------------------------------------------------------
      // Record ATREntry at entry (parser-safe pointer usage)
      // ------------------------------------------------------------
      if(m_atrTracker != NULL && PositionSelect(symbol))
         {
         long ticket = (long)PositionGetInteger(POSITION_TICKET);
         if(ticket > 0)
            {
            (*m_atrTracker).AddOrUpdate(ticket, ctx.ATREntry.Value);
            }
         }

      return true;
   }

   // ---------------------------------------------------------------
   // EXIT EXECUTION (FULL CLOSE)
   // ---------------------------------------------------------------
   bool ExecuteExit(const TradeContext &ctx)
   {
      if(!ctx.Exit.ShouldExit) return false;
      if(!PositionSelect(ctx.Symbol)) return false;

      return m_trade.PositionClose(ctx.Symbol);
   }

   // ---------------------------------------------------------------
   // STOP LOSS MODIFICATION ONLY
   // ---------------------------------------------------------------
   bool ModifyStopLoss(const string symbol, const double newSL)
   {
      if(!PositionSelect(symbol)) return false;

      double oldSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      bool ok = m_trade.PositionModify(symbol, newSL, tp);
      return ok;
   }

   // ---------------------------------------------------------------
   // TAKE PROFIT MODIFICATION ONLY
   // ---------------------------------------------------------------
   bool ModifyTakeProfit(const string symbol, const double newTP)
   {
      if(!PositionSelect(symbol)) return false;

      double sl = PositionGetDouble(POSITION_SL);
      return m_trade.PositionModify(symbol, sl, newTP);
   }

   // ---------------------------------------------------------------
   // FULL SL / TP MODIFICATION
   // ---------------------------------------------------------------
   bool ModifyStopAndTP(const string symbol,
                        const double sl,
                        const double tp)
   {
      if(!PositionSelect(symbol)) return false;
      return m_trade.PositionModify(symbol, sl, tp);
   }

   // ---------------------------------------------------------------
   // PARTIAL CLOSE (SCALING OUT)
   // ---------------------------------------------------------------
   bool PartialClose(const string symbol, const double closeLots)
   {
      if(!PositionSelect(symbol)) return false;

      double volume = PositionGetDouble(POSITION_VOLUME);
      double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

      if(closeLots <= 0.0 || closeLots >= volume) return false;
      if(closeLots < minLot)                      return false;

      return m_trade.PositionClosePartial(symbol, closeLots);
   }
};

#endif // __LIBCTRADEEXECUTION_MQH__
