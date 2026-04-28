

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


