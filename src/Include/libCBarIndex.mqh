//+------------------------------------------------------------------+
//|                                             libCBarIndex.mqh     |
//|                     Standard Bar Index Abstraction (MQL5)        |
//|                                                     Marteo Cosme |
//|                               Designed for Baseline-style engines |
//+------------------------------------------------------------------+
#property strict

#ifndef __LIBCBARINDEX_MQH__
#define __LIBCBARINDEX_MQH__

// ------------------------------------------------------------------
// Canonical bar references for SERIES arrays in MQL5:
// - Bar 0 = current forming candle (avoid for signals to prevent repaint)
// - Bar 1 = last closed candle (primary signal bar)
// - Bar 2 = previous closed candle (cross/flip comparisons)
// - Bar 3 = optional deeper confirmation bar
// ------------------------------------------------------------------
#define BAR_CURRENT   0
#define BAR_SIGNAL    1
#define BAR_PREVIOUS  2
#define BAR_CONFIRM   3

// ------------------------------------------------------------------
// Optional aliases (readability)
// ------------------------------------------------------------------
#define SHIFT_CURRENT  BAR_CURRENT
#define SHIFT_SIGNAL   BAR_SIGNAL
#define SHIFT_PREV     BAR_PREVIOUS
#define SHIFT_CONFIRM  BAR_CONFIRM

// ------------------------------------------------------------------
// Helpers for minimum required buffer sizes (avoid out-of-range)
// ------------------------------------------------------------------
int BarsNeededForSignal()   { return (BAR_SIGNAL   + 1); }  // needs bars [0..1]
int BarsNeededForPrevious() { return (BAR_PREVIOUS + 1); }  // needs bars [0..2]
int BarsNeededForConfirm()  { return (BAR_CONFIRM  + 1); }  // needs bars [0..3]

// Ensure minimum buffer size for logic that uses BAR_PREVIOUS etc.
int EnsureBars(const int requested, const int required)
{
   return (requested < required ? required : requested);
}

// Common presets
int EnsureForSignal(const int requested)   { return EnsureBars(requested, BarsNeededForSignal()); }
int EnsureForPrevious(const int requested) { return EnsureBars(requested, BarsNeededForPrevious()); }
int EnsureForConfirm(const int requested)  { return EnsureBars(requested, BarsNeededForConfirm()); }

#endif // __LIBCBARINDEX_MQH__
