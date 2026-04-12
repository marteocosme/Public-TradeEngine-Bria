//+------------------------------------------------------------------+
//|                                             libCVolume.mqh       |
//|                         Volume Signal Framework (Baseline-style) |
//|                         TTMS: Squeeze ON/OFF (Option A Gate)     |
//|                               Marteo Cosme (2026)  04/03/2026    |
//+------------------------------------------------------------------+
//  - Baseline-style Update() -> Result()
//  - ✅ Explicit Reset() for lifecycle safety
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBCVOLUME_MQH__
#define __LIBCVOLUME_MQH__

#include <Arrays\ArrayObj.mqh>
#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>

// Paths
#define PATH_TOOLBOX "\\Indicators\\Toolbox\\"
#define TTMS_FILENAME (PATH_TOOLBOX + "TTMS_2.0.ex5")

// ------------------------------------------------------------
// TTMS Parameter Bundle
// ------------------------------------------------------------
struct TTMSParams
{
   int              bbPeriod;
   double           bbDev;
   int              kPeriod;
   ENUM_MA_METHOD   kMethod;
   double           kDev;
};

// ------------------------------------------------------------
// Indicator State Container
// ------------------------------------------------------------
class IndicatorState : public CObject
{
public:
   int              handle;
   string           symbol;
   ENUM_TIMEFRAMES  timeframe;
   uint             bufferSize;
   bool             isReady;
   double           buffer[];
   TTMSParams       ttms;

   IndicatorState()
   {
      handle     = INVALID_HANDLE;
      symbol     = "";
      timeframe  = PERIOD_CURRENT;
      bufferSize = 0;
      isReady    = false;
      ArraySetAsSeries(buffer, true);
   }

   virtual ~IndicatorState()
   {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
   }
};

// ------------------------------------------------------------
// Volume Signal Engine
// ------------------------------------------------------------
class CVolumeSignal
{
private:
   CArrayObj   m_states;
   VolumeResult m_result;
   int         m_buffer_size;

// ------------------------------------------------------------
private:

   void ResetInternal()
   {
      // Free all IndicatorState objects (their destructors release handles)
      m_states.Clear();

      // Reset result
      m_result.Reset();
   }

// ------------------------------------------------------------
// Public API
// ------------------------------------------------------------
public:

   CVolumeSignal()
   {
      m_buffer_size = EnsureForPrevious(3);
      Reset(); // ✅ initialize clean state
   }

   ~CVolumeSignal()
   {
      Reset(); // ✅ enforce cleanup
   }

   // ---------------------------------------------------------
   // ✅ Explicit lifecycle reset (IMPORTANT)
   // ---------------------------------------------------------
   void Reset()
   {
      ResetInternal();

      // Recreate indicator slots
      // (currently only TTMS = 1, but future-proof)
      for(int i = 0; i < 1; i++)
         m_states.Add(new IndicatorState);
   }

   void SetBufferSize(int n)
   {
      m_buffer_size = EnsureForPrevious(n);
   }

   VolumeResult Result() const
   {
      return m_result;
   }

   bool GatePassed() const
   {
      return (m_result.IsValid && m_result.State == VOL_STATE_ON);
   }

   // ---------------------------------------------------------
   // Update TTMS (Option A Gate)
   // ---------------------------------------------------------
   bool UpdateTTMS(const string symbol,
                   const ENUM_TIMEFRAMES tf,
                   const TTMSParams &params)
   {
      m_result.Reset();

      IndicatorState *st =
         (IndicatorState*)m_states.At(0); // TTMS index

      if(st == NULL)
         return false;

      // Recreate indicator if config changed
      if(!st.isReady ||
         st.symbol    != symbol ||
         st.timeframe != tf ||
         st.bufferSize != (uint)m_buffer_size ||
         st.ttms.bbPeriod != params.bbPeriod ||
         st.ttms.bbDev    != params.bbDev ||
         st.ttms.kPeriod  != params.kPeriod ||
         st.ttms.kMethod  != params.kMethod ||
         st.ttms.kDev     != params.kDev)
      {
         if(st.handle != INVALID_HANDLE)
            IndicatorRelease(st.handle);

         st.handle = iCustom(symbol, tf, TTMS_FILENAME,
                              params.bbPeriod,
                              params.bbDev,
                              params.kPeriod,
                              params.kMethod,
                              params.kDev);

         if(st.handle == INVALID_HANDLE)
            return false;

         st.symbol     = symbol;
         st.timeframe  = tf;
         st.bufferSize = m_buffer_size;
         st.ttms       = params;
         st.isReady    = true;

         ArrayResize(st.buffer, m_buffer_size);
         ArraySetAsSeries(st.buffer, true);
      }

      // Copy buffer
      if(CopyBuffer(st.handle, 0, 0, m_buffer_size, st.buffer) < m_buffer_size)
         return false;

      double value = st.buffer[BAR_SIGNAL];
      if(value == EMPTY_VALUE)
         return false;

      m_result.State   = (value > 0.0 ? VOL_STATE_ON : VOL_STATE_OFF);
      m_result.IsValid = true;
      m_result.Time    = iTime(symbol, tf, BAR_SIGNAL);
      m_result.Source  = VOL_TTMS;

      return true;
   }
};

#endif // __LIBCVOLUME_MQH__
