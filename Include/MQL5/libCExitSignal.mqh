

//+------------------------------------------------------------------+
//|                                           libCExitSignal.mqh     |
//|                     Exit Signal Framework (Baseline-style)       |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                         libCExitSignal.mqh       |
//|                 Exit Signal Engine (PSAR / RVI, NNFX‑style)     |
//|                                                     Marteo Cosme |
//|                                 Cleaned / Stable Version        |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBCEXITSIGNAL_MQH__
#define __LIBCEXITSIGNAL_MQH__

#include <MyInclude\NNFX\libEnum.mqh>
#include <MyInclude\NNFX\libCBarIndex.mqh>
#include <MyInclude\NNFX\libCConfirmation.mqh>

// ------------------------------------------------------------------
// Exit parameter bundles
// ------------------------------------------------------------------
struct ExitPSARParams
{
   double step;
   double max;
};

struct ExitRVIParams
{
   int period;
};
enum enum_exitMode
{
   EXIT_MODE_STATE = 0, //STATE (faster exits, more whipsaws), or
   EXIT_MODE_CROSS = 1  //CROSS (slower exits, less noise)
};
// ------------------------------------------------------------------
// Exit Signal Engine
// ------------------------------------------------------------------
class CExitSignal : public CConfirmationLibrary
{
private:
   int             m_bufferSize;
   enum_position   m_lastSignal;

public:
   CExitSignal()
   {
      m_bufferSize = EnsureForPrevious(3);
      m_lastSignal = NoTrade;
   }

   ~CExitSignal()
   {
      Reset();
   }

   void SetBufferSize(int n)
   {
      m_bufferSize = EnsureForPrevious(n);
   }

   // ---------------------------------------------------------------
   // Update exit condition
   //
   // Returns TRUE if position should be exited
   // ---------------------------------------------------------------
   bool Update(const string symbol,
               ENUM_TIMEFRAMES tf,
               enum_position positionDir,
               enum_Confirmation exitIndicator,
               const ExitPSARParams &ps,
               const ExitRVIParams  &rv,
               enum_exitMode mode)
   {
      if(positionDir == NoTrade)
         return false;

      enum_position currentSignal = NoTrade;
      int buf = m_bufferSize;

      // ============================================================
      // EXIT VIA PSAR
      // ============================================================
      if(exitIndicator == PSAR)
      {
         if(!RefreshPSAR(symbol, tf, buf, ps.step, ps.max))
            return false;

         double close1 = iClose(symbol, tf, BAR_SIGNAL);
         double psar1  = m_psarBuf[BAR_SIGNAL];

         currentSignal = (psar1 < close1 ? Long : Short);
      }

      // ============================================================
      // EXIT VIA RVI
      // ============================================================
      if(exitIndicator == RVI)
      {
         if(!RefreshRVI(symbol, tf, buf, rv.period))
            return false;

         if(m_rviMain[BAR_SIGNAL] > m_rviSignal[BAR_SIGNAL])
            currentSignal = Long;
         else
            currentSignal = Short;
      }

      // ============================================================
      // Handle disable / invalid
      // ============================================================
      if(currentSignal == NoTrade)
         return false;

      // ============================================================
      // EXIT MODE: STATE
      // Exit when indicator shows opposite state
      // ============================================================
      if(mode == EXIT_MODE_STATE)
      {
         return (currentSignal != positionDir);
      }

      // ============================================================
      // EXIT MODE: CROSS
      // Exit only on fresh reversal
      // ============================================================
      if(mode == EXIT_MODE_CROSS)
      {
         bool trigger =
            (currentSignal != positionDir &&
             m_lastSignal == positionDir);

         m_lastSignal = currentSignal;
         return trigger;
      }

      return false;
   }
};

#endif // __LIBCEXITSIGNAL_MQH__


