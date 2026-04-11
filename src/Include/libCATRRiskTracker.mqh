//+------------------------------------------------------------------+
//|                                       libCATRRiskTracker.mqh     |
//|                    ATR Ticket Risk Tracker (Trade Management)    |
//|                                                     Marteo Cosme |
//|                                            Updated: 2026-04-02   |
//+------------------------------------------------------------------+
//| Need to be rename | TradeTicketInfo?

#property strict

#ifndef __LIBCATRRISKTRACKER_MQH__
#define __LIBCATRRISKTRACKER_MQH__

#include <MyInclude\NNFX\libEnum.mqh>      // tableATR struct
#include <MyInclude\NNFX\libCBarIndex.mqh> // optional consistency (not required here)

// ------------------------------------------------------------------
// CATRRiskTracker
// - Tracks ATR values per position ticket (long-term management)
// - Intended usage:
//   1) When opening a position, compute ATR via CATRSignal and AddOrUpdate(ticket, atr)
//   2) On every tick / new candle, call PruneClosedTickets() or SyncWithOpenPositions()
//   3) Use GetATR(ticket) for trailing stop, break-even, scaling logic
// ------------------------------------------------------------------
class CATRRiskTracker
{
private:
   tableATR m_list[];   // dynamic array of {ticket, atr}

private:
   // Find index by ticket. Returns -1 if not found.
   int FindIndexByTicket(const long ticket) const
   {
      int n = ArraySize(m_list);
      for(int i = 0; i < n; i++)
         {
         if(m_list[i].ticket == ticket)
            return i;
         }
      return -1;
   }

   // Check if a ticket exists among currently open positions
   bool IsTicketOpen(const long ticket) const
   {
      // PositionSelectByTicket exists in MQL5
      return PositionSelectByTicket((ulong)ticket);
   }

public:
   CATRRiskTracker()
   {
      ArrayResize(m_list, 0);
   }

   ~CATRRiskTracker() {}
   
   // ✅ PUBLIC: lifecycle sequencing (REQUIRED)
   uint NextEventSeq(const long ticket)
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return 0;
      return ++m_list[idx].eventSeq;
   }

   // ---------------------------------------------------------------
   // Basic operations
   // ---------------------------------------------------------------
   int Count() const
   {
      return ArraySize(m_list);
   }

   bool Exists(const long ticket) const
   {
      return (FindIndexByTicket(ticket) >= 0);
   }

   // Add ticket+ATR only if ticket not present
   bool AddTicket(const long ticket, const double atrValue)
   {
  
      if(ticket <= 0) return false;
      if(Exists(ticket)) return false;

      int n = ArraySize(m_list);
      ArrayResize(m_list, n + 1);
      m_list[n].ticket = ticket;
      m_list[n].atr    = atrValue;
      m_list[n].beApplied = false;
      m_list[n].eventSeq = 0;
      ArrayResize(m_list[n].scaleStages, 0);
      return true;
   }

   // Add if missing; otherwise update ATR
   bool AddOrUpdate(const long ticket, const double atrValue)
   {
      if(ticket <= 0) return false;

      int idx = FindIndexByTicket(ticket);
      if(idx < 0)
         {
         int n = ArraySize(m_list);
         ArrayResize(m_list, n + 1);
         m_list[n].ticket = ticket;
         m_list[n].atr    = atrValue;
         m_list[n].beApplied = false;   // ✅ initialize
         return true;
         }

      m_list[idx].atr = atrValue;
      return true;
   }

   bool RemoveTicket(const long ticket)
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return false;

      int n = ArraySize(m_list);

      // Shift left to fill the removed slot
      for(int i = idx; i < n - 1; i++)
         {
         m_list[i] = m_list[i + 1];
         }

      ArrayResize(m_list, n - 1);
      return true;
   }

   // Get ATR value by ticket. Returns EMPTY_VALUE if not found.
   double GetATR(const long ticket) const
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return EMPTY_VALUE;
      return m_list[idx].atr;
   }

   // Set ATR by ticket (only if exists)
   bool SetATR(const long ticket, const double atrValue)
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return false;
      m_list[idx].atr = atrValue;
      return true;
   }

   bool MarkBEApplied(const long ticket)
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return false;

      m_list[idx].beApplied = true;
      return true;
   }

   bool IsBEApplied(const long ticket) const
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return false;

      return m_list[idx].beApplied;
   }
   // ------------------------------------------------------------
