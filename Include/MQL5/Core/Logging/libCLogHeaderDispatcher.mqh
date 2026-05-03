//+------------------------------------------------------------------+
//| libCLogHeaderDispatcher.mqh                                     |
//| Centralized Header Management (Phase 4.3 Hardening)             |
//| Marteo Cosme                                                    |
//+------------------------------------------------------------------+
#property strict
#ifndef __LIBC_LOG_HEADER_DISPATCHER_MQH__
#define __LIBC_LOG_HEADER_DISPATCHER_MQH__

class CLogHeaderDispatcher
{
private:
   struct HeaderState
   {
      string file_name;
      bool   checked;
      bool   needs_header;
   };

   // Fixed small registry (you only have a few log files)
   HeaderState m_states[10];
   int         m_count;

public:
   CLogHeaderDispatcher() : m_count(0) {}

   // --------------------------------------------------------------
   // PUBLIC: Check if header is needed (cached per file)
   // --------------------------------------------------------------
   bool NeedsHeader(const string file_name)
   {
      int idx = FindOrRegister(file_name);

      if(!m_states[idx].checked)
      {
         m_states[idx].needs_header = DetectHeader(file_name);
         m_states[idx].checked = true;
      }

      return m_states[idx].needs_header;
   }

   // --------------------------------------------------------------
   // PUBLIC: Mark header as written (important!)
   // --------------------------------------------------------------
   void MarkHeaderWritten(const string file_name)
   {
      int idx = FindOrRegister(file_name);
      m_states[idx].needs_header = false;
   }

private:

   // --------------------------------------------------------------
   // INTERNAL: Find existing or register new file entry
   // --------------------------------------------------------------
   int FindOrRegister(const string file_name)
   {
      for(int i = 0; i < m_count; i++)
      {
         if(m_states[i].file_name == file_name)
            return i;
      }

      // Register new
      m_states[m_count].file_name = file_name;
      m_states[m_count].checked = false;
      m_states[m_count].needs_header = true;

      m_count++;
      return (m_count - 1);
   }

   // --------------------------------------------------------------
   // INTERNAL: Detect header safely (content-based)
   // --------------------------------------------------------------
   bool DetectHeader(const string file_name)
   {
      int h = FileOpen(file_name, FILE_READ | FILE_TXT | FILE_COMMON);

      if(h == INVALID_HANDLE)
         return true;

      if(FileSize(h) == 0)
      {
         FileClose(h);
         return true;
      }

      string first_line = FileReadString(h);
      FileClose(h);

      // ✅ robust check (handles BOM / formatting variance)
      if(StringFind(first_line, "debug_event_id") != -1)
         return false;

      return true;
   }
};

#endif // __LIBC_LOG_HEADER_DISPATCHER_MQH__

