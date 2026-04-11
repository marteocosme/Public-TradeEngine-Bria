//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                  DialogPanel.mqh |
//|                                   Cleaned & extended by request  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Controls\Defines.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>
#include <Controls\Panel.mqh>
#include <Controls\Edit.mqh>
#include <Controls\ComboBox.mqh>

#include <MyInclude\NNFX\libCTradeEngine.mqh>
#include <MyInclude\NNFX\CDebug.mqh>
#include <MyInclude\NNFX\libCTradeContext.mqh>

//--- Inputs
input group "Panel Setting"
input int   InpPanelX         = 0;                // Panel X (pixels)
input int   InpPanelY         = 50;               // Panel Y (pixels)
input int   InpPanelWidth     = 300;              // Width (pixels)
input int   InpPanelHeight    = 500;              // Height (pixels)
input int   InpPanelFontSize  = 10;               // Font size
input color InpPanelTxtColor  = clrBlack;    // Text color
input bool  InpDebug          = false;            // Debug prints
input group "-----"




//+------------------------------------------------------------------+
//| Class CPanelSignal                                                |
//+------------------------------------------------------------------+
class CPanelSignal : public CAppDialog
{
private:
   //--- Layout (single source of truth)
   struct SLayout
   {
      // Tab header
      int            tab_x, tab_y, tab_w, tab_h, tab_gap;

      // Page rectangle (content area under tabs)
      int            page_x1, page_y1, page_x2, page_y2;
      int            page_pad;

      // Grid defaults
      int            col_w;
      int            row_h;

      // Sizes
      int            lbl_w;
      int            sig_w;
      int            h;
   };

   SLayout           m_ui;

   //--- State
   string            m_prefix;
   int               m_active_tab;
   bool              m_auto_trade_on;

   // Settings values (stored)
   int               m_risk_mode;     // from combo Value()
   int               m_entry_mode;    // from combo Value()
   double            m_risk_pct;
   double            m_atr_mult;

   //--- Tab controls
   CButton           m_btn_TabSignals;
   CButton           m_btn_TabSettings;

   //--- Page backgrounds
   CPanel            m_bg_TabSignals;
   CPanel            m_bg_TabSettings;

   //--- Signals tab controls
   CButton           m_btn_AutoTrade;
   /*
   CButton m_btn_TradeExecute;
   CButton m_btn_TrendAnalysis;
   */

   CLabel            m_lbl_CurrentPeriod;
   CLabel            m_lbl_CurrentSymbol;

   CLabel            m_lbl_Header_tradeExecutePeriod;
   CLabel            m_lbl_Header_tradeAnalysisPeriod;

   CLabel            m_lbl_BaseLine;
   CLabel            m_lbl_1stConfirmation;
   CLabel            m_lbl_2ndConfirmation;
   CLabel            m_lbl_Volume;
   CLabel            m_lbl_ATR;

   CLabel            m_lbl_Baseline_Signal;
   CLabel            m_lbl_1stConfirmation_Signal;
   CLabel            m_lbl_2ndConfirmation_Signal;
   CLabel            m_lbl_Volume_Signal;
   CLabel            m_lbl_ATR_Signal;

   //--- Settings tab controls
   CLabel            m_lbl_RiskMode;
   CLabel            m_lbl_EntryMode;
   CLabel            m_lbl_RiskPct;
   CLabel            m_lbl_ATRMult;

   CComboBox         m_cb_RiskMode;
   CComboBox         m_cb_EntryMode;

   CEdit             m_ed_RiskPct;
   CEdit             m_ed_ATRMult;

private:
   //--- Naming
   string            Name(const string id) const
   {
      return m_prefix + id;
   }

   //--- Layout helpers
   int               X0() const
   {
      return m_ui.page_x1 + m_ui.page_pad;
   }
   int               Y0() const
   {
      return m_ui.page_y1 + m_ui.page_pad;
   }
   int               XCol(const int col) const
   {
      return X0() + col * m_ui.col_w;
   }
   int               YRow(const int baseY, const int row) const
   {
      return baseY + row * m_ui.row_h;
   }

