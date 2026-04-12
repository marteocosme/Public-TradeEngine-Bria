//+------------------------------------------------------------------+
//|                                                   libEnum.mqh    |
//|                         Central Enum & Struct Definitions (2026) |
//|                                          Marteo Cosme 04/02/2026 |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBENUM_MQH__
#define __LIBENUM_MQH__

// ================================================================
// 1) UNIVERSAL POSITION / DIRECTION ENUM
// ================================================================
enum enum_position
{
   NoTrade   = 0,   // No action / neutral
   Short     = -1,  // Short trade direction
   Long      = 1,   // Long trade direction

   // Optional: higher-level trend direction (if you explicitly use it)
   UpTrend   = 2,
   DownTrend = -2
};

// ================================================================
// 2) RISK SETTINGS ENUMS
// ================================================================
enum enum_riskMethod
{
   RISK_BALANCE = 0,  // Risk is based on ACCOUNT_BALANCE
   RISK_EQUITY  = 1,  // Risk is based on ACCOUNT_EQUITY
   RISK_FIXED   = 2   // Risk is fixed amount (inpRiskFixAmount)
};

// ================================================================
// 3) BASELINE ENUMS + RESULT STRUCT
// ================================================================
enum enum_Baseline
{
   MA   = 0,
   SWMA = 1
};

enum enum_baselineSignal
{
   SigNone  = 0,
   SigLong  = 1,
   SigShort = -1
};

enum enum_baselineTrend
{
   TrendNone = 0,
   TrendUp   = 1,
   TrendDown = -1
};

struct BaselineResult
{
   enum_baselineSignal signal;
   enum_baselineTrend  trend;
};

// ================================================================
// 4) CONFIRMATION ENUMS + RESULT STRUCT (ONLY enum_Confirmation)
// ================================================================
enum enum_ConfirmationRole
{
   Primary   = 0,
   Secondary = 1
};

enum enum_Confirmation
{
   confirmDisable = 0,
   PSAR           = 1,
   RVI            = 2,
   KUSKUS         = 3
};

// More explicit source tag for results (optional but recommended)
enum enum_confirmSource
{
   CONF_NONE = 0,
   CONF_PSAR_SRC,
   CONF_RVI_SRC,
   CONF_KUSKUS_SRC
};

// Helper mapper (no 'inline' to keep compatibility simple)
enum_confirmSource ConfirmToSource(const enum_Confirmation c)
{
   switch(c)
      {
      case PSAR:
         return CONF_PSAR_SRC;
      case RVI:
         return CONF_RVI_SRC;
      case KUSKUS:
         return CONF_KUSKUS_SRC;
      default:
         return CONF_NONE;
      }
}

struct ConfirmationResult
{
   enum_position      Signal;          // Long/Short/NoTrade
   enum_position      Trend;           // Long/Short/NoTrade
   bool               IsValid;
   datetime           Time;

   enum_confirmSource PrimarySource;
   enum_confirmSource SecondarySource;

   int                Score;           // 0-100 confidence score (optional)
};

// ================================================================
// 5) VOLUME ENUMS + RESULT STRUCT  (TTMS: Squeeze ON/OFF)
// ================================================================

// Engine input selector
enum ENUM_VOL_IND
{
   TTMS = 0
};

// Internal volume indicator enum
enum ENUM_VOLUME_INDICATOR
{
   VOL_TTMS = 0
};

// TTMS is NOT directional (in your version). It is a state.
// Positive => Squeeze ON (energy/volume present)
// Zero/Negative => Squeeze OFF (no volume)
enum enum_volumeState
{
   VOL_STATE_OFF = 0,   // Squeeze OFF
   VOL_STATE_ON  = 1    // Squeeze ON (good volume/energy)
};

struct VolumeResult
{
   enum_volumeState      State;
   bool                  IsValid;
   datetime              Time;
   ENUM_VOLUME_INDICATOR Source;

   void Reset()
   {
      State  = VOL_STATE_OFF;
      IsValid = false;
      Time   = 0;
      Source = (ENUM_VOLUME_INDICATOR) - 1;
   }
};


