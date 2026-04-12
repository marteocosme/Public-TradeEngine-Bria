//+------------------------------------------------------------------+
//|                                             libCBaseline.mqh     |
//|                        Baseline Framework (Aligned Architecture) |
//|                                                     Marteo Cosme |
//|                                           Updated: 2026-04-03    |
//+------------------------------------------------------------------+
//
//  - Baseline-style Update() -> Result()
//  - Supports MA / SWMA
//  - Optional ATR bands
//  - ✅ Explicit Reset() for lifecycle safety
//
//  Marteo Cosme
//  Updated: 2026-04-03
//
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBCBASELINE_MQH__
#define __LIBCBASELINE_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>

// Paths
#define PATH_TOOLBOX "\\Indicators\\Toolbox\\"
#define SWMA_FILENAME (PATH_TOOLBOX + "SWMA.ex5")

// ------------------------------------------------------------
// Internal state container
// ------------------------------------------------------------
struct BaselineState
{
   BaselineResult result;
   bool     IsValid;
   datetime Time;
   double   Base;
   double   Upper;
   double   Lower;


   void Reset()
   {
      result.signal = SigNone;
      result.trend  = TrendNone;
      IsValid = false;
      Time    = 0;
      Base    = EMPTY_VALUE;
      Upper   = EMPTY_VALUE;
      Lower   = EMPTY_VALUE;
   }
};

// ------------------------------------------------------------
// CBaseline
// ------------------------------------------------------------
class CBaseline
{
private:
   int             m_baseHandle;
   int             m_atrHandle;

   // Cached parameters
   string          m_symbol;
   ENUM_TIMEFRAMES m_tf;
   enum_Baseline   m_type;
   int             m_period;
   int             m_shift;
   ENUM_MA_METHOD  m_method;
   ENUM_APPLIED_PRICE m_price;
   int             m_atrPeriod;

   // Buffers
   double          m_baseBuf[];
   double          m_atrBuf[];

   // State
   BaselineState   m_state;
   int             m_buffer_size;

// ------------------------------------------------------------
private:

   void ResetInternal()
   {
      if(m_baseHandle != INVALID_HANDLE)
         {
         IndicatorRelease(m_baseHandle);
         m_baseHandle = INVALID_HANDLE;
         }

      if(m_atrHandle != INVALID_HANDLE)
         {
         IndicatorRelease(m_atrHandle);
         m_atrHandle = INVALID_HANDLE;
         }

      m_symbol     = "";
      m_tf         = PERIOD_CURRENT;
      m_type       = MA;
      m_period     = 0;
      m_shift      = 0;
      m_method     = MODE_SMA;
      m_price      = PRICE_CLOSE;
      m_atrPeriod  = 0;

      ArrayFree(m_baseBuf);
      ArrayFree(m_atrBuf);
      m_state.Reset();
   }

// ------------------------------------------------------------
// Public API
// ------------------------------------------------------------
public:

   CBaseline()
   {
      m_baseHandle  = INVALID_HANDLE;
      m_atrHandle   = INVALID_HANDLE;
      m_buffer_size = EnsureForPrevious(3);
      ArraySetAsSeries(m_baseBuf, true);
      ArraySetAsSeries(m_atrBuf, true);
      m_state.Reset();
   }

   ~CBaseline()
   {
      Reset(); // ✅ clean shutdown
   }

   // ---------------------------------------------------------
   // ✅ Explicit lifecycle reset (IMPORTANT)
   // ---------------------------------------------------------
   void Reset()
   {
      ResetInternal();
   }

   void SetBufferSize(int n)
   {
      m_buffer_size = EnsureForPrevious(n);
   }

   BaselineResult Result() const
   {
      return m_state.result;
   }
   BaselineState  State()  const
   {
      return m_state;
   }

