//+------------------------------------------------------------------+
//|                                           libCConfirmation.mqh   |
//|                     Confirmation Framework (Baseline-style)      |
//|                 Dual Confirmation + Volume HARD GATE (Option A)  |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
//  - Dual confirmation (Primary + Secondary)
//  - Volume hard gate (Option A)
//  - ✅ Explicit Reset() for lifecycle safety
//|                                 Cleaned / Stable Version        |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBCCONFIRMATION_MQH__
#define __LIBCCONFIRMATION_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>

// ------------------------------------------------------------------
// Parameter bundles
// ------------------------------------------------------------------
struct PSARParams
{
   double step;
   double max;
};

struct RVIParams
{
   int period;
};

struct KuskusParams
{
   int    rPeriod;
   double pSmooth;
   double iSmooth;
};

// ------------------------------------------------------------------
// Helper
// ------------------------------------------------------------------
inline int ClampScore(int v)
{
   if(v < 0)   return 0;
   if(v > 100) return 100;
   return v;
}

// ------------------------------------------------------------------
// Indicator handle library (shared by Confirmation & Exit)
// ------------------------------------------------------------------
class CConfirmationLibrary
{
protected:
   int m_psarHandle;
   int m_rviHandle;

   double m_psarBuf[];
   double m_rviMain[];
   double m_rviSignal[];

public:
   CConfirmationLibrary()
   {
      m_psarHandle = INVALID_HANDLE;
      m_rviHandle  = INVALID_HANDLE;
   }

   virtual ~CConfirmationLibrary()
   {
      Reset();
   }

   // ✅ lifecycle safety
   void Reset()
   {
      if(m_psarHandle != INVALID_HANDLE)
         IndicatorRelease(m_psarHandle);
      if(m_rviHandle != INVALID_HANDLE)
         IndicatorRelease(m_rviHandle);

      m_psarHandle = INVALID_HANDLE;
      m_rviHandle  = INVALID_HANDLE;

      ArrayFree(m_psarBuf);
      ArrayFree(m_rviMain);
      ArrayFree(m_rviSignal);
   }

protected:
   // ---------------------------------------------------------------
   bool RefreshPSAR(const string symbol,
                    ENUM_TIMEFRAMES tf,
                    int bufferSize,
                    double step,
                    double max)
   {
      bufferSize = EnsureForPrevious(bufferSize);

      if(m_psarHandle == INVALID_HANDLE)
      {
         m_psarHandle = iSAR(symbol, tf, step, max);
         if(m_psarHandle == INVALID_HANDLE)
            return false;
      }

      ArrayResize(m_psarBuf, bufferSize);
      ArraySetAsSeries(m_psarBuf, true);

      return (CopyBuffer(m_psarHandle, 0, 0, bufferSize, m_psarBuf) >= bufferSize);
   }

   bool RefreshRVI(const string symbol,
                   ENUM_TIMEFRAMES tf,
                   int bufferSize,
                   int period)
   {
      bufferSize = EnsureForPrevious(bufferSize);

      if(m_rviHandle == INVALID_HANDLE)
      {
         m_rviHandle = iRVI(symbol, tf, period);
         if(m_rviHandle == INVALID_HANDLE)
            return false;
      }

      ArrayResize(m_rviMain, bufferSize);
      ArrayResize(m_rviSignal, bufferSize);
      ArraySetAsSeries(m_rviMain, true);
      ArraySetAsSeries(m_rviSignal, true);

      if(CopyBuffer(m_rviHandle, 0, 0, bufferSize, m_rviMain) < bufferSize)
         return false;
      if(CopyBuffer(m_rviHandle, 1, 0, bufferSize, m_rviSignal) < bufferSize)
         return false;

      return true;
   }
};

// ------------------------------------------------------------------
// CConfirmation – Dual Confirmation Engine
// ------------------------------------------------------------------
class CConfirmation : public CConfirmationLibrary
{
private:
   int m_bufferSize;
   ConfirmationResult m_result;

