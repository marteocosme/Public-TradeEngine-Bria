//+------------------------------------------------------------------+
//|                                          libCRiskEngine.mqh      |
//|                       Risk Sizing Engine (Context-based)         |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-03   |
//+------------------------------------------------------------------+
//  Responsibilities:
//  - Risk percent calculation (Balance / Equity / Fixed)
//  - Anti-Martingale progression
//  - Stop-distance -> lot size conversion
//  - Broker-safe lot normalization
//
//\
//  ALL risk computation must flow through ComputeLotSize()



#property strict
#ifndef __LIBCRISKENGINE_MQH__
#define __LIBCRISKENGINE_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCTradeContext.mqh>


// ================================================================
// Risk Parameter Bundle
// ================================================================
// Explicit, loggable, and extensible risk policy definition
// ================================================================

struct RiskParams
{
   enum_riskMethod Method;     // Balance / Equity / Fixed
   double BaseRiskPercent;     // e.g. 0.01 (1%)
   double FixedRiskAmount;     // if Method == RISK_FIXED

   // Anti‑Martingale
   bool EnableAntiMartingale;
   double RiskStep;            // e.g. 0.005 (0.5%)
   double MaxRiskPercent;      // e.g. 0.05 (0.5%)

   // Stop sizing
   double StopATRMultiplier;  // e.g. 1.5
};


// ------------------------------------------------------------------
// CRiskEngine
// - Computes risk amount and lot size based on TradeContext
// - Handles Anti-Martingale logic
// - Does NOT place trades
// ------------------------------------------------------------------
class CRiskEngine
{
private:
   uint   m_profitCount;
   double m_riskMultiplier;
   double m_lastComputedRiskAmount;   // ✅ MM-LOG-01 support

   // ===============================================================
   // Anti-Martingale: check last closed trade result
   // ===============================================================
   bool LastTradeWasProfit() const
   {
      HistorySelect(0, TimeCurrent());
      int deals = HistoryDealsTotal();
      if(deals <= 0) return false;

      ulong ticket = HistoryDealGetTicket(deals - 1);
      if(ticket == 0) return false;

      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      return (profit > 0.0);
   }

   // ------------------------------------------------------------
   double ApplyAntiMartingale(
      const double baseRisk,
      const RiskParams& p
   )
   {
      if(!p.EnableAntiMartingale)
         return baseRisk;

      if(LastTradeWasProfit())
      {
         m_profitCount++;
         m_riskMultiplier = 1.0 + (m_profitCount * p.RiskStep);
      }
      else
      {
         ResetAntiMartingale();
      }

      double risk = baseRisk * m_riskMultiplier;
      if(risk > p.MaxRiskPercent)
         risk = p.MaxRiskPercent;

      return risk;
   }
   
   
   // ------------------------------------------------------------
   double RiskMoney(
      enum_riskMethod method,
      double riskPercent,
      double fixedAmount
   )
   {
      double riskAmount = 0.0;
      switch(method)
      {
         case RISK_BALANCE:
            riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * riskPercent;
            break;

         case RISK_EQUITY:
            riskAmount = AccountInfoDouble(ACCOUNT_EQUITY) * riskPercent;
            break;

         case RISK_FIXED:
            riskAmount = fixedAmount;
            break;
      }
      m_lastComputedRiskAmount = NormalizeDouble(riskAmount, 2); // ✅ MM-LOG-01 support
      return NormalizeDouble(riskAmount, 2);
   }

   // ===============================================================
   // Lot normalization (broker-safe)
   // ===============================================================
   double NormalizeLots(const string symbol, double lots) const
   {
      double minLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

      if(lots < minLot) lots = minLot;
      if(lots > maxLot) lots = maxLot;

      if(stepLot > 0)
         lots = MathFloor(lots / stepLot) * stepLot;

      return NormalizeDouble(lots, 2);
   }
   // ------------------------------------------------------------
   double LotsFromStopDistance(
      const string symbol,
      double riskMoney,
      double stopDistancePrice
   ) const
   {
      if(riskMoney <= 0.0 || stopDistancePrice <= 0.0)
         return 0.0;

      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0.0) return 0.0;