   // ---------------------------------------------------------
   // ✅ Accessor: baseline value (price)
   // Used for R1 distance rule and entry logic
   // ---------------------------------------------------------
   double Base() const
   {
      return m_state.Base;
   }


   // ---------------------------------------------------------
   // Update baseline
   // ---------------------------------------------------------
   bool Update(const string symbol,
               const ENUM_TIMEFRAMES tf,
               const enum_Baseline type,
               const int period,
               const int shift,
               const ENUM_MA_METHOD method,
               const ENUM_APPLIED_PRICE price,
               const int atrPeriod,
               const double atrMultiplier)
   {
      m_state.Reset();

      bool useBands = (atrMultiplier > 0.0);

      // Recreate baseline handle if config changed
      if(m_baseHandle == INVALID_HANDLE ||
            m_symbol != symbol || m_tf != tf || m_type != type ||
            m_period != period || m_shift != shift ||
            m_method != method || m_price != price)
         {
         ResetInternal();

         if(type == MA)
            m_baseHandle = iMA(symbol, tf, period, shift, method, price);
         else if(type == SWMA)
            m_baseHandle = iCustom(symbol, tf, SWMA_FILENAME, period, price);

         if(m_baseHandle == INVALID_HANDLE)
            {
            PrintFormat("[CBaseline] Failed to create baseline handle. err=%d",
                        GetLastError());
            return false;
            }

         m_symbol = symbol;
         m_tf     = tf;
         m_type   = type;
         m_period = period;
         m_shift  = shift;
         m_method = method;
         m_price  = price;
         }

      // ATR handle only if bands enabled
      if(useBands &&
            (m_atrHandle == INVALID_HANDLE ||
             m_atrPeriod != atrPeriod ||
             m_symbol != symbol || m_tf != tf))
         {
         if(m_atrHandle != INVALID_HANDLE)
            IndicatorRelease(m_atrHandle);

         m_atrHandle = iATR(symbol, tf, atrPeriod);
         if(m_atrHandle == INVALID_HANDLE)
            {
            PrintFormat("[CBaseline] Failed to create ATR handle. err=%d",
                        GetLastError());
            return false;
            }

         m_atrPeriod = atrPeriod;
         }

      // Copy baseline
      ArrayResize(m_baseBuf, m_buffer_size);
      if(CopyBuffer(m_baseHandle, 0, 0, m_buffer_size, m_baseBuf) < m_buffer_size)
         return false;

      // Copy ATR if needed
      if(useBands)
         {
         ArrayResize(m_atrBuf, m_buffer_size);
         if(CopyBuffer(m_atrHandle, 0, 0, m_buffer_size, m_atrBuf) < m_buffer_size)
            return false;
         }

      double close1 = iClose(symbol, tf, BAR_SIGNAL);
      double base1  = m_baseBuf[BAR_SIGNAL];
      if(base1 == EMPTY_VALUE || close1 == 0.0)
         return false;

      m_state.Base = base1;
      m_state.Time = iTime(symbol, tf, BAR_SIGNAL);

      double upper = base1;
      double lower = base1;

      if(useBands)
         {
         double atr = m_atrBuf[BAR_SIGNAL];
         upper = base1 + atr * atrMultiplier;
         lower = base1 - atr * atrMultiplier;
         m_state.Upper = upper;
         m_state.Lower = lower;
         }

      // Trend logic
      if(useBands)
         {
         // version 1 trend logic
         if(close1 > upper)      m_state.result.trend = TrendUp; // close price > upper limit
         else if(close1 < lower) m_state.result.trend = TrendDown;
         else                    m_state.result.trend = TrendNone;


         }
      else
         {
         if(close1 > base1)      m_state.result.trend = TrendUp;
         else if(close1 < base1) m_state.result.trend = TrendDown;
         else                    m_state.result.trend = TrendNone;
         }

      m_state.IsValid = true;
      return true;
   }
};

#endif // __LIBCBASELINE_MQH__
//+------------------------------------------------------------------+
