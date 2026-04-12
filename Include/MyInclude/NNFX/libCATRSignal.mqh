//+------------------------------------------------------------------+
//|                                           libCATRSignal.mqh      |
//|                    ATR Signal Engine (Baseline-style)            |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+

//  ATR Signal Engine (Baseline-style)
//
//  - Computes ATR on BAR_SIGNAL (no repaint)
//  - Caches indicator handle for performance
//  - ✅ Explicit Reset() for lifecycle safety


#property strict

#ifndef __LIBCATRSIGNAL_MQH__
#define __LIBCATRSIGNAL_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>

// ------------------------------------------------------------------
// CATRSignal
// - Baseline-style ATR engine: Update() computes once and stores ATRResult
// - Caches indicator handle; recreates when symbol/tf/period changes
// - Uses BAR_SIGNAL by default (last closed candle), avoiding repaint
// ------------------------------------------------------------------
class CATRSignal
{
private:
   int             m_handle;
   string          m_symbol;
   ENUM_TIMEFRAMES m_tf;
   int             m_period;
   int             m_buffer_size;
   double          m_bufATR[];
   ATRResult       m_result;

// ------------------------------------------------------------
// Internal helpers
// ------------------------------------------------------------
private:
   void ResetResult()
   {
      m_result.Reset();
   }

   // Recreate handle if configuration changed or handle is invalid
   bool NeedsRecreate(const string symbol, const ENUM_TIMEFRAMES tf, const int period) const
   {
      if(m_handle == INVALID_HANDLE) return true;
      if(m_symbol != symbol) return true;
      if(m_tf     != tf)     return true;
      if(m_period != period) return true;
      return false;
   }

   bool InitHandle(const string symbol, const ENUM_TIMEFRAMES tf, const int period)
   {
      if(m_handle != INVALID_HANDLE)
         {
         IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
         }

      m_handle = iATR(symbol, tf, period);
      if(m_handle == INVALID_HANDLE)
         {
         PrintFormat("[CATRSignal] Failed to create iATR handle. err=%d", GetLastError());
         return false;
         }

      // cache current config
      m_symbol = symbol;
      m_tf     = tf;
      m_period = period;

      return true;
   }

   bool CopyOrRetry(const int start_pos, const int count)
   {
      ArrayResize(m_bufATR, count);
      ArraySetAsSeries(m_bufATR, true);

      int copied = CopyBuffer(m_handle, 0, start_pos, count, m_bufATR);
      if(copied >= count) return true;

      // retry once (history sync / transient)
      ResetLastError();
      Sleep(20);
      copied = CopyBuffer(m_handle, 0, start_pos, count, m_bufATR);

      return (copied >= count);
   }

// ------------------------------------------------------------
// Public API
// ------------------------------------------------------------
public:
   CATRSignal()
   {
      m_handle = INVALID_HANDLE;
      m_symbol = "";
      m_tf     = PERIOD_CURRENT;
      m_period = 14;

      // default: enough for BAR_PREVIOUS usage
      m_buffer_size = EnsureForPrevious(3);

      ArraySetAsSeries(m_bufATR, true);
      ResetResult();
   }

   ~CATRSignal()
   {
      Reset(); // ✅ ensures clean shutdown
   }

   // ---------------------------------------------------------
   // ✅ Explicit lifecycle reset (IMPORTANT)
   // ---------------------------------------------------------
   void Reset()
   {
      if(m_handle != INVALID_HANDLE)
      {
         IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
      }

      m_symbol = "";
      m_tf     = PERIOD_CURRENT;
      m_period = 0;

      ResetResult();
      ArrayFree(m_bufATR);
   }

   // Optional: adjust internal buffer depth
   void SetBufferSize(const int n)
   {
      m_buffer_size = EnsureForPrevious(n);
   }

   ATRResult Result() const
   {
      return m_result;
   }

   // ------------------------------------------------------------------
   // Update: compute ATR on BAR_SIGNAL by default
   // Returns true if ATR is valid and stored in Result()
   // ------------------------------------------------------------------
   bool Update(const string symbol,
               const ENUM_TIMEFRAMES tf,
               const int period,
               const int barShift = BAR_SIGNAL)
   {
      ResetResult();

      // Validate arguments
      if(period <= 0)
         {
         Print("[CATRSignal] Invalid ATR period.");
         return false;
         }
      if(barShift < 0)
         {
         Print("[CATRSignal] Invalid barShift.");
         return false;
         }

      // Recreate handle when needed
      if(NeedsRecreate(symbol, tf, period))
         {
         if(!InitHandle(symbol, tf, period))
            return false;
         }

      // We only need 1 value at the requested shift.
      // But we keep a configurable buffer size available if you later want
      // ATR comparisons across bars (e.g., volatility regimes).
      int needed = 1;

      if(!CopyOrRetry(barShift, needed))
         {
         PrintFormat("[CATRSignal] CopyBuffer failed. copied<%d err=%d", needed, GetLastError());
         return false;
         }

      double atr = m_bufATR[0];
      if(atr <= 0.0 || atr == EMPTY_VALUE)
         return false;

      m_result.Value   = NormalizeDouble(atr, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      m_result.IsValid = true;
      m_result.Time    = iTime(symbol, tf, barShift);

      return true;
   }

   // ------------------------------------------------------------------
   // Convenience getters (optional helpers)
   // ------------------------------------------------------------------

   // ATR in raw price units (same as indicator output)
   double ATR_Value() const
   {
      return m_result.Value;
   }

   // ATR converted to points (e.g., 0.00123 / _Point)
   double ATR_Points(const string symbol) const
   {
      if(!m_result.IsValid) return 0.0;
      double pt = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(pt <= 0.0) return 0.0;
      return (m_result.Value / pt);
   }

   // ATR converted to pips (handles 5-digit/3-digit brokers)
   // - For 5-digit FX: 10 points = 1 pip
   // - For 4-digit FX: 1 point  = 1 pip
   double ATR_Pips(const string symbol) const
   {
      if(!m_result.IsValid) return 0.0;

      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double points = ATR_Points(symbol);

      // Common pip scaling: if digits is 3 or 5 => pip = 10 points
      if(digits == 3 || digits == 5)
         return points / 10.0;

      return points;
   }
};

#endif // __LIBCATRSIGNAL_MQH__

/* Example: store ATR in TradeContext
CATRSignal atrSignal;
atrSignal.Update(_Symbol, inpTradeExecutionPeriod, (int)inpATRinterval, BAR_SIGNAL);

ATRResult ar = atrSignal.Result();
if(ar.IsValid)
{
   // ar.Value is ATR in price units
}
``


Example: ATR-based SL/TP sizing
double atr = ar.Value;
double slPriceDistance = atr * inpSLxATRxPlier;
double tpPriceDistance = atr * inpTPxATRxPlier;





*/
//+------------------------------------------------------------------+