// Check if a scaling stage is already applied
// ------------------------------------------------------------
   bool IsScaleStageApplied(const long ticket, const double stageATR) const
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return false;

      int n = ArraySize(m_list[idx].scaleStages);
      for(int i = 0; i < n; i++)
         {
         if(MathAbs(m_list[idx].scaleStages[i] - stageATR) < 1e-6)
            return true;
         }
      return false;
   }

// ------------------------------------------------------------
// Mark a scaling stage as applied
// ------------------------------------------------------------
   bool MarkScaleStageApplied(const long ticket, const double stageATR)
   {
      int idx = FindIndexByTicket(ticket);
      if(idx < 0) return false;

      int n = ArraySize(m_list[idx].scaleStages);
      ArrayResize(m_list[idx].scaleStages, n + 1);
      m_list[idx].scaleStages[n] = stageATR;
      return true;
   }



   // Remove everything
   void Clear()
   {
      ArrayResize(m_list, 0);
   }

   // ---------------------------------------------------------------
   // Maintenance / Sync functions
   // ---------------------------------------------------------------

   // Remove tickets that are no longer open positions
   // Recommended to call periodically (e.g., every new candle)
   int PruneClosedTickets()
   {
      int removed = 0;
      for(int i = ArraySize(m_list) - 1; i >= 0; i--)
         {
         long t = m_list[i].ticket;
         if(!IsTicketOpen(t))
            {
            RemoveTicket(t);
            removed++;
            }
         }
      return removed;
   }

   // Ensure all open positions exist in the tracker.
   // If missing, add with defaultAtr (you can later update).
   // Also prunes closed tickets.
   int SyncWithOpenPositions(const double defaultAtr = EMPTY_VALUE)
   {
      // 1) prune closed
      PruneClosedTickets();

      // 2) add missing open tickets
      int added = 0;
      int total = PositionsTotal();
      for(int i = 0; i < total; i++)
         {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;

         if(!Exists((long)ticket))
            {
            AddTicket((long)ticket, defaultAtr);
            added++;
            }
         }
      return added;
   }

   // Optional helper: remove everything that doesn't match a symbol
   // Useful if you track per-symbol
   int PruneBySymbol(const string symbol)
   {
      int removed = 0;
      for(int i = ArraySize(m_list) - 1; i >= 0; i--)
         {
         long t = m_list[i].ticket;

         if(!PositionSelectByTicket((ulong)t))
            {
            RemoveTicket(t);
            removed++;
            continue;
            }

         string sym = PositionGetString(POSITION_SYMBOL);
         if(sym != symbol)
            {
            RemoveTicket(t);
            removed++;
            }
         }
      return removed;
   }

   // ---------------------------------------------------------------
   // Diagnostics
   // ---------------------------------------------------------------
   void PrintAll(const string tag = "ATRRiskTracker")
   {
      int n = ArraySize(m_list);
      PrintFormat("[%s] items=%d", tag, n);
      for(int i = 0; i < n; i++)
         {
         PrintFormat("[%s] #%d ticket=%d atr=%f", tag, i, m_list[i].ticket, m_list[i].atr);
         }
   }
};

#endif // __LIBCATRRISKTRACKER_MQH__



/*
Recommended Usage Pattern (How it plugs into your engine)
1) When you open a new position
Use CATRSignal to compute ATR, then store it with the ticket:

// After opening trade and getting ticket:
long ticket = (long)PositionGetInteger(POSITION_TICKET);

// Assume atrSignal.Update(...) already called
double atrAtEntry = atrSignal.Result().Value;

atrTracker.AddOrUpdate(ticket, atrAtEntry);
``

2) Each new candle (or periodically)
Clean up closed tickets:

atrTracker.PruneClosedTickets();
``

3) When managing trailing stop / BE / scaling
Retrieve ATR:

double atrEntry = atrTracker.GetATR(ticket);
if(atrEntry != EMPTY_VALUE)
{
   // use atrEntry for trailing / break-even distance, etc.
}
*/
//+------------------------------------------------------------------+