// ================================================================
// 6) EXIT ENUMS + RESULT STRUCT
// ================================================================
enum enum_exitReason
{
   EXIT_NONE = 0,
   EXIT_REVERSAL,
   EXIT_TRAIL,
   EXIT_TIME,
   EXIT_MANUAL
};

struct ExitResult
{
   bool            ShouldExit;
   enum_exitReason Reason;
   datetime        Time;
};

// ================================================================
// 7) ATR STRUCTS (Ticket tracking + baseline-style result)
// ================================================================
struct tableATR
{
   long   ticket;
   double atr;
   bool   beApplied;   // ✅ Break-even already applied?
   double scaleStages[];   // ✅ ATR multiples already scaled out
   uint eventSeq;
};

struct ATRResult
{
   double   Value;
   bool     IsValid;
   datetime Time;

   void Reset()
   {
      Value   = 0.0;
      IsValid = false;
      Time    = 0;
   }
};

// ================================================================
// 8) Input STRUCTS (For passing multiple related parameters to functions, optional but cleaner)
// ================================================================
struct RiskSettings
{
   enum_riskMethod   method;
   double riskPercent;       // Used if method is RISK_BALANCE or RISK_EQUITY
   double fixedAmount;      // Used if method is RISK_FIXED
   double SLxATRMultiplier; // For ATR-based SL calculation
   int    MaxOpenPositions;  // Max concurrent positions
   bool   ScalingOut;       // Whether to scale out at ATR multiples

   void Reset()
   {
      method = RISK_BALANCE;
      riskPercent = 0.01;           // Default to 1% risk
      fixedAmount = 100.0;          // Default to $100 fixed risk
      SLxATRMultiplier = 1.5;       // Default SL distance in ATR multiples
      MaxOpenPositions = 1;         // Default max open positions
      ScalingOut = true;            // Default to scaling out
   }
};

struct TopdownSettings
{
   ENUM_TIMEFRAMES   EntryTF;
   ENUM_TIMEFRAMES   TopdownTF;
   void Reset()
   {
      EntryTF = PERIOD_M15;   // Default entry timeframe
      TopdownTF = PERIOD_D1;  // Default topdown timeframe
   }
};

// ==================================================================
// 9) Unified Event Definition
// ==================================================================
enum enum_tradeEvent
{
   EVT_SIGNAL,   // ✅ New - Decision snapshot (per candle)
   EVT_ENTRY,
   EVT_RISK,
   EVT_BE,
   EVT_TRAIL,
   EVT_SCALE,
   EVT_EXIT,
   EVT_SUMMARY
};


enum ENUM_MM_EVENT_TYPE
{
  MM_TradeValidated,
  MM_TradeRejected,
  MM_TradeOpened,
  MM_BreakEvenTriggered,
  MM_StopLossAdjusted,
  MM_PartialCloseExecuted,
  MM_ExitSignalReceived,
  MM_TradeClosed,
  MM_SafetyTriggered
};

enum ENUM_MM_PHASE
{
  MM_PreTrade,
  MM_Init,
  MM_Active,
  MM_Terminal,
  MM_Safety
};





// ================================================================
// 10) SIGNAL SNAPSHOT (Decision Telemetry)
// ================================================================

struct SignalSnapshot
{
   datetime time;
   string   symbol;

   // Baseline
   enum_baselineTrend baseTrend;

   // Confirmation
   enum_position confSignal;
   enum_position confTrend;
   int confScore;

   // Volume
   enum_volumeState volState;

   // Final decision
   bool entryAllowed;
};

// ================================================================
// 10) Entry Strategy Enum Type
// ================================================================

enum enum_entryStrategy
{
   ENTRY_STANDARD,
   ENTRY_BASELINE_CROSS,
   ENTRY_PULLBACK,       // future
   ENTRY_CONTINUATION    // future
};


struct EntryCandidate
{
   bool           allowed;
   enum_position  direction;
   string         reason;   // for logging & debugging
};






//+------------------------------------------------------------------+
//| Helper: Timeframe to string                                      |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES tf)
{
   if(tf == PERIOD_CURRENT)
      tf = (ENUM_TIMEFRAMES)Period();

   return StringSubstr(EnumToString(tf), 7);
}


#endif // __LIBENUM_MQH__
