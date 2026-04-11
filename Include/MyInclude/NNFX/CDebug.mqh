//+------------------------------------------------------------------+
//|                                                   CDebug.mqh     |
//|                       Lightweight Debug Utility for MQL5         |
//|                                                     Marteo Cosme |
//+------------------------------------------------------------------+
#property strict

#ifndef __CDEBUG_MQH__
#define __CDEBUG_MQH__

// ---------------------------------------------------------------
// Debug levels (higher = more verbose)
// ---------------------------------------------------------------
enum enum_debugLevel
{
   DBG_OFF     = 0,
   DBG_ERROR   = 1,
   DBG_WARN    = 2,
   DBG_INFO    = 3,
   DBG_VERBOSE = 4
};

// ---------------------------------------------------------------
// Debug utility class
// ---------------------------------------------------------------
class CDebugPrint
{
private:
   bool           m_enabled;
   enum_debugLevel m_level;
   string         m_tag;
   bool           m_showContext;

   // Anti-spam throttle (milliseconds)
   bool           m_useThrottle;
   uint           m_throttleMs;
   uint           m_lastTick;

public:
   CDebugPrint()
   {
      m_enabled     = true;
      m_level       = DBG_INFO;
      m_tag         = "DEBUG";
      m_showContext = false;

      m_useThrottle = false;
      m_throttleMs  = 250;
      m_lastTick    = 0;
   }

   // ----------------------------
   // Configuration
   // ----------------------------
   void SetEnabled(const bool enabled)
   {
      m_enabled = enabled;
   }
   void SetLevel(const enum_debugLevel lvl)
   {
      m_level = lvl;
   }
   void SetTag(const string tag)
   {
      m_tag = tag;
   }
   void ShowContext(const bool on)
   {
      m_showContext = on;
   }

   // Throttle controls (prevents spamming the Experts tab)
   void EnableThrottle(const bool on)
   {
      m_useThrottle = on;
   }
   void SetThrottleMs(const uint ms)
   {
      m_throttleMs = ms;
   }

   bool Enabled() const
   {
      return m_enabled;
   }
   enum_debugLevel Level() const
   {
      return m_level;
   }

private:
   // ----------------------------
   // Internal helpers
   // ----------------------------
   bool CanPrint()
   {
      if(!m_useThrottle) return true;

      uint now = (uint)GetTickCount();
      if(m_lastTick == 0 || (now - m_lastTick) >= m_throttleMs)
         {
         m_lastTick = now;
         return true;
         }
      return false;
   }

   string LevelToString(const enum_debugLevel lvl) const
   {
      switch(lvl)
         {
         case DBG_ERROR:
            return "ERROR";
         case DBG_WARN:
            return "WARN";
         case DBG_INFO:
            return "INFO";
         case DBG_VERBOSE:
            return "VERBOSE";
         default:
            return "OFF";
         }
   }

   string BuildPrefix(const enum_debugLevel lvl,
                      const string file,
                      const int line,
                      const string func) const
   {
      string prefix = "[" + m_tag + "][" + LevelToString(lvl) + "] ";

      if(m_showContext)
         prefix += "(" + file + ":" + IntegerToString(line) + " " + func + ") ";

      return prefix;
   }

public:
   // ----------------------------
   // Print methods
   // ----------------------------
   void Log(const enum_debugLevel lvl,
            const string msg,
            const string file = "",
            const int line = 0,
            const string func = "")
   {
      if(!m_enabled) return;
      if(lvl > m_level) return;
      if(!CanPrint()) return;

      Print(BuildPrefix(lvl, file, line, func) + msg);
   }

   void Error(const string msg, const string file = "", const int line = 0, const string func = "")
   {
      Log(DBG_ERROR, msg, file, line, func);
   }

   void Warn(const string msg, const string file = "", const int line = 0, const string func = "")
   {
      Log(DBG_WARN, msg, file, line, func);
   }

   void Info(const string msg, const string file = "", const int line = 0, const string func = "")
   {
      Log(DBG_INFO, msg, file, line, func);
   }

   void Verbose(const string msg, const string file = "", const int line = 0, const string func = "")
   {
      Log(DBG_VERBOSE, msg, file, line, func);
   }

   // PrintFormat wrapper (keeps the class cohesive)
   void LogFormat(const enum_debugLevel lvl,
                  const string fmt,
                  const string file = "",
                  const int line = 0,
                  const string func = "")
   {
      if(!m_enabled) return;
      if(lvl > m_level) return;
      if(!CanPrint()) return;

      // Build prefix then PrintFormat the full string
      string prefix = BuildPrefix(lvl, file, line, func);
      PrintFormat(prefix + fmt);
   }
};

// ---------------------------------------------------------------
// Convenience free functions (match your engine usage)
// Example: DebugPrint(debug, "message");
// ---------------------------------------------------------------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DebugPrint(CDebugPrint &dbg, const string msg, const enum_debugLevel lvl = DBG_INFO)
{
   dbg.Log(lvl, msg);
}

// Same as DebugPrint but includes file/line/function context
void DebugPrintCtx(CDebugPrint &dbg,
                   const string msg,
                   const enum_debugLevel lvl,
                   const string file,
                   const int line,
                   const string func)
{
   dbg.Log(lvl, msg, file, line, func);
}

// Macros for easy context logging
#define DEBUG_ERROR(dbg, msg)   DebugPrintCtx((dbg), (msg), DBG_ERROR,   __FILE__, __LINE__, __FUNCTION__)
#define DEBUG_WARN(dbg, msg)    DebugPrintCtx((dbg), (msg), DBG_WARN,    __FILE__, __LINE__, __FUNCTION__)
#define DEBUG_INFO(dbg, msg)    DebugPrintCtx((dbg), (msg), DBG_INFO,    __FILE__, __LINE__, __FUNCTION__)
#define DEBUG_VERBOSE(dbg, msg) DebugPrintCtx((dbg), (msg), DBG_VERBOSE, __FILE__, __LINE__, __FUNCTION__)

#endif // __CDEBUG_MQH__


/*

✅ How to Use It (Matches Your Current Style)
1) Basic usage (your current pattern)

CDebugPrint debug;
DebugPrint(debug, "Engine initialized");
DebugPrint(debug, "Something happened", DBG_VERBOSE);

2) Enable context output (file/line/function)
debug.ShowContext(true);
DEBUG_INFO(debug, "Baseline parameter invalid");

3) Throttle spam (recommended during testing)
debug.EnableThrottle(true);
debug.SetThrottleMs(200);
// print at most every 200ms

4) Set log level
debug.SetLevel(DBG_VERBOSE); // prints everything
debug.SetLevel(DBG_INFO);    // info+warn+error
debug.SetLevel(DBG_WARN);    // warn+error only
debug.SetLevel(DBG_OFF);     // silent``Show more lines
*/