   void ResetResult()
   {
      m_result.Signal         = NoTrade;
      m_result.Trend          = NoTrade;
      m_result.IsValid        = false;
      m_result.Time           = 0;
      m_result.PrimarySource  = CONF_NONE;
      m_result.SecondarySource= CONF_NONE;
      m_result.Score          = 0;
   }

public:
   CConfirmation()
   {
      m_bufferSize = EnsureForPrevious(3);
      ResetResult();
   }

   ~CConfirmation()
   {
      Reset();
   }

   void SetBufferSize(int n)
   {
      m_bufferSize = EnsureForPrevious(n);
   }

   ConfirmationResult Result() const
   {
      return m_result;
   }

   // ---------------------------------------------------------------
   // Dual confirmation update (PSAR / RVI)
   // ---------------------------------------------------------------
   bool UpdateDual(const string symbol,
                   ENUM_TIMEFRAMES tf,
                   enum_Confirmation primary,
                   enum_Confirmation secondary,
                   const PSARParams &ps,
                   const RVIParams  &rv,
                   const KuskusParams & /*unused*/)
   {
      ResetResult();

      int buf = m_bufferSize;

      enum_position pSignal = NoTrade, pTrend = NoTrade;
      enum_position sSignal = NoTrade, sTrend = NoTrade;

      // --- Primary
      if(primary == PSAR)
      {
         if(!RefreshPSAR(symbol, tf, buf, ps.step, ps.max))
            return false;

         double close1 = iClose(symbol, tf, BAR_SIGNAL);
         double ps1    = m_psarBuf[BAR_SIGNAL];
         pSignal = (ps1 < close1 ? Long : Short);
         pTrend  = pSignal;
      }
      if(primary == RVI)
      {
         if(!RefreshRVI(symbol, tf, buf, rv.period))
            return false;

         if(m_rviMain[BAR_SIGNAL] > m_rviSignal[BAR_SIGNAL])
            pSignal = pTrend = Long;
         else
            pSignal = pTrend = Short;
      }

      // --- Secondary (same logic)
      if(secondary == PSAR)
      {
         if(!RefreshPSAR(symbol, tf, buf, ps.step, ps.max))
            return false;

         double close1 = iClose(symbol, tf, BAR_SIGNAL);
         double ps1    = m_psarBuf[BAR_SIGNAL];
         sSignal = (ps1 < close1 ? Long : Short);
         sTrend  = sSignal;
      }
      if(secondary == RVI)
      {
         if(!RefreshRVI(symbol, tf, buf, rv.period))
            return false;

         if(m_rviMain[BAR_SIGNAL] > m_rviSignal[BAR_SIGNAL])
            sSignal = sTrend = Long;
         else
            sSignal = sTrend = Short;
      }

      // --- Merge
      m_result.Signal = (pSignal == sSignal ? pSignal : NoTrade);
      m_result.Trend  = (pTrend  == sTrend  ? pTrend  : NoTrade);

      int score = 0;
      if(pSignal == pTrend && pSignal != NoTrade) score += 40;
      if(sSignal == sTrend && sSignal != NoTrade) score += 30;
      if(pSignal == sSignal && pSignal != NoTrade) score += 30;

      m_result.Score   = ClampScore(score);
      m_result.IsValid = true;
      m_result.Time    = iTime(symbol, tf, BAR_SIGNAL);

      return true;
   }

   // ---------------------------------------------------------------
   // Volume Gate (Option A)
   // ---------------------------------------------------------------
   void ApplyVolumeGate(const VolumeResult &vol)
   {
      if(!m_result.IsValid || !vol.IsValid)
         return;

      if(vol.State == VOL_STATE_OFF)
      {
         m_result.Signal = NoTrade;
         m_result.Trend  = NoTrade;
         m_result.Score  = 0;
      }
      else
      {
         m_result.Score = ClampScore(m_result.Score + 15);
      }
   }
};

#endif // __LIBCCONFIRMATION_MQH__
