//+------------------------------------------------------------------+
//|                                   libCTradeVisualizer.mqh       |
//|              Trade Visualization (SL / TP / Context)            |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCTRADEVISUALIZER_MQH__
#define __LIBCTRADEVISUALIZER_MQH__

#include <MyInclude\NNFX\libCTradeContext.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTradeVisualizer
{
private:
   string ObjName(const string base, const string symbol)
   {
      return base + "_" + symbol;
   }

public:
   // ------------------------------------------------------------
   // Draw SL / TP lines
   // ------------------------------------------------------------
   void DrawStops(const string symbol)
   {
      if(!PositionSelect(symbol))
         return;

      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);

      if(sl > 0)
         {
         ObjectCreate(0, ObjName("SL", symbol), OBJ_HLINE, 0, 0, sl);
         ObjectSetInteger(0, ObjName("SL", symbol), OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, ObjName("SL", symbol), OBJPROP_STYLE, STYLE_DOT);
         }

      if(tp > 0)
         {
         ObjectCreate(0, ObjName("TP", symbol), OBJ_HLINE, 0, 0, tp);
         ObjectSetInteger(0, ObjName("TP", symbol), OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, ObjName("TP", symbol), OBJPROP_STYLE, STYLE_DOT);
         }
   }

   // ------------------------------------------------------------
   // Draw TradeContext label
   // ------------------------------------------------------------
   void DrawContextLabel(const TradeContext &ctx)
   {
      string name = ObjName("CTX", ctx.Symbol);

      string txt =
         "Bias: " + EnumToString(ctx.EntryBias) + "\n" +
         "Score: " + IntegerToString(ctx.ConfirmEntry.Score) + "\n" +
         "Volume: " + EnumToString(ctx.VolumeEntry.State) + "\n" +
         "ATR: " + DoubleToString(ctx.ATREntry.Value, 5);

      if(!ObjectFind(0, name))
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

      ObjectSetString(0, name, OBJPROP_TEXT, txt);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   }

// ------------------------------------------------------------
// Draw Break Even level (visual validation)
// ------------------------------------------------------------
   void DrawBreakEven(const string symbol, const double bePrice)
   {
      if(bePrice <= 0.0)
         return;

      string name = ObjName("BE", symbol);

      if(!ObjectFind(0, name))
         {
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, bePrice);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrGold);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
         }
      else
         {
         ObjectSetDouble(0, name, OBJPROP_PRICE, bePrice);
         }
   }


   // ------------------------------------------------------------
   // Cleanup (on exit or symbol change)
   // ------------------------------------------------------------
   void Clear(const string symbol)
   {
      ObjectDelete(0, ObjName("SL", symbol));
      ObjectDelete(0, ObjName("TP", symbol));
      ObjectDelete(0, ObjName("BE", symbol)); // ✅ NEW
      ObjectDelete(0, ObjName("CTX", symbol));
   }
};

#endif // __LIBCTRADEVISUALIZER_MQH__
/*

✅ How to Wire Visualization
Inside libCTradeEngine.mqh:
CTradeVisualizer viz;


After entry:
viz.DrawStops(_Symbol);
viz.DrawContextLabel(ctx);

During trade management:
viz.DrawStops(_Symbol);
viz.DrawContextLabel(ctx);

On exit:
viz.Clear(_Symbol
//+------------------------------------------------------------------+