   //--- Core
   bool              CheckInputs();
   void              InitLayout();
   bool              CreatePanel();
   bool              CreateTabs();
   bool              BuildTabSignals();
   bool              BuildTabSettings();

   //--- UI helpers
   void              StyleTabButtons();
   void              SetActiveTab(const int tab_index);

   void              AddLabel(CLabel &lbl, const string objName, const string text, int x1, int y1, int w, int h);
   void              AddSignalLabel(CLabel &lbl, const string objName, int x1, int y1, int w, int h);

   void              UpdateGlobals();                 // TF + Symbol labels
   void              UpdateAutoTradeButton();

   void              SetTradeSignal(CLabel &lbl, const int pos);
   void              UpdateFromContext(const TradeContext &ctx);

   //--- Settings sync/validation
   void              SyncSettingsFromControls();
   void              ValidateAndFixEdits();

   double            ReadDouble(const CEdit &ed, const double fallback) const;

public:
   CPanelSignal();
   ~CPanelSignal();

   bool              Oninit();
   void              CheckSignal();
   void              PanelChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
};

//+------------------------------------------------------------------+
//| Constructor / Destructor                                          |
//+------------------------------------------------------------------+
CPanelSignal::CPanelSignal()
{
   m_active_tab     = 0;
   m_auto_trade_on  = false;

// default settings
   m_risk_mode  = 0;
   m_entry_mode = 0;
   m_risk_pct   = 1.0;
   m_atr_mult   = 1.5;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPanelSignal::~CPanelSignal()
{
// Call Destroy() from your EA/Indicator OnDeinit.
}

//+------------------------------------------------------------------+
//| Init                                                              |
//+------------------------------------------------------------------+
bool CPanelSignal::Oninit()
{

   // initEngine(); 
   if(!CheckInputs())
      return false;

   InitLayout();

   if(!CreatePanel())
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Input validation                                                  |
//+------------------------------------------------------------------+
bool CPanelSignal::CheckInputs()
{
   if(InpPanelWidth <= 0)
      {
      Print("Panel width <= 0");
      return false;
      }
   if(InpPanelHeight <= 0)
      {
      Print("Panel height <= 0");
      return false;
      }
   if(InpPanelFontSize <= 0)
      {
      Print("Font size <= 0");
      return false;
      }
   return true;
}

//+------------------------------------------------------------------+
//| Layout init (constants)                                           |
//+------------------------------------------------------------------+
void CPanelSignal::InitLayout()
{
// Tabs
   m_ui.tab_x   = 10;
   m_ui.tab_y   = 10;
   m_ui.tab_w   = 120;
   m_ui.tab_h   = 22;
   m_ui.tab_gap = 5;

// Page padding + grid
   m_ui.page_pad = 10;
   m_ui.col_w    = 140;
   m_ui.row_h    = 22;

// Control sizes
   m_ui.lbl_w = 135;
   m_ui.sig_w = 120;
   m_ui.h     = 18;

// Unique prefix avoids collisions per chart/instance
   m_prefix = StringFormat("NNFX_%I64d_", ChartID());
}

//+------------------------------------------------------------------+
//| Create the dialog & content                                       |
//+------------------------------------------------------------------+
bool CPanelSignal::CreatePanel()
{
// Dialog Create expects rectangle corners (x1,y1,x2,y2)
   const int x1 = InpPanelX;
   const int y1 = InpPanelY;
   const int x2 = InpPanelX + InpPanelWidth;
   const int y2 = InpPanelY + InpPanelHeight;

   if(!this.Create(NULL, "NNFX Algo EA Panel", 0, x1, y1, x2, y2))
      {
      Print("Failed to create dialog");
      return false;
      }

// Page rectangle (content area under tabs)
   m_ui.page_x1 = 5;
   m_ui.page_y1 = m_ui.tab_y + m_ui.tab_h + 6;
   m_ui.page_x2 = this.Width()  - 10;
   m_ui.page_y2 = this.Height() - 30;

   if(!CreateTabs())
      return false;
   if(!BuildTabSignals())
      return false;
   if(!BuildTabSettings())
      return false;

   SetActiveTab(0);

   if(!Run())
      {
      Print("Failed to run panel");
      return false;
      }

   ChartRedraw(0);
   return true;
}

//+------------------------------------------------------------------+
//| Create tab buttons + background pages                             |
//+------------------------------------------------------------------+
bool CPanelSignal::CreateTabs()
{
// Tab buttons
   m_btn_TabSignals.Create(NULL, Name("tabSignals"), 0,
                           m_ui.tab_x, m_ui.tab_y,
                           m_ui.tab_x + m_ui.tab_w, m_ui.tab_y + m_ui.tab_h);
   m_btn_TabSignals.Text("Signals");
   m_btn_TabSignals.FontSize(InpPanelFontSize);
   this.Add(m_btn_TabSignals);

   m_btn_TabSettings.Create(NULL, Name("tabSettings"), 0,
                            m_ui.tab_x + m_ui.tab_w + m_ui.tab_gap, m_ui.tab_y,
                            m_ui.tab_x + 2 * m_ui.tab_w + m_ui.tab_gap, m_ui.tab_y + m_ui.tab_h);
   m_btn_TabSettings.Text("Settings");
   m_btn_TabSettings.FontSize(InpPanelFontSize);
   this.Add(m_btn_TabSettings);

// Background pages fill the same page rectangle
// CPanel background uses ColorBackground (BackColor internally) [6](https://github.com/Endt4sk/MQL5/blob/master/Include/Controls/Panel.mqh)
   m_bg_TabSignals.Create(NULL, Name("bgSignals"), 0,
                          m_ui.page_x1, m_ui.page_y1, m_ui.page_x2, m_ui.page_y2);
   m_bg_TabSignals.ColorBackground(CONTROLS_DIALOG_COLOR_CLIENT_BG);
   m_bg_TabSignals.ColorBorder(clrRed);
   this.Add(m_bg_TabSignals);

   m_bg_TabSettings.Create(NULL, Name("bgSettings"), 0,
                           m_ui.page_x1, m_ui.page_y1, m_ui.page_x2, m_ui.page_y2);
   m_bg_TabSettings.ColorBackground(CONTROLS_DIALOG_COLOR_CLIENT_BG);
   m_bg_TabSettings.ColorBorder(clrAqua);
   this.Add(m_bg_TabSettings);

   StyleTabButtons();
   return true;
}

//+------------------------------------------------------------------+
//| Style tabs                                                        |
//+------------------------------------------------------------------+
void CPanelSignal::StyleTabButtons()
{
// inactive base
   m_btn_TabSignals.Color(clrWhite);
   m_btn_TabSignals.ColorBackground(C'70,70,70');

   m_btn_TabSettings.Color(clrWhite);
   m_btn_TabSettings.ColorBackground(C'70,70,70');
}

//+------------------------------------------------------------------+
//| Add label helper                                                  |
//+------------------------------------------------------------------+
void CPanelSignal::AddLabel(CLabel &lbl, const string objName, const string text, int x1, int y1, int w, int h)
{
   lbl.Create(NULL, Name(objName), 0, x1, y1, x1 + w, y1 + h);
   lbl.Text(text);
   lbl.FontSize(InpPanelFontSize);
   lbl.Color(InpPanelTxtColor);
   this.Add(lbl);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CPanelSignal::AddSignalLabel(CLabel &lbl, const string objName, int x1, int y1, int w, int h)
{
   lbl.Create(NULL, Name(objName), 0, x1, y1, x1 + w, y1 + h);
   lbl.Text("-");
   lbl.FontSize(InpPanelFontSize);
   lbl.Color(InpPanelTxtColor);
   this.Add(lbl);
}

//+------------------------------------------------------------------+
//| Build Signals tab                                                  |
//+------------------------------------------------------------------+
bool CPanelSignal::BuildTabSignals()
{
// Top of page
   int y = Y0();
   const int x = X0();

// AutoTrade button (Signals tab only)
   const int bw = (this.Width() - 2 * m_ui.page_pad) - 20;
   const int bh = 36;

   m_btn_AutoTrade.Create(NULL, Name("btnAutoTrade"), 0,
                          x, y,
                          x + bw, y + bh);
   m_btn_AutoTrade.FontSize(InpPanelFontSize);
   this.Add(m_btn_AutoTrade);
   UpdateAutoTradeButton();

// Global TF & Symbol labels BELOW the button (as requested)
   y = y + bh + 8;

   AddLabel(m_lbl_CurrentPeriod, "lblGlobalTF", "Current Timeframe: -", x, y, bw, m_ui.h);
   y += m_ui.row_h;

   AddLabel(m_lbl_CurrentSymbol, "lblGlobalSymbol", "Current Symbol: -", x, y, bw, m_ui.h);
   y += m_ui.row_h + 10;

// Table headers now inside page (no more clipping under tabs)
   const int headerY = y;
   AddLabel(m_lbl_Header_tradeExecutePeriod, "lblHeadertradeExecutePeriod", TimeframeToString(inpEntryPeriod), XCol(1), headerY, 60, m_ui.h);
   AddLabel(m_lbl_Header_tradeAnalysisPeriod, "lbHeadertradeAnalysisPeriod", TimeframeToString(inpTopdownPeriod), XCol(1) + 75, headerY, 30, m_ui.h);

// First data row starts one row below headers
   const int baseY = headerY + m_ui.row_h;

   enum Rows { ROW_BASELINE = 0, ROW_CONF1, ROW_CONF2, ROW_VOLUME, ROW_ATR };

   AddLabel(m_lbl_BaseLine, "lblBaseline", "Baseline", XCol(0), YRow(baseY, ROW_BASELINE), m_ui.lbl_w, m_ui.h);
   AddSignalLabel(m_lbl_Baseline_Signal, "lblBaselineSignal", XCol(1), YRow(baseY, ROW_BASELINE), m_ui.sig_w, m_ui.h);

   AddLabel(m_lbl_1stConfirmation, "lblConf1", "1st Confirmation", XCol(0), YRow(baseY, ROW_CONF1), m_ui.lbl_w, m_ui.h);
   AddSignalLabel(m_lbl_1stConfirmation_Signal, "lblConf1Signal", XCol(1), YRow(baseY, ROW_CONF1), m_ui.sig_w, m_ui.h);

   AddLabel(m_lbl_2ndConfirmation, "lblConf2", "2nd Confirmation", XCol(0), YRow(baseY, ROW_CONF2), m_ui.lbl_w, m_ui.h);
   AddSignalLabel(m_lbl_2ndConfirmation_Signal, "lblConf2Signal", XCol(1), YRow(baseY, ROW_CONF2), m_ui.sig_w, m_ui.h);

   AddLabel(m_lbl_Volume, "lblVolume", "Volume", XCol(0), YRow(baseY, ROW_VOLUME), m_ui.lbl_w, m_ui.h);
   AddSignalLabel(m_lbl_Volume_Signal, "lblVolumeSignal", XCol(1), YRow(baseY, ROW_VOLUME), m_ui.sig_w, m_ui.h);

   AddLabel(m_lbl_ATR, "lblATR", "ATR", XCol(0), YRow(baseY, ROW_ATR), m_ui.lbl_w, m_ui.h);
   AddSignalLabel(m_lbl_ATR_Signal, "lblATRSignal", XCol(1), YRow(baseY, ROW_ATR), m_ui.sig_w, m_ui.h);

// Set globals now
   UpdateGlobals();

   return true;
}

//+------------------------------------------------------------------+
//| Build Settings tab                                                 |
//+------------------------------------------------------------------+
bool CPanelSignal::BuildTabSettings()
{
   int y = Y0();
   int xL = XCol(0);
   int xC = XCol(1);

   const int wLbl = m_ui.lbl_w;
   const int wCtl = m_ui.sig_w;
   const int hCtl = 20;

// Risk Mode
   AddLabel(m_lbl_RiskMode, "lblRiskMode", "Risk Mode", xL, y, wLbl, m_ui.h);

   m_cb_RiskMode.Create(NULL, Name("cbRiskMode"), 0, xC, y, xC + wCtl, y + hCtl);
// Add items to combobox [3](https://www.mql5.com/en/docs/standardlibrary/controls/ccombobox/ccomboboxadditem)[4](https://www.mql5.com/en/docs/standardlibrary/controls/ccombobox)
   m_cb_RiskMode.AddItem("Fixed % Risk", 0);
   m_cb_RiskMode.AddItem("Fixed Lot",    1);
   m_cb_RiskMode.AddItem("Balance Tier", 2);
   m_cb_RiskMode.Select(0);
   this.Add(m_cb_RiskMode);
   y += m_ui.row_h;

// Entry Mode
   AddLabel(m_lbl_EntryMode, "lblEntryMode", "Entry Mode", xL, y, wLbl, m_ui.h);

   m_cb_EntryMode.Create(NULL, Name("cbEntryMode"), 0, xC, y, xC + wCtl, y + hCtl);
   m_cb_EntryMode.AddItem("Market", 0);
   m_cb_EntryMode.AddItem("Limit",  1);
   m_cb_EntryMode.AddItem("Stop",   2);
   m_cb_EntryMode.Select(0);
   this.Add(m_cb_EntryMode);
   y += m_ui.row_h;

// Risk %
   AddLabel(m_lbl_RiskPct, "lblRiskPct", "Risk %", xL, y, wLbl, m_ui.h);

   m_ed_RiskPct.Create(NULL, Name("edRiskPct"), 0, xC, y, xC + wCtl, y + hCtl);
   m_ed_RiskPct.FontSize(InpPanelFontSize);
   m_ed_RiskPct.Text(DoubleToString(m_risk_pct, 2));
   this.Add(m_ed_RiskPct);
   y += m_ui.row_h;

// ATR multiplier
   AddLabel(m_lbl_ATRMult, "lblATRMult", "ATR Multiplier", xL, y, wLbl, m_ui.h);

   m_ed_ATRMult.Create(NULL, Name("edATRMult"), 0, xC, y, xC + wCtl, y + hCtl);
   m_ed_ATRMult.FontSize(InpPanelFontSize);
   m_ed_ATRMult.Text(DoubleToString(m_atr_mult, 2));
   this.Add(m_ed_ATRMult);

// Initial sync
   SyncSettingsFromControls();

   return true;
}

//+------------------------------------------------------------------+
//| Set active tab (show/hide groups)                                 |
//+------------------------------------------------------------------+
void CPanelSignal::SetActiveTab(const int tab_index)
{
   m_active_tab = tab_index;

   if(m_active_tab == 0)
      {
      m_btn_TabSignals.ColorBackground(C'20,100,20');
      m_btn_TabSettings.ColorBackground(C'70,70,70');

      m_bg_TabSignals.Show();
      m_bg_TabSettings.Hide();

      // Signals tab show
      m_btn_AutoTrade.Show();
      m_lbl_CurrentPeriod.Show();
      m_lbl_CurrentSymbol.Show();

      m_lbl_Header_tradeExecutePeriod.Show();
      m_lbl_Header_tradeAnalysisPeriod.Show();

      m_lbl_BaseLine.Show();
      m_lbl_1stConfirmation.Show();
      m_lbl_2ndConfirmation.Show();
      m_lbl_Volume.Show();
      m_lbl_ATR.Show();

      m_lbl_Baseline_Signal.Show();
      m_lbl_1stConfirmation_Signal.Show();
      m_lbl_2ndConfirmation_Signal.Show();
      m_lbl_Volume_Signal.Show();
      m_lbl_ATR_Signal.Show();

      // Settings tab hide
      m_lbl_RiskMode.Hide();
      m_lbl_EntryMode.Hide();
      m_lbl_RiskPct.Hide();
      m_lbl_ATRMult.Hide();
      m_cb_RiskMode.Hide();
      m_cb_EntryMode.Hide();
      m_ed_RiskPct.Hide();
      m_ed_ATRMult.Hide();
      }
   else
      {
      m_btn_TabSignals.ColorBackground(C'70,70,70');
      m_btn_TabSettings.ColorBackground(C'20,100,20');

      m_bg_TabSignals.Hide();
      m_bg_TabSettings.Show();

      // Signals tab hide
      m_btn_AutoTrade.Hide();
      m_lbl_CurrentPeriod.Hide();
      m_lbl_CurrentSymbol.Hide();

      m_lbl_Header_tradeExecutePeriod.Hide();
      m_lbl_Header_tradeAnalysisPeriod.Hide();

      m_lbl_BaseLine.Hide();
      m_lbl_1stConfirmation.Hide();
      m_lbl_2ndConfirmation.Hide();
      m_lbl_Volume.Hide();
      m_lbl_ATR.Hide();

      m_lbl_Baseline_Signal.Hide();
      m_lbl_1stConfirmation_Signal.Hide();
      m_lbl_2ndConfirmation_Signal.Hide();
      m_lbl_Volume_Signal.Hide();
      m_lbl_ATR_Signal.Hide();

      // Settings tab show
      m_lbl_RiskMode.Show();
      m_lbl_EntryMode.Show();
      m_lbl_RiskPct.Show();
      m_lbl_ATRMult.Show();
      m_cb_RiskMode.Show();
      m_cb_EntryMode.Show();
      m_ed_RiskPct.Show();
      m_ed_ATRMult.Show();
      }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update AutoTrade button style                                     |
//+------------------------------------------------------------------+
void CPanelSignal::UpdateAutoTradeButton()
{
   if(m_auto_trade_on)
      {
      m_btn_AutoTrade.Text("AUTO TRADING ON");
      m_btn_AutoTrade.Color(clrWhite);
      m_btn_AutoTrade.ColorBackground(clrDarkGreen);
      }
   else
      {
      m_btn_AutoTrade.Text("AUTO TRADING OFF");
      m_btn_AutoTrade.Color(clrWhite);
      m_btn_AutoTrade.ColorBackground(clrDarkRed);
      }
}

//+------------------------------------------------------------------+
//| Update global TF & Symbol labels                                  |
//+------------------------------------------------------------------+
void CPanelSignal::UpdateGlobals()
{
   const string strTFValue = TimeframeToString((ENUM_TIMEFRAMES)Period());
   const string strSymbolValue   = _Symbol;

   m_lbl_CurrentPeriod.Text("Current Timeframe: " + strTFValue);
   m_lbl_CurrentSymbol.Text("Current Symbol: " + strSymbolValue);

}

//+------------------------------------------------------------------+
//| Set trade signal label (clean)                                    |
//+------------------------------------------------------------------+
void CPanelSignal::SetTradeSignal(CLabel &lbl, const int pos)
{
   // Default
   lbl.Color(InpPanelTxtColor);

   switch(pos)
      {
      case -2:
         lbl.Color(clrRed);
         lbl.Text("Sell");
         break;

      case -1:
         lbl.Color(clrRed);
         lbl.Text("+Sell");
         break;

      case 1:
         lbl.Color(clrLime);
         lbl.Text("+Buy");
         break;

      case 2:
         lbl.Color(clrLime);
         lbl.Text("Buy");
         break;

      default:
         lbl.Text("No Trade");
         break;
      }

}
//+------------------------------------------------------------------+
//| CheckSignal updates (called by your EA logic)                      |
//+------------------------------------------------------------------+
void CPanelSignal::CheckSignal()
{
// Get signal values

// Update globals in case symbol/period changed
   UpdateGlobals();
   ChartRedraw(0);
}

void CPanelSignal::UpdateFromContext(const TradeContext &ctx)
{
   SetTradeSignal(m_lbl_Baseline_Signal, ctx.BaselineExec.trend);
   SetTradeSignal(m_lbl_1stConfirmation_Signal, ctx.Confirm.Signal);
   SetTradeSignal(m_lbl_2ndConfirmation_Signal, ctx.Confirm.Trend);
   m_lbl_Volume_Signal.Text(EnumToString(ctx.Volume.State));
   m_lbl_ATR_Signal.Text(DoubleToString(ctx.ATR.Value, 2));
   UpdateGlobals();
   ChartRedraw(0);
   /* Inside your EA:
   
      TradeContext ctx;
      if(engine.BuildTradeContext(ctx, _Symbol))
      {
         panel.UpdateFromContext(ctx);
      }
   */
}

//+------------------------------------------------------------------+
//| Read double from edit safely                                      |
//+------------------------------------------------------------------+
double CPanelSignal::ReadDouble(const CEdit & ed, const double fallback) const
{
   string s = ed.Text();
   StringTrimLeft(s);
   StringTrimRight(s);
   if(s == "")
      return fallback;
   return StringToDouble(s);
}

//+------------------------------------------------------------------+
//| Sync Settings from controls                                       |
//+------------------------------------------------------------------+
void CPanelSignal::SyncSettingsFromControls()
{
// ComboBox current selection value [4](https://www.mql5.com/en/docs/standardlibrary/controls/ccombobox)
   m_risk_mode  = (int)m_cb_RiskMode.Value();
   m_entry_mode = (int)m_cb_EntryMode.Value();

   m_risk_pct = ReadDouble(m_ed_RiskPct, m_risk_pct);
   m_atr_mult = ReadDouble(m_ed_ATRMult, m_atr_mult);

   ValidateAndFixEdits();
}

//+------------------------------------------------------------------+
//| Validate & fix edit fields (simple guardrails)                    |
//+------------------------------------------------------------------+
void CPanelSignal::ValidateAndFixEdits()
{
// Risk %: clamp 0.01 .. 100
   if(m_risk_pct < 0.01)
      m_risk_pct = 0.01;
   if(m_risk_pct > 100)
      m_risk_pct = 100;

// ATR multiplier: clamp 0.1 .. 50
   if(m_atr_mult < 0.1)
      m_atr_mult = 0.1;
   if(m_atr_mult > 50)
      m_atr_mult = 50;

// Write back formatted
   m_ed_RiskPct.Text(DoubleToString(m_risk_pct, 2));
   m_ed_ATRMult.Text(DoubleToString(m_atr_mult, 2));
}

//+------------------------------------------------------------------+
//| Chart event handler                                               |
//+------------------------------------------------------------------+
void CPanelSignal::PanelChartEvent(const int id,
                                   const long & lparam,
                                   const double & dparam,
                                   const string & sparam)
{
// Let the dialog/control system process events first [1](https://www.mql5.com/en/docs/standardlibrary/controls)
   ChartEvent(id, lparam, dparam, sparam);

   if(InpDebug)
      Print("Event id=", id, " sparam=", sparam);

// Tab switching + AutoTrade click
   if(id == CHARTEVENT_OBJECT_CLICK)
      {
      if(sparam == Name("tabSignals"))
         {
         SetActiveTab(0);
         return;
         }
      if(sparam == Name("tabSettings"))
         {
         SetActiveTab(1);
         return;
         }

      if(sparam == Name("btnAutoTrade"))
         {
         /* Auto‑Trade Button Should Toggle Engine State ONLY
         ✅ This should be propagated to TradeEngine:
            Code: 
            engine.SetAutoTrade(m_auto_trade_on);
         */
         m_auto_trade_on = !m_auto_trade_on;
         UpdateAutoTradeButton();
         ChartRedraw(0);
         return;
         }
      }

// Handle edit end edit to validate fields (CEdit supports ENDEDIT handling) [5](https://www.mql5.com/en/docs/standardlibrary/controls/cedit)
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
      {
      if(sparam == Name("edRiskPct") || sparam == Name("edATRMult"))
         {
         SyncSettingsFromControls();
         ChartRedraw(0);
         return;
         }
      }

// For combo boxes, their internal events are handled by the control system; we can just sync
// on common user interactions to keep stored values up-to-date.
   if(id == CHARTEVENT_OBJECT_CLICK || id == CHARTEVENT_OBJECT_CHANGE)
      {
      // only sync if we're on settings tab (optional optimization)
      if(m_active_tab == 1)
         SyncSettingsFromControls();
      }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
