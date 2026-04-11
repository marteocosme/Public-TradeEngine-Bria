//+------------------------------------------------------------------+
//|                                libCEntryStrategyEngine.mqh       |
//|                               Marteo Cosme (2026)  04/10/2026    |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBC_ENTRY_STRATEGY_ENGINE_MQH__
#define __LIBC_ENTRY_STRATEGY_ENGINE_MQH__

#include <MyInclude\\NNFX\\libEnum.mqh>
#include <MyInclude\\NNFX\\libCTradeContext.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CEntryStrategyEngine
{
public:

   // ===============================
   // PUBLIC DISPATCHER
   // ===============================
   EntryCandidate Evaluate(const TradeContext &ctx,
                           enum_entryStrategy strategy)
   {
      EntryCandidate ec;   // ✅ MUST EXIST
      switch(strategy)
         {
         case ENTRY_STANDARD:
            return EvaluateStandard(ctx);

         case ENTRY_BASELINE_CROSS:
            return EvaluateBaselineCross(ctx);

         default:
            ec.allowed = false;
            ec.direction = NoTrade;
            ec.reason = "STRATEGY_NOT_IMPLEMENTED";
            return ec;

         }
   }


private:

   // ===============================
   // R1 — DISTANCE RULE
   // ===============================
   bool DistanceRuleR1(const TradeContext &ctx) const
   {
      /* 
      if(!ctx.ATREntry.IsValid) return false;

      double price = iClose(ctx.Symbol, ctx.EntryPeriod, BAR_SIGNAL);
      double baseline = ctx.BaselineEntryPrice; // must already be stored
      double atr = ctx.ATREntry.Value;

      return (MathAbs(price - baseline) <= atr);
      */
      return true; // TEMP DEBUG
   }

   // ===============================
   // R3 — BRIDGE TOO FAR RULE
   // ===============================
   bool BridgeTooFarR3(const TradeContext &ctx, int maxBars = 7) const
   {
      return true; // future‑proofed
   }

   // ===============================
   // STRATEGY 1 — STANDARD
   // ===============================

   EntryCandidate EvaluateStandard(const TradeContext &ctx)
   {
      EntryCandidate ec;

      if(!DistanceRuleR1(ctx))
         {
         ec.allowed = false;
         ec.direction = NoTrade;
         ec.reason = "R1_DISTANCE_FAIL";
         return ec;
         }

      if(ctx.BaselineEntry.trend == TrendUp &&
            ctx.ConfirmEntry.Signal == Long &&
            ctx.ConfirmEntry.Trend == Long &&
            ctx.VolumeEntry.State == VOL_STATE_ON)
         {
         ec.allowed = true;
         ec.direction = Long;
         ec.reason = "STANDARD_LONG";
         return ec;
         }

      if(ctx.BaselineEntry.trend == TrendDown &&
            ctx.ConfirmEntry.Signal == Short &&
            ctx.ConfirmEntry.Trend == Short &&
            ctx.VolumeEntry.State == VOL_STATE_ON)
         {
         ec.allowed = true;
         ec.direction = Short;
         ec.reason = "STANDARD_SHORT";
         return ec;
         }

      ec.allowed = false;
      ec.direction = NoTrade;
      ec.reason = "STANDARD_FAIL";
      return ec;
   }



   // ===============================
   // STRATEGY 2 — BASELINE CROSS
   // ===============================
   EntryCandidate EvaluateBaselineCross(const TradeContext &ctx)
   {


      EntryCandidate ec;

      if(!DistanceRuleR1(ctx))
         {
         ec.allowed = false;
         ec.direction = NoTrade;
         ec.reason = "R1_DISTANCE_FAIL";
         return ec;
         }

      if(!BridgeTooFarR3(ctx))
         {
         ec.allowed = false;
         ec.direction = NoTrade;
         ec.reason = "R3_BRIDGE_TOO_FAR";
         return ec;
         }

      if(ctx.VolumeEntry.State != VOL_STATE_ON)
         {
         ec.allowed = false;
         ec.direction = NoTrade;
         ec.reason = "VOLUME_FAIL";
         return ec;
         }

      enum_position dir = ctx.BaselineCrossDirection;

      if(dir != NoTrade && ctx.ConfirmEntry.Trend == dir)
         {
         ec.allowed = true;
         ec.direction = dir;
         ec.reason = "BASELINE_CROSS";
         return ec;
         }

      ec.allowed = false;
      ec.direction = NoTrade;
      ec.reason = "BASELINE_CROSS_FAIL";
      return ec;

   }

};

#endif
//+------------------------------------------------------------------+