/*
✅ How to Use in libCTradeEngine.mqh (Example)
CExitSignal exitSignal;

// Build params from inputs
ExitPSARParams ps; ps.step = inpPSAR_Steps; ps.max = inpPSAR_Max;
ExitRVIParams  rv; rv.period = (int)inpRVI_Period;

// Determine current position direction (example)
enum_position posDir = Long; // or Short

exitSignal.Update(_Symbol,
                  inpTradeExecutionPeriod,
                  posDir,
                  inpExitIndicator,   // enum_Confirmation
                  ps,
                  rv,
                  EXIT_MODE_STATE);   // or EXIT_MODE_CROSS

ExitResult er = exitSignal.Result();
if(er.ShouldExit)
{
   // Close position here (TradeHndlr.PositionClose, etc.)
}



✅ How to call it (no need to pass mode anymore)
ExitPSARParams ps; ps.step = inpPSAR_Steps; ps.max = inpPSAR_Max;
ExitRVIParams  rv; rv.period = (int)inpRVI_Period;

exitSignal.Update(_Symbol,
                  inpTradeExecutionPeriod,
                  posDir,
                  inpExitIndicator,
                  ps,
                  rv);  // ✅ CROSS default
``



Apps

Cosme, Marteo

Refactor MQH files

Think Deeper




You said:
Option A and general final updated libCVolume.mqh + revised libCConfirmation.mqh as complete copy/paste files
Copilot said:
Copilot

Reasoning completed in 3 steps
Absolutely — here are the final, copy/paste-ready versions of:

✅ libCVolume.mqh (TTMS = Squeeze ON/OFF, Option A hard gate)
✅ libCConfirmation.mqh (revised to merge Volume gate into Confirmation result, and still supports dual confirmation)
Important: These files assume your libEnum.mqh has already been updated so that:

VolumeResult has State (not Bias)
enum_volumeState has VOL_STATE_ON / VOL_STATE_OFF
If not yet, tell me and I’ll generate the updated libEnum.mqh patch section again.
✅ 1) libCVolume.mqh (FINAL — TTMS Squeeze ON/OFF, Baseline-style)



C++
//+------------------------------------------------------------------+
//|                                             libCVolume.mqh       |
//|                         Volume Signal Framework (Baseline-style) |
//|                         TTMS: Squeeze ON/OFF (Option A Gate)     |
//|                                         Marteo Cosme (2026)      |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCVOLUME_MQH__
#define __LIBCVOLUME_MQH__

#include <Arrays\ArrayObj.mqh>
#include <MyInclude\libEnum.mqh>
#include <MyInclude\libCBarIndex.mqh>

// Paths
#define PATH_TOOLBOX "\\Indicators\\Toolbox\\"
#define TTMS_FILENAME (PATH_TOOLBOX + "TTMS_2.0.ex5")

//------------------------------------------------------------------
// Supported Volume Indicators
//------------------------------------------------------------------
enum ENUM_VOLUME_INDICATOR
{
   VOL_TTMS = 0
};

#define TOTAL_VOLUME_INDICATORS 1

//------------------------------------------------------------------
// TTMS Params (match your TradeEngine inputs)
//------------------------------------------------------------------
struct TTMSParams
{
   int            bbPeriod;
   double         bbDev;
   int            kPeriod;
   ENUM_MA_METHOD kMethod;
   double         kDev;
};

//------------------------------------------------------------------
// Indicator state container
//------------------------------------------------------------------
class IndicatorState : public CObject
{
public:
   int             handle;
   string          symbol;
   ENUM_TIMEFRAMES timeframe;
   uint            bufferSize;
   double          buffer[];
   bool            isReady;

   // Extra: keep params for iCustom recreation (TTMS-specific)
   TTMSParams      ttms;

   IndicatorState()
   {
      handle     = INVALID_HANDLE;
      symbol     = "";
      timeframe  = PERIOD_CURRENT;
      bufferSize = 0;
      isReady    = false;

      // Default params (safe)
      ttms.bbPeriod = 20;
      ttms.bbDev    = 2.0;
      ttms.kPeriod  = 20;
      ttms.kMethod  = MODE_SMA;
      ttms.kDev     = 2.0;

      ArraySetAsSeries(buffer, true);
   }

   ~IndicatorState()
   {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
   }
};

//------------------------------------------------------------------
// Volume Signal Engine (Baseline-style)
// Produces VolumeResult (State ON/OFF) using BAR_SIGNAL
//------------------------------------------------------------------
class CVolumeSignal
{
private:
   CArrayObj    m_states;
   VolumeResult m_result;
   int          m_buffer_size;

public:
   CVolumeSignal()
   {
      m_states.Clear();

      for(int i = 0; i < TOTAL_VOLUME_INDICATORS; i++)
         m_states.Add(new IndicatorState);

      m_buffer_size = EnsureForPrevious(3);
      Reset();
   }

   ~CVolumeSignal()
   {
      m_states.Clear(); // destroys IndicatorState objects
   }

   void Reset()
   {
      m_result.Reset();
   }

   void SetBufferSize(int n)
   {
      m_buffer_size = EnsureForPrevious(n);
   }

   VolumeResult Result() const
   {
      return m_result;
   }

   // Option A Gate helper: trade only when squeeze is ON
   bool GatePassed() const
   {
      return (m_result.IsValid && m_result.State == VOL_STATE_ON);
   }

private:
   // ---------------------------------------------------------
   bool SameTTMSParams(const TTMSParams &a, const TTMSParams &b)
   {
      return (a.bbPeriod == b.bbPeriod &&
              a.bbDev    == b.bbDev &&
              a.kPeriod  == b.kPeriod &&
              a.kMethod  == b.kMethod &&
              a.kDev     == b.kDev);
   }

   bool NeedsRefreshTTMS(IndicatorState &st,
                         string symbol,
                         ENUM_TIMEFRAMES tf,
                         uint buffer_size,
                         const TTMSParams &params)
   {
      if(st.handle == INVALID_HANDLE) return true;
      if(st.symbol != symbol) return true;
      if(st.timeframe != tf) return true;
      if(st.bufferSize != buffer_size) return true;
      if(!SameTTMSParams(st.ttms, params)) return true;
      return false;
   }

   bool InitTTMS(IndicatorState &st,
                 string symbol,
                 ENUM_TIMEFRAMES tf,
                 uint buffer_size,
                 const TTMSParams &params)
   {
      if(st.handle != INVALID_HANDLE)
      {
         IndicatorRelease(st.handle);
         st.handle = INVALID_HANDLE;
      }

      // iCustom params must match your TTMS indicator signature.
      // Based on your inputs: BB period/dev, Keltner period/method/dev
      st.handle = iCustom(symbol, tf, TTMS_FILENAME,
                          params.bbPeriod,
                          params.bbDev,
                          params.kPeriod,
                          params.kMethod,
                          params.kDev);

      if(st.handle == INVALID_HANDLE)
      {
         PrintFormat("[CVolumeSignal] TTMS iCustom failed. err=%d file=%s", GetLastError(), TTMS_FILENAME);
         return false;
      }

      st.symbol     = symbol;
      st.timeframe  = tf;
      st.bufferSize = buffer_size;
      st.isReady    = true;
      st.ttms       = params;

      ArrayResize(st.buffer, buffer_size);
      ArraySetAsSeries(st.buffer, true);

      return true;
   }

   bool RefreshTTMS(IndicatorState &st, uint buffer_size)
   {
      int copied = CopyBuffer(st.handle, 0, 0, (int)buffer_size, st.buffer);
      if(copied >= (int)buffer_size) return true;

      // retry once (history sync)
      ResetLastError();
      Sleep(20);
      copied = CopyBuffer(st.handle, 0, 0, (int)buffer_size, st.buffer);
      return (copied >= (int)buffer_size);
   }

   double Value(IndicatorState &st, uint bar)
   {
      if(!st.isReady) return EMPTY_VALUE;
      if(bar >= st.bufferSize) return EMPTY_VALUE;
      return st.buffer[bar];
   }

public:
   // ---------------------------------------------------------
   // UpdateTTMS (Baseline-style):
   // TTMS returns positive/negative values:
   //   > 0  => Squeeze ON (good volume / energy present)
   //   <= 0 => Squeeze OFF (no volume)
   // Option A: This will be used as HARD GATE in TradeContext.
   // ---------------------------------------------------------
   bool UpdateTTMS(string symbol,
                   ENUM_TIMEFRAMES tf,
                   const TTMSParams &params)
   {
      Reset();

      int buf = EnsureForPrevious(m_buffer_size);

      IndicatorState *st = (IndicatorState*)m_states.At(VOL_TTMS);
      if(st == NULL)
      {
         Print("[CVolumeSignal] Internal error: TTMS state is NULL");
         return false;
      }

      if(NeedsRefreshTTMS(*st, symbol, tf, (uint)buf, params))
      {
         if(!InitTTMS(*st, symbol, tf, (uint)buf, params))
            return false;
      }

      if(!RefreshTTMS(*st, (uint)buf))
      {
         PrintFormat("[CVolumeSignal] TTMS CopyBuffer failed. err=%d", GetLastError());
         return false;
      }

      double v1 = Value(*st, BAR_SIGNAL);
      if(v1 == EMPTY_VALUE)
         return false;

      // Your definition:
      // Positive => Squeeze ON (good volume)
      // Otherwise => Squeeze OFF (no volume)
      m_result.State  = (v1 > 0.0 ? VOL_STATE_ON : VOL_STATE_OFF);
      m_result.IsValid = true;
      m_result.Time    = iTime(symbol, tf, BAR_SIGNAL);
      m_result.Source  = VOL_TTMS;

      return true;
   }
};

#endif // __LIBCVOLUME_MQH__

Show more lines
✅ 2) libCConfirmation.mqh (FINAL — Dual confirmation + Volume HARD GATE)
This version does two things:

✅ Computes Primary + Secondary confirmation (PSAR/RVI) and stores in ConfirmationResult
✅ Applies Option A hard gate:

If Volume.State == OFF → Signal = NoTrade, Trend = NoTrade, Score = 0, and IsValid stays true (so you can still log/debug it)
Why keep IsValid = true even when gated?
Because the data is valid — it’s just not tradeable due to volume gate.
Your TradeContext.IsTradeable should handle gating explicitly.




C++
//+------------------------------------------------------------------+
//|                                           libCConfirmation.mqh   |
//|                     Confirmation Framework (Baseline-style)      |
//|                 Dual Confirmation + Volume HARD GATE (Option A)  |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCCONFIRMATION_MQH__
#define __LIBCCONFIRMATION_MQH__

#include <MyInclude\libEnum.mqh>
#include <MyInclude\libCBarIndex.mqh>

// Paths (adjust as needed)
#define PATH_BACKTESTING "\\Indicators\\Toolbox\\Backtesting\\"
#define KUSKUS_FILENAME (PATH_BACKTESTING + "Kuskus Starlight - revised.ex5")

// ------------------------------------------------------------------
// Param bundles
// ------------------------------------------------------------------
struct PSARParams { double step; double max; };
struct RVIParams  { int period; };

// Optional future use
struct KuskusParams { int rPeriod; double pSmooth; double iSmooth; };

// ------------------------------------------------------------------
int ClampScore(int v)
{
   if(v < 0)   return 0;
   if(v > 100) return 100;
   return v;
}

//+------------------------------------------------------------------+
//| CConfirmationLibrary - handles, buffers, refresh                  |
//+------------------------------------------------------------------+
class CConfirmationLibrary
{
private:
   int m_psarHandle;
   int m_rviHandle;
   int m_kuskusHandle;

   double m_bufPSAR[];
   double m_bufRVI_Main[];
   double m_bufRVI_Signal[];
   double m_bufKus_Up[];
   double m_bufKus_Dn[];

   struct PsarKey { string sym; ENUM_TIMEFRAMES tf; double step; double max; };
   struct RviKey  { string sym; ENUM_TIMEFRAMES tf; int period; };
   struct KusKey  { string sym; ENUM_TIMEFRAMES tf; int r; double p; double i; };

   PsarKey m_psarKey;
   RviKey  m_rviKey;
   KusKey  m_kusKey;

private:
   bool SamePsarKey(string s, ENUM_TIMEFRAMES tf, double step, double mx)
   {
      return (m_psarKey.sym == s && m_psarKey.tf == tf && m_psarKey.step == step && m_psarKey.max == mx);
   }
   bool SameRviKey(string s, ENUM_TIMEFRAMES tf, int period)
   {
      return (m_rviKey.sym == s && m_rviKey.tf == tf && m_rviKey.period == period);
   }
   bool SameKusKey(string s, ENUM_TIMEFRAMES tf, int r, double p, double i)
   {
      return (m_kusKey.sym == s && m_kusKey.tf == tf && m_kusKey.r == r && m_kusKey.p == p && m_kusKey.i == i);
   }

   double SafeAt(const double &arr[], uint idx)
   {
      int n = ArraySize(arr);
      if(n <= 0 || (int)idx >= n) return EMPTY_VALUE;
      return arr[idx];
   }

   bool CopyOrRetry(const int handle, const int bufIdx, const int count, double &dest[])
   {
      int copied = CopyBuffer(handle, bufIdx, 0, count, dest);
      if(copied >= count) return true;

      ResetLastError();
      Sleep(20);
      copied = CopyBuffer(handle, bufIdx, 0, count, dest);
      return (copied >= count);
   }

public:
   CConfirmationLibrary()
   {
      m_psarHandle   = INVALID_HANDLE;
      m_rviHandle    = INVALID_HANDLE;
      m_kuskusHandle = INVALID_HANDLE;

      ArraySetAsSeries(m_bufPSAR, true);
      ArraySetAsSeries(m_bufRVI_Main, true);
      ArraySetAsSeries(m_bufRVI_Signal, true);
      ArraySetAsSeries(m_bufKus_Up, true);
      ArraySetAsSeries(m_bufKus_Dn, true);

      m_psarKey.sym=""; m_psarKey.tf=(ENUM_TIMEFRAMES)0; m_psarKey.step=0.0; m_psarKey.max=0.0;
      m_rviKey.sym="";  m_rviKey.tf=(ENUM_TIMEFRAMES)0;  m_rviKey.period=0;
      m_kusKey.sym="";  m_kusKey.tf=(ENUM_TIMEFRAMES)0;  m_kusKey.r=0; m_kusKey.p=0.0; m_kusKey.i=0.0;
   }

   ~CConfirmationLibrary()
   {
      if(m_psarHandle   != INVALID_HANDLE) IndicatorRelease(m_psarHandle);
      if(m_rviHandle    != INVALID_HANDLE) IndicatorRelease(m_rviHandle);
      if(m_kuskusHandle != INVALID_HANDLE) IndicatorRelease(m_kuskusHandle);
   }

   // ---- PSAR ----
   bool RefreshPSAR(string symbol, ENUM_TIMEFRAMES tf, int buffer_size, double stepVal, double maxVal)
   {
      buffer_size = EnsureForPrevious(buffer_size);

      if(!SamePsarKey(symbol, tf, stepVal, maxVal) && m_psarHandle != INVALID_HANDLE)
      {
         IndicatorRelease(m_psarHandle);
         m_psarHandle = INVALID_HANDLE;
      }

      if(m_psarHandle == INVALID_HANDLE)
      {
         m_psarHandle = iSAR(symbol, tf, stepVal, maxVal);
         if(m_psarHandle == INVALID_HANDLE)
         {
            PrintFormat("[CConfirmationLibrary] PSAR handle create failed err=%d", GetLastError());
            return false;
         }

         m_psarKey.sym  = symbol;
         m_psarKey.tf   = tf;
         m_psarKey.step = stepVal;
         m_psarKey.max  = maxVal;
      }

      ArrayResize(m_bufPSAR, buffer_size);
      if(!CopyOrRetry(m_psarHandle, 0, buffer_size, m_bufPSAR))
      {
         PrintFormat("[CConfirmationLibrary] PSAR CopyBuffer failed err=%d", GetLastError());
         return false;
      }
      return true;
   }

   double GetPSAR(uint bar) { return SafeAt(m_bufPSAR, bar); }

   // ---- RVI ----
   bool RefreshRVI(string symbol, ENUM_TIMEFRAMES tf, int buffer_size, int periodVal)
   {
      buffer_size = EnsureForPrevious(buffer_size);

      if(!SameRviKey(symbol, tf, periodVal) && m_rviHandle != INVALID_HANDLE)
      {
         IndicatorRelease(m_rviHandle);
         m_rviHandle = INVALID_HANDLE;
      }

      if(m_rviHandle == INVALID_HANDLE)
      {
         m_rviHandle = iRVI(symbol, tf, periodVal);
         if(m_rviHandle == INVALID_HANDLE)
         {
            PrintFormat("[CConfirmationLibrary] RVI handle create failed err=%d", GetLastError());
            return false;
         }

         m_rviKey.sym    = symbol;
         m_rviKey.tf     = tf;
         m_rviKey.period = periodVal;
      }

      ArrayResize(m_bufRVI_Main, buffer_size);
      ArrayResize(m_bufRVI_Signal, buffer_size);

      if(!CopyOrRetry(m_rviHandle, 0, buffer_size, m_bufRVI_Main))
      {
         PrintFormat("[CConfirmationLibrary] RVI main CopyBuffer failed err=%d", GetLastError());
         return false;
      }
      if(!CopyOrRetry(m_rviHandle, 1, buffer_size, m_bufRVI_Signal))
      {
         PrintFormat("[CConfirmationLibrary] RVI signal CopyBuffer failed err=%d", GetLastError());
         return false;
      }
      return true;
   }

   double GetRVI_Main(uint bar)   { return SafeAt(m_bufRVI_Main, bar); }
   double GetRVI_Signal(uint bar) { return SafeAt(m_bufRVI_Signal, bar); }

   // ---- KUSKUS (future / optional) ----
   bool RefreshKuskus(string symbol, ENUM_TIMEFRAMES tf, int buffer_size, int rPeriod, double pSmooth, double iSmooth)
   {
      buffer_size = EnsureForPrevious(buffer_size);

      if(!SameKusKey(symbol, tf, rPeriod, pSmooth, iSmooth) && m_kuskusHandle != INVALID_HANDLE)
      {
         IndicatorRelease(m_kuskusHandle);
         m_kuskusHandle = INVALID_HANDLE;
      }

      if(m_kuskusHandle == INVALID_HANDLE)
      {
         m_kuskusHandle = iCustom(symbol, tf, KUSKUS_FILENAME, rPeriod, pSmooth, iSmooth);
         if(m_kuskusHandle == INVALID_HANDLE)
         {
            PrintFormat("[CConfirmationLibrary] Kuskus handle create failed err=%d", GetLastError());
            return false;
         }

         m_kusKey.sym = symbol;
         m_kusKey.tf  = tf;
         m_kusKey.r   = rPeriod;
         m_kusKey.p   = pSmooth;
         m_kusKey.i   = iSmooth;
      }

      ArrayResize(m_bufKus_Up, buffer_size);
      ArrayResize(m_bufKus_Dn, buffer_size);

      if(!CopyOrRetry(m_kuskusHandle, 0, buffer_size, m_bufKus_Up)) return false;
      if(!CopyOrRetry(m_kuskusHandle, 1, buffer_size, m_bufKus_Dn)) return false;

      return true;
   }
};

//+------------------------------------------------------------------+
//| CConfirmation - Dual confirmation + Volume gate                   |
//+------------------------------------------------------------------+
class CConfirmation : public CConfirmationLibrary
{
private:
   int m_buffer_size;
   ConfirmationResult m_result;

   struct SingleEval
   {
      enum_position Signal;
      enum_position Trend;
      bool          IsValid;
      enum_confirmSource Source;
   };

private:
   void ResetResult()
   {
      m_result.Signal = NoTrade;
      m_result.Trend  = NoTrade;
      m_result.IsValid = false;
      m_result.Time = 0;
      m_result.PrimarySource = CONF_NONE;
      m_result.SecondarySource = CONF_NONE;
      m_result.Score = 0;
   }

   SingleEval EvaluateSingle(enum_Confirmation which,
                             string symbol,
                             ENUM_TIMEFRAMES tf,
                             int buffer_size,
                             const PSARParams &psar,
                             const RVIParams  &rvi,
                             const KuskusParams &kus)
   {
      SingleEval out;
      out.Signal = NoTrade;
      out.Trend  = NoTrade;
      out.IsValid = false;
      out.Source  = ConfirmToSource(which);

      if(which == confirmDisable) return out;

      // ---- RVI ----
      if(which == RVI)
      {
         if(!RefreshRVI(symbol, tf, buffer_size, rvi.period))
            return out;

         double r1 = GetRVI_Main(BAR_SIGNAL);
         double r2 = GetRVI_Main(BAR_PREVIOUS);
         double s1 = GetRVI_Signal(BAR_SIGNAL);
         double s2 = GetRVI_Signal(BAR_PREVIOUS);

         if(r1 > s1 && r2 <= s2) out.Signal = Long;
         else if(r1 < s1 && r2 >= s2) out.Signal = Short;

         if(r1 > s1) out.Trend = Long;
         else if(r1 < s1) out.Trend = Short;

         out.IsValid = true;
         return out;
      }

      // ---- PSAR ----
      if(which == PSAR)
      {
         if(!RefreshPSAR(symbol, tf, buffer_size, psar.step, psar.max))
            return out;

         double closes[];
         ArraySetAsSeries(closes, true);
         int need = BarsNeededForPrevious();
         if(CopyClose(symbol, tf, 0, need, closes) < need)
            return out;

         double ps1 = GetPSAR(BAR_SIGNAL);
         double ps2 = GetPSAR(BAR_PREVIOUS);

         bool prevAbove = (ps2 > closes[BAR_PREVIOUS]);
         bool lastAbove = (ps1 > closes[BAR_SIGNAL]);

         if(prevAbove && !lastAbove) out.Signal = Long;
         else if(!prevAbove && lastAbove) out.Signal = Short;

         if(ps1 > closes[BAR_SIGNAL]) out.Trend = Short;
         else if(ps1 < closes[BAR_SIGNAL]) out.Trend = Long;

         out.IsValid = true;
         return out;
      }

      // ---- KUSKUS (future) ----
      if(which == KUSKUS)
      {
         if(!RefreshKuskus(symbol, tf, buffer_size, kus.rPeriod, kus.pSmooth, kus.iSmooth))
            return out;

         // placeholder interpretation – adjust to your Kuskus buffers
         out.IsValid = true;
         return out;
      }

      return out;
   }

public:
   CConfirmation()
   {
      m_buffer_size = EnsureForPrevious(3);
      ResetResult();
   }

   void SetBufferSize(int n) { m_buffer_size = EnsureForPrevious(n); }
   ConfirmationResult Result() const { return m_result; }

   // ---------------------------------------------------------------
   // UpdateDual: compute primary + secondary confirmation + base score
   // ---------------------------------------------------------------
   bool UpdateDual(string symbol,
                   ENUM_TIMEFRAMES tf,
                   enum_Confirmation primary,
                   enum_Confirmation secondary,
                   const PSARParams &psar,
                   const RVIParams  &rvi,
                   const KuskusParams &kus)
   {
      ResetResult();

      int buf = EnsureForPrevious(m_buffer_size);

      // Both disabled => neutral but valid (no confirmation required)
      if(primary == confirmDisable && secondary == confirmDisable)
      {
         m_result.IsValid = true;
         m_result.Time = iTime(symbol, tf, BAR_SIGNAL);
         m_result.PrimarySource = CONF_NONE;
         m_result.SecondarySource = CONF_NONE;
         m_result.Signal = NoTrade;
         m_result.Trend  = NoTrade;
         m_result.Score  = 0;
         return true;
      }

      SingleEval p = EvaluateSingle(primary, symbol, tf, buf, psar, rvi, kus);
      SingleEval s = EvaluateSingle(secondary, symbol, tf, buf, psar, rvi, kus);

      if(!p.IsValid && !s.IsValid)
         return false;

      m_result.IsValid = true;
      m_result.Time = iTime(symbol, tf, BAR_SIGNAL);
      m_result.PrimarySource   = p.Source;
      m_result.SecondarySource = s.Source;

      // ---- Merge Trend
      enum_position mergedTrend = NoTrade;
      if(p.IsValid && !s.IsValid) mergedTrend = p.Trend;
      else if(!p.IsValid && s.IsValid) mergedTrend = s.Trend;
      else if(p.IsValid && s.IsValid)
      {
         mergedTrend = (p.Trend == s.Trend ? p.Trend : NoTrade);
      }

      // ---- Merge Signal
      enum_position mergedSignal = NoTrade;
      if(p.IsValid && !s.IsValid) mergedSignal = p.Signal;
      else if(!p.IsValid && s.IsValid) mergedSignal = s.Signal;
      else if(p.IsValid && s.IsValid)
      {
         mergedSignal = (p.Signal != NoTrade && p.Signal == s.Signal ? p.Signal : NoTrade);
      }

      // ---- Score
      int score = 0;

      if(p.IsValid && p.Signal != NoTrade && p.Signal == p.Trend) score += 40;
      if(s.IsValid && s.Signal != NoTrade && s.Signal == s.Trend) score += 30;

      if(p.IsValid && s.IsValid && p.Signal != NoTrade && p.Signal == s.Signal) score += 20;
      if(p.IsValid && s.IsValid && p.Trend  != NoTrade && p.Trend  == s.Trend)  score += 10;

      // conflict (both signaled opposite)
      if(p.IsValid && s.IsValid &&
         p.Signal != NoTrade && s.Signal != NoTrade &&
         p.Signal != s.Signal)
      {
         score -= 50;
         mergedSignal = NoTrade;
      }

      m_result.Signal = mergedSignal;
      m_result.Trend  = mergedTrend;
      m_result.Score  = ClampScore(score);

      return true;
   }

   // ---------------------------------------------------------------
   // ApplyVolumeGate (Option A):
   // If TTMS Squeeze is OFF => hard block:
   // - Signal = NoTrade
   // - Trend  = NoTrade
   // - Score  = 0
   // ---------------------------------------------------------------
   void ApplyVolumeGate(const VolumeResult &vol)
   {
      if(!m_result.IsValid) return;
      if(!vol.IsValid) return;

      if(vol.State == VOL_STATE_OFF)
      {
         m_result.Signal = NoTrade;
         m_result.Trend  = NoTrade;
         m_result.Score  = 0;
      }
      else
      {
         // Squeeze ON => give a small confidence boost (optional)
         // Keeps scoring meaningful without overpowering indicator logic.
         m_result.Score = ClampScore(m_result.Score + 15);
      }
   }

   // ---------------------------------------------------------------
   // Backward-compatible wrappers (so your old engine can still call)
   // ---------------------------------------------------------------
   enum_position signalRVI(string symbol, ENUM_TIMEFRAMES tf, int period)
   {
      RVIParams r; r.period = period;
      PSARParams p; p.step = 0.02; p.max = 0.2;
      KuskusParams k; k.rPeriod=0; k.pSmooth=0; k.iSmooth=0;

      SingleEval e = EvaluateSingle(RVI, symbol, tf, EnsureForPrevious(m_buffer_size), p, r, k);
      return (e.IsValid ? e.Signal : NoTrade);
   }

   enum_position trendRVI(string symbol, ENUM_TIMEFRAMES tf, int period)
   {
      RVIParams r; r.period = period;
      PSARParams p; p.step = 0.02; p.max = 0.2;
      KuskusParams k; k.rPeriod=0; k.pSmooth=0; k.iSmooth=0;

      SingleEval e = EvaluateSingle(RVI, symbol, tf, EnsureForPrevious(m_buffer_size), p, r, k);
      return (e.IsValid ? e.Trend : NoTrade);
   }

   enum_position signalPSAR(string symbol, ENUM_TIMEFRAMES tf, double step, double max)
   {
      PSARParams p; p.step = step; p.max = max;
      RVIParams r; r.period = 8;
      KuskusParams k; k.rPeriod=0; k.pSmooth=0; k.iSmooth=0;

      SingleEval e = EvaluateSingle(PSAR, symbol, tf, EnsureForPrevious(m_buffer_size), p, r, k);
      return (e.IsValid ? e.Signal : NoTrade);
   }

   enum_position trendPSAR(string symbol, ENUM_TIMEFRAMES tf, double step, double max)
   {
      PSARParams p; p.step = step; p.max = max;
      RVIParams r; r.period = 8;
      KuskusParams k; k.rPeriod=0; k.pSmooth=0; k.iSmooth=0;

      SingleEval e = EvaluateSingle(PSAR, symbol, tf, EnsureForPrevious(m_buffer_size), p, r, k);
      return (e.IsValid ? e.Trend : NoTrade);
   }
};

#endif // __LIBCCONFIRMATION_MQH__

Show more lines
✅ How to Use These (Recommended Wiring in Trade Engine)
Here’s the clean “Option A gate” sequence:




C++
// 1) Build TTMS params from inputs
TTMSParams tp;
tp.bbPeriod = (int)inpBBperiod;
tp.bbDev    = inpBBdeviation;
tp.kPeriod  = (int)inpKperiod;
tp.kMethod  = inpKmethod;
tp.kDev     = inpKdeviation;

// 2) Update volume first (gate)
volumeSignal.UpdateTTMS(_Symbol, inpTradeExecutionPeriod, tp);
VolumeResult vr = volumeSignal.Result();

// 3) If squeeze OFF => no trade early
if(!volumeSignal.GatePassed())
   return; // or set ctx.IsTradeable=false

// 4) Update confirmation
PSARParams ps; ps.step = inpPSAR_Steps; ps.max = inpPSAR_Max;
RVIParams  rv; rv.period = (int)inpRVI_Period;
KuskusParams ku; ku.rPeriod=0; ku.pSmooth=0; ku.iSmooth=0;

confirmSignal.UpdateDual(_Symbol, inpTradeExecutionPeriod,
                         inpConfirmPrimary, inpConfirmSecondary,
                         ps, rv, ku);

// 5) Apply volume gate/boost into confirmation result
confirmSignal.ApplyVolumeGate(vr);

ConfirmationResult cr = confirmSignal.Result();

Show more lines
This gives you:

Hard gate on TTMS OFF ✅
Score boost on TTMS ON ✅
Still keeps confirmation logic clean and reusable ✅
Quick sanity checklist before compiling
✅ libEnum.mqh must include:
enum_volumeState { VOL_STATE_OFF, VOL_STATE_ON }
struct VolumeResult { enum_volumeState State; ... }
✅ Remove any old references to VolumeResult.Bias or VOL_BULLISH/VOL_BEARISH
✅ Ensure TTMS_2.0.ex5 parameter signature matches the iCustom() call (bbPeriod, bbDev, kPeriod, kMethod, kDev)
If you want, next I can generate the final libCTradeContext.mqh + updated BuildTradeContext() that implements Option A gating and produces a single ctx.IsTradeable decision cleanly.








image.png
You said:
lets do libCATRSignal.mqh
Copilot said:
Copilot

Reasoning completed in 1 step
Absolutely — here is a final, MQL5-compatible libCATRSignal.mqh you can copy and paste.

✅ Baseline-style (Update() → stores into ATRResult, Result() accessor)
✅ Uses your shared standards:

libEnum.mqh (for ATRResult)
libCBarIndex.mqh (for BAR_SIGNAL, etc.) ✅ Efficient: one ATR handle cached & recreated only when needed
✅ Supports configurable buffer depth (defaults safe for BAR_SIGNAL/BAR_PREVIOUS)
✅ Includes helpful utilities: ATR_Points(), ATR_Pips() (optional but handy)
✅ libCATRSignal.mqh (Copy/Paste)



C++
//+------------------------------------------------------------------+
//|                                           libCATRSignal.mqh      |
//|                    ATR Signal Engine (Baseline-style)            |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCATRSIGNAL_MQH__
#define __LIBCATRSIGNAL_MQH__

#include <MyInclude\libEnum.mqh>
#include <MyInclude\libCBarIndex.mqh>

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
      if(m_handle != INVALID_HANDLE)
         IndicatorRelease(m_handle);
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
``

Show more lines
✅ How to Use It (Typical in your Trade Engine)
Example: store ATR in TradeContext



C++
CATRSignal atrSignal;
atrSignal.Update(_Symbol, inpTradeExecutionPeriod, (int)inpATRinterval, BAR_SIGNAL);

ATRResult ar = atrSignal.Result();
if(ar.IsValid)
{
   // ar.Value is ATR in price units
}
``
Example: ATR-based SL/TP sizing



C++
double atr = ar.Value;
double slPriceDistance = atr * inpSLxATRxPlier;
double tpPriceDistance = atr * inpTPxATRxPlier;
✅ Notes / Design Choices (Why this works well)
Avoids repaint by default (BAR_SIGNAL)
Handle is recreated only when:
symbol changes
timeframe changes
period changes
Minimal overhead: copies only 1 value per update
If you want, next we can generate libCTradeContext.mqh (final) and then patch your BuildTradeContext() to include:

Baseline result
Confirmation result (+ TTMS gate)
Volume result
ATR result
Just say “generate TradeContext next” and I’ll produce the complete file.








You said:
lets do libCExitSignal.mqh
Copilot said:
Copilot

Reasoning completed in 2 steps
Sure, Marteo — below is a complete, copy/paste-ready libCExitSignal.mqh that matches your Baseline-style architecture and integrates cleanly with the refactored Confirmation library you already have.

✅ Key features

Baseline-style: Update...() computes once and stores in ExitResult
Uses enum_Confirmation only (as you preferred)
Reuses indicator handle/buffer logic by inheriting from CConfirmationLibrary
Supports Exit indicators:
PSAR reversal exit
RVI reversal exit
Uses Bar Index abstraction (BAR_SIGNAL, BAR_PREVIOUS)
Includes a unified Update() dispatcher based on the configured exit indicator
Cleanly returns ExitResult Result() for the Trade Engine to consume
✅ libCExitSignal.mqh (Copy & Paste)



C++
//+------------------------------------------------------------------+
//|                                           libCExitSignal.mqh     |
//|                     Exit Signal Framework (Baseline-style)       |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCEXITSIGNAL_MQH__
#define __LIBCEXITSIGNAL_MQH__

#include <MyInclude\libEnum.mqh>
#include <MyInclude\libCBarIndex.mqh>

// Reuse indicator handle/buffer/refresh logic from confirmation library.
// This keeps ExitSignal lightweight and consistent.
#include <MyInclude\libCConfirmation.mqh>

// ------------------------------------------------------------------
// Exit params (keeps Update() calls tidy)
// ------------------------------------------------------------------
struct ExitPSARParams
{
   double step;
   double max;
};

struct ExitRVIParams
{
   int period;
};

// Exit mode for oscillators (RVI): choose behavior
// - EXIT_MODE_STATE: exit when main is on the wrong side of signal at BAR_SIGNAL
// - EXIT_MODE_CROSS: exit only when a cross happened between BAR_PREVIOUS and BAR_SIGNAL
enum enum_exitMode
{
   EXIT_MODE_STATE = 0,
   EXIT_MODE_CROSS = 1
};

// ------------------------------------------------------------------
// CExitSignal
// - Stores ExitResult (ShouldExit/Reason/Time)
// - Uses PSAR or RVI as exit indicator
// - Does NOT place trades; just reports "exit now?".
// ------------------------------------------------------------------
class CExitSignal : public CConfirmationLibrary
{
private:
   int       m_buffer_size;
   ExitResult m_result;

private:
   void ResetResult()
   {
      m_result.ShouldExit = false;
      m_result.Reason     = EXIT_NONE;
      m_result.Time       = 0;
   }

public:
   CExitSignal()
   {
      m_buffer_size = EnsureForPrevious(3);
      ResetResult();
   }

   ~CExitSignal() {}

   void SetBufferSize(int n)
   {
      m_buffer_size = EnsureForPrevious(n);
   }

   ExitResult Result() const
   {
      return m_result;
   }

   // ---------------------------------------------------------------
   // PSAR Exit (Reversal)
   // Long: exit if PSAR is ABOVE close (bearish reversal)
   // Short: exit if PSAR is BELOW close (bullish reversal)
   // ---------------------------------------------------------------
   bool UpdatePSARExit(string symbol,
                       ENUM_TIMEFRAMES tf,
                       enum_position currentPosition,
                       const ExitPSARParams &psar)
   {
      ResetResult();

      if(currentPosition != Long && currentPosition != Short)
         return false;

      if(!RefreshPSAR(symbol, tf, m_buffer_size, psar.step, psar.max))
         return false;

      double close1 = iClose(symbol, tf, BAR_SIGNAL);
      double ps1    = GetPSAR(BAR_SIGNAL);

      if(close1 == 0.0 || ps1 == EMPTY_VALUE)
         return false;

      // Reversal condition
      if(currentPosition == Long && ps1 > close1)
      {
         m_result.ShouldExit = true;
         m_result.Reason     = EXIT_REVERSAL;
      }
      else if(currentPosition == Short && ps1 < close1)
      {
         m_result.ShouldExit = true;
         m_result.Reason     = EXIT_REVERSAL;
      }

      m_result.Time = iTime(symbol, tf, BAR_SIGNAL);
      return m_result.ShouldExit;
   }

   // ---------------------------------------------------------------
   // RVI Exit (Reversal)
   // EXIT_MODE_STATE:
   //   Long: exit if RVI main < signal on BAR_SIGNAL
   //   Short: exit if RVI main > signal on BAR_SIGNAL
   //
   // EXIT_MODE_CROSS:
   //   Long: exit if main crossed DOWN (bar1 < sig1 AND bar2 >= sig2)
   //   Short: exit if main crossed UP   (bar1 > sig1 AND bar2 <= sig2)
   // ---------------------------------------------------------------
   bool UpdateRVIExit(string symbol,
                      ENUM_TIMEFRAMES tf,
                      enum_position currentPosition,
                      const ExitRVIParams &rvi,
                      enum_exitMode mode = EXIT_MODE_STATE)
   {
      ResetResult();

      if(currentPosition != Long && currentPosition != Short)
         return false;

      if(!RefreshRVI(symbol, tf, m_buffer_size, rvi.period))
         return false;

      double r1 = GetRVI_Main(BAR_SIGNAL);
      double s1 = GetRVI_Signal(BAR_SIGNAL);

      if(r1 == EMPTY_VALUE || s1 == EMPTY_VALUE)
         return false;

      bool exitNow = false;

      if(mode == EXIT_MODE_STATE)
      {
         // Fast exit: use current state at BAR_SIGNAL
         if(currentPosition == Long  && r1 < s1) exitNow = true;
         if(currentPosition == Short && r1 > s1) exitNow = true;
      }
      else // EXIT_MODE_CROSS
      {
         double r2 = GetRVI_Main(BAR_PREVIOUS);
         double s2 = GetRVI_Signal(BAR_PREVIOUS);

         if(r2 == EMPTY_VALUE || s2 == EMPTY_VALUE)
            return false;

         // Cross-based exit: reduce noise
         if(currentPosition == Long  && (r1 < s1 && r2 >= s2)) exitNow = true; // crossed down
         if(currentPosition == Short && (r1 > s1 && r2 <= s2)) exitNow = true; // crossed up
      }

      if(exitNow)
      {
         m_result.ShouldExit = true;
         m_result.Reason     = EXIT_REVERSAL;
      }

      m_result.Time = iTime(symbol, tf, BAR_SIGNAL);
      return m_result.ShouldExit;
   }

   // ---------------------------------------------------------------
   // Unified dispatcher:
   // Choose which exit indicator to use based on enum_Confirmation
   //
   // confirmDisable => no exit signal (always false)
   // ---------------------------------------------------------------
   bool Update(string symbol,
               ENUM_TIMEFRAMES tf,
               enum_position currentPosition,
               enum_Confirmation exitIndicator,
               const ExitPSARParams &psar,
               const ExitRVIParams &rvi,
               enum_exitMode rviMode = EXIT_MODE_STATE)
   {
      ResetResult();

      if(exitIndicator == confirmDisable)
         return false;

      switch(exitIndicator)
      {
         case PSAR:
            return UpdatePSARExit(symbol, tf, currentPosition, psar);

         case RVI:
            return UpdateRVIExit(symbol, tf, currentPosition, rvi, rviMode);

         // Future: KUSKUS exit, etc.
         default:
            return false;
      }
   }
};

#endif // __LIBCEXITSIGNAL_MQH__
``

Show more lines
✅ How to Use in libCTradeEngine.mqh (Example)



C++
CExitSignal exitSignal;

// Build params from inputs
ExitPSARParams ps; ps.step = inpPSAR_Steps; ps.max = inpPSAR_Max;
ExitRVIParams  rv; rv.period = (int)inpRVI_Period;

// Determine current position direction (example)
enum_position posDir = Long; // or Short

exitSignal.Update(_Symbol,
                  inpTradeExecutionPeriod,
                  posDir,
                  inpExitIndicator,   // enum_Confirmation
                  ps,
                  rv,
                  EXIT_MODE_STATE);   // or EXIT_MODE_CROSS

ExitResult er = exitSignal.Result();
if(er.ShouldExit)
{
   // Close position here (TradeHndlr.PositionClose, etc.)
}

Show more lines
🔧 Design Notes (why this matches your framework)
Exit is independent from entry confirmation (clean separation)
Uses same handle recreation logic (via CConfirmationLibrary)
Uses BAR_SIGNAL to avoid repaint issues
Produces a single struct (ExitResult) just like Baseline/Confirmation/Volume/ATR
Quick question (so I align it perfectly)
For RVI exits, do you prefer default behavior:

STATE (faster exits, more whipsaws), or
CROSS (slower exits, less noise)?
You chose TTMS as a hard gate for entries; many systems pair that with RVI CROSS for exits to reduce churn — but it depends on your strategy.








You said:
CROSS 
Copilot said:
Copilot

Reasoning completed in 1 step
Great — CROSS is the cleaner default for exits (less churn/whipsaw). ✅
Below is the final adjustment you need in libCExitSignal.mqh so RVI uses CROSS by default everywhere.

✅ What to change (2 small edits)
1) Make UpdateRVIExit() default to EXIT_MODE_CROSS
Find:




C++
bool UpdateRVIExit(...,
                   enum_exitMode mode = EXIT_MODE_STATE)
``
✅ Change to:




C++
bool UpdateRVIExit(...,
                   enum_exitMode mode = EXIT_MODE_CROSS)
``
2) Make the unified Update() default to EXIT_MODE_CROSS
Find:




C++
bool Update(...,
            enum_exitMode rviMode = EXIT_MODE_STATE)
✅ Change to:




C++
bool Update(...,
            enum_exitMode rviMode = EXIT_MODE_CROSS)
``
That’s it.

✅ Updated libCExitSignal.mqh (Complete Copy/Paste)
Here is the same file I generated earlier, but with CROSS as default:




C++
//+------------------------------------------------------------------+
//|                                           libCExitSignal.mqh     |
//|                     Exit Signal Framework (Baseline-style)       |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCEXITSIGNAL_MQH__
#define __LIBCEXITSIGNAL_MQH__

#include <MyInclude\libEnum.mqh>
#include <MyInclude\libCBarIndex.mqh>
#include <MyInclude\libCConfirmation.mqh>  // inherits CConfirmationLibrary

// ------------------------------------------------------------------
// Exit params (keeps Update() calls tidy)
// ------------------------------------------------------------------
struct ExitPSARParams
{
   double step;
   double max;
};

struct ExitRVIParams
{
   int period;
};

// Exit mode for oscillators (RVI):
// - EXIT_MODE_STATE: exit when main is on the wrong side of signal at BAR_SIGNAL
// - EXIT_MODE_CROSS: exit only when a cross happened between BAR_PREVIOUS and BAR_SIGNAL
enum enum_exitMode
{
   EXIT_MODE_STATE = 0,
   EXIT_MODE_CROSS = 1
};

// ------------------------------------------------------------------
// CExitSignal
// - Stores ExitResult (ShouldExit/Reason/Time)
// - Uses PSAR or RVI as exit indicator
// - Does NOT place trades; just reports "exit now?".
// ------------------------------------------------------------------
class CExitSignal : public CConfirmationLibrary
{
private:
   int        m_buffer_size;
   ExitResult m_result;

private:
   void ResetResult()
   {
      m_result.ShouldExit = false;
      m_result.Reason     = EXIT_NONE;
      m_result.Time       = 0;
   }

public:
   CExitSignal()
   {
      m_buffer_size = EnsureForPrevious(3);
      ResetResult();
   }

   ~CExitSignal() {}

   void SetBufferSize(int n)
   {
      m_buffer_size = EnsureForPrevious(n);
   }

   ExitResult Result() const
   {
      return m_result;
   }

   // ---------------------------------------------------------------
   // PSAR Exit (Reversal)
   // Long: exit if PSAR is ABOVE close (bearish reversal)
   // Short: exit if PSAR is BELOW close (bullish reversal)
   // ---------------------------------------------------------------
   bool UpdatePSARExit(string symbol,
                       ENUM_TIMEFRAMES tf,
                       enum_position currentPosition,
                       const ExitPSARParams &psar)
   {
      ResetResult();

      if(currentPosition != Long && currentPosition != Short)
         return false;

      if(!RefreshPSAR(symbol, tf, m_buffer_size, psar.step, psar.max))
         return false;

      double close1 = iClose(symbol, tf, BAR_SIGNAL);
      double ps1    = GetPSAR(BAR_SIGNAL);

      if(close1 == 0.0 || ps1 == EMPTY_VALUE)
         return false;

      if(currentPosition == Long && ps1 > close1)
      {
         m_result.ShouldExit = true;
         m_result.Reason     = EXIT_REVERSAL;
      }
      else if(currentPosition == Short && ps1 < close1)
      {
         m_result.ShouldExit = true;
         m_result.Reason     = EXIT_REVERSAL;
      }

      m_result.Time = iTime(symbol, tf, BAR_SIGNAL);
      return m_result.ShouldExit;
   }

   // ---------------------------------------------------------------
   // RVI Exit (Reversal)
   // DEFAULT: EXIT_MODE_CROSS (less noise)
   //
   // EXIT_MODE_STATE:
   //   Long: exit if RVI main < signal on BAR_SIGNAL
   //   Short: exit if RVI main > signal on BAR_SIGNAL
   //
   // EXIT_MODE_CROSS:
   //   Long: exit if main crossed DOWN (bar1 < sig1 AND bar2 >= sig2)
   //   Short: exit if main crossed UP   (bar1 > sig1 AND bar2 <= sig2)
   // ---------------------------------------------------------------
   bool UpdateRVIExit(string symbol,
                      ENUM_TIMEFRAMES tf,
                      enum_position currentPosition,
                      const ExitRVIParams &rvi,
                      enum_exitMode mode = EXIT_MODE_CROSS)
   {
      ResetResult();

      if(currentPosition != Long && currentPosition != Short)
         return false;

      if(!RefreshRVI(symbol, tf, m_buffer_size, rvi.period))
         return false;

      double r1 = GetRVI_Main(BAR_SIGNAL);
      double s1 = GetRVI_Signal(BAR_SIGNAL);

      if(r1 == EMPTY_VALUE || s1 == EMPTY_VALUE)
         return false;

      bool exitNow = false;

      if(mode == EXIT_MODE_STATE)
      {
         if(currentPosition == Long  && r1 < s1) exitNow = true;
         if(currentPosition == Short && r1 > s1) exitNow = true;
      }
      else // EXIT_MODE_CROSS
      {
         double r2 = GetRVI_Main(BAR_PREVIOUS);
         double s2 = GetRVI_Signal(BAR_PREVIOUS);

         if(r2 == EMPTY_VALUE || s2 == EMPTY_VALUE)
            return false;

         if(currentPosition == Long  && (r1 < s1 && r2 >= s2)) exitNow = true; // crossed down
         if(currentPosition == Short && (r1 > s1 && r2 <= s2)) exitNow = true; // crossed up
      }

      if(exitNow)
      {
         m_result.ShouldExit = true;
         m_result.Reason     = EXIT_REVERSAL;
      }

      m_result.Time = iTime(symbol, tf, BAR_SIGNAL);
      return m_result.ShouldExit;
   }

   // ---------------------------------------------------------------
   // Unified dispatcher:
   // DEFAULT RVI MODE: EXIT_MODE_CROSS
   // ---------------------------------------------------------------
   bool Update(string symbol,
               ENUM_TIMEFRAMES tf,
               enum_position currentPosition,
               enum_Confirmation exitIndicator,
               const ExitPSARParams &psar,
               const ExitRVIParams &rvi,
               enum_exitMode rviMode = EXIT_MODE_CROSS)
   {
      ResetResult();

      if(exitIndicator == confirmDisable)
         return false;

      switch(exitIndicator)
      {
         case PSAR:
            return UpdatePSARExit(symbol, tf, currentPosition, psar);

         case RVI:
            return UpdateRVIExit(symbol, tf, currentPosition, rvi, rviMode);

         default:
            return false;
      }
   }
};

#endif // __LIBCEXITSIGNAL_MQH__
``

Show less
✅ How to call it (no need to pass mode anymore)
Since CROSS is now default:




C++
ExitPSARParams ps; ps.step = inpPSAR_Steps; ps.max = inpPSAR_Max;
ExitRVIParams  rv; rv.period = (int)inpRVI_Period;

exitSignal.Update(_Symbol,
                  inpTradeExecutionPeriod,
                  posDir,
                  inpExitIndicator,
                  ps,
                  rv);  // ✅ CROSS default
``
Optional improvement (recommended)
If you want exits to be even cleaner, you can add a minimum bar confirmation (e.g., require RVI cross AND close breaks baseline), but CROSS already reduces noise significantly.
*/