      double stopPoints = stopDistancePrice / point;

      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickValue <= 0.0 || tickSize <= 0.0)
         return 0.0;

      double valuePerPoint = tickValue * (point / tickSize);
      double riskPerLot    = stopPoints * valuePerPoint;

      if(riskPerLot <= 0.0)
         return 0.0;

      return NormalizeLots(symbol, riskMoney / riskPerLot);
   }

   // ⚠️ DEPRECATED — do not use outside CRiskEngine
   // ===============================================================
   // Effective risk percent (Anti-Martingale aware)
   // ===============================================================
   double EffectiveRiskPercent(const bool enableAntiMartingale,
                               const double baseRiskPercent,
                               const double riskStep,
                               const double maxRiskPercent)
   {
      if(!enableAntiMartingale)
         return baseRiskPercent;

      if(LastTradeWasProfit())
      {
         m_profitCount++;
         m_riskMultiplier = 1.0 + (m_profitCount * riskStep);
      }
      else
      {
         m_profitCount = 0;
         m_riskMultiplier = 1.0;
      }

      double rp = baseRiskPercent * m_riskMultiplier;
      if(rp > maxRiskPercent)
         rp = maxRiskPercent;

      return rp;
   }

   // ===============================================================
   // Risk amount in account currency
   // ===============================================================
   double RiskAmount(enum_riskMethod method,
                     const double riskPercent,
                     const double fixedAmount)
   {
      switch(method)
      {
         case RISK_BALANCE:
            return AccountInfoDouble(ACCOUNT_BALANCE) * riskPercent;

         case RISK_EQUITY:
            return AccountInfoDouble(ACCOUNT_EQUITY) * riskPercent;

         case RISK_FIXED:
            return fixedAmount;

         default:
            return AccountInfoDouble(ACCOUNT_BALANCE) * riskPercent;
      }
   }



   // ===============================================================
   // Convert stop distance (price) to lots using broker specs
   // ===============================================================
   double LotsFromRisk(const string symbol,
                       const double riskMoney,
                       const double stopDistancePrice) const
   {
      if(riskMoney <= 0.0 || stopDistancePrice <= 0.0)
         return 0.0;

      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0.0)
         return 0.0;

      double stopPoints = stopDistancePrice / point;
      if(stopPoints <= 0.0)
         return 0.0;

      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickValue <= 0.0 || tickSize <= 0.0)
         return 0.0;

      // Money per point per lot
      double valuePerPoint = tickValue * (point / tickSize);
      if(valuePerPoint <= 0.0)
         return 0.0;

      double riskPerLot = stopPoints * valuePerPoint;
      if(riskPerLot <= 0.0)
         return 0.0;

      double lots = riskMoney / riskPerLot;
      return NormalizeLots(symbol, lots);
   }


// ---------------------------------------------------------------
// Public API (INTENTIONALLY MINIMAL)
// ---------------------------------------------------------------
public:
   CRiskEngine()
   {
      ResetAntiMartingale();
      m_lastComputedRiskAmount = 0.0;
   }

   // ------------------------------------------------------------
   // Reset risk progression manually (testing / restart safety)
   // ------------------------------------------------------------
   void ResetAntiMartingale()
   {
      m_profitCount   = 0;
      m_riskMultiplier = 1.0;
   }

   // =============================================================
   // ✅ SINGLE AUTHORITY ENTRY POINT
   // =============================================================
   // Returns lot size based on:
   // - TradeContext (ATREntry, Symbol)
   // - Explicit RiskParams
   // =============================================================
   double ComputeLotSize(const TradeContext &ctx,
                         const RiskParams   &p)
   {
      if(!ctx.ATREntry.IsValid)
         return 0.0;

      double stopDistance = ctx.ATREntry.Value * p.StopATRMultiplier;
      if(stopDistance <= 0.0)
         return 0.0;

      double effectiveRisk =
         ApplyAntiMartingale(p.BaseRiskPercent, p);

      double moneyRisk =
         RiskMoney(p.Method, effectiveRisk, p.FixedRiskAmount);

      return LotsFromStopDistance(
         ctx.Symbol,
         moneyRisk,
         stopDistance
      );
   }
   double GetLastComputedRiskAmount() const
   {
      return NormalizeDouble(m_lastComputedRiskAmount,2);
   }

};



#endif // __LIBCRISKENGINE_MQH__

