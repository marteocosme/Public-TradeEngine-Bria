# 📘 NNFX Trade Entry Strategy & Algorithm
**📘 ****NNFX Trading System****Algorithm Documentation ****1. System Overview**The **No Nonsense Forex** is a **rule-based, indicator-driven trading framework** designed to:  
    - Eliminate discretionary decisions  
    - Standardize trade execution  
    - Use volatility-based risk management  
    - Operate on **confirmed candle closes** **🧩**** 2. System Components****📊**** Indicators**
| **Component** | **Purpose** | 
| :--- | :--- |
| **ATR** | Volatility measurement (SL, TP, distance rules) | 
| **Baseline** | Defines trend direction | 
| **C1 (Main Confirmation)** | Primary entry signal | 
| **C2 (Secondary Confirmation)** | Signal validation | 
| **V1 (Volume/Volatility)** | Market strength filter | 
| **Exit Indicator** | Trade exit signal | 
| *(Optional)* Continuation Indicator | Used for trend continuation entries | 
**⚙️**** 3. Core Trading Principles****3.1 Candle-Based Execution**  
    - All decisions are made **only at candle close**   
    - Prevents noise and false signals**3.2 Rule-Based Validation System**The algorithm enforces **three critical filters**:
| **Filter Type** | **Rule** | 
| :--- | :--- |
| **Location** | Price must be near baseline (R1: ≤ 1×ATR) | 
| **Timing** | Signal must be recent (R3: ≤ 7 candles) | 
| **Synchronization** | Indicators must align within 1 candle | 
**3.3 Multi-Path Entry System**The system evaluates **four distinct entry strategies**:  
    1. Standard Entry  
    1. Baseline Cross Entry  
    1. Pullback Entry  
    1. Continuation Entry  
    **1. System Overview**  
    The **No Nonsense Forex** is a **rule-based, indicator-driven trading framework** designed to:  
        - Eliminate discretionary decisions  
        - Standardize trade execution  
        - Use volatility-based risk management  
        - Operate on **confirmed candle closes**   
      
    **🧩**** 2. System Components**  
    **📊**** Indicators**  
>
| **Component** | **Purpose** | 
| :--- | :--- |
| **ATR** | Volatility measurement (SL, TP, distance rules) | 
| **Baseline** | Defines trend direction | 
| **C1 (Main Confirmation)** | Primary entry signal | 
| **C2 (Secondary Confirmation)** | Signal validation | 
| **V1 (Volume/Volatility)** | Market strength filter | 
| **Exit Indicator** | Trade exit signal | 
| *(Optional)* Continuation Indicator | Used for trend continuation entries | 
  
      
    **⚙️**** 3. Core Trading Principles**  
    **3.1 Candle-Based Execution**  
        - All decisions are made **only at candle close**   
        - Prevents noise and false signals  
      
    **3.2 Rule-Based Validation System**  
    The algorithm enforces **three critical filters**:  
>
| **Filter Type** | **Rule** | 
| :--- | :--- |
| **Location** | Price must be near baseline (R1: ≤ 1×ATR) | 
| **Timing** | Signal must be recent (R3: ≤ 7 candles) | 
| **Synchronization** | Indicators must align within 1 candle | 
  
      
    **3.3 Multi-Path Entry System**  
    The system evaluates **four distinct entry strategies**:  
        1. Standard Entry  
        1. Baseline Cross Entry  
        1. Pullback Entry  
        1. Continuation Entry  
    **🔄**** 4. Entry Decision Flow****📊**** High-Level Flow**![Image-1](📘 NNFX Trade Entry Strategy & Algorithm\📘 NNFX Trade Entry Strategy & Algorithm_1.png)
|  A |
| :--- |
| **Code \</&gt; Mermaid** | 
| flowchart TD A\[New Candle] --&gt; B{Open Trade Exists?} B --&gt;\|Yes\| Z\[Do Nothing] B --&gt;\|No\| C{Evaluate Entry Types} C --&gt; D\[Standard Entry] C --&gt; E\[Baseline Entry] C --&gt; F\[Pullback Entry] C --&gt; G\[Continuation Entry] D --&gt;\|Valid\| H\[Enter Trade] E --&gt;\|Valid\| H F --&gt;\|Valid\| H G --&gt;\|Valid\| H D --&gt;\|Invalid\| E E --&gt;\|Invalid\| F F --&gt;\|Invalid\| G | 
**📈**** 5. Entry Strategies****✅**** 5.1 Standard Entry****Trigger:** C1 signal**Conditions:**  
    - Baseline agrees with direction  
    - Price within **1×ATR** of baseline *(R1)*   
    - C2 confirms  
    - Volume confirms**🔄**** 5.2 Baseline Cross Entry****Trigger:** Price crosses baseline**Conditions:**  
    - C1 agrees  
    - Price within **1×ATR** *(R1)*   
    - C2 confirms  
    - Volume confirms  
    - C1 signal occurred within **7 candles** *(R3: Bridge Too Far)* **🔁**** 5.3 Pullback Entry****Trigger:** Trend already established**Phase 1:**  
    - Baseline gives signal  
    - Price moves **beyond 1×ATR** **Phase 2 (Next Candle):**  
    - Price returns within **1×ATR**   
    - All indicators align**🚀**** 5.4 Continuation Entry****Trigger:** Existing trend continuation**Conditions:**  
    - Prior entry signal exists  
    - Baseline has not been crossed since  
    - Continuation signal (or C1) appears  
    - C1, Baseline, and C2 agree**📏**** 6. Rule Definitions****📐**** R1 — Distance Rule**  
    - Price must be **within 1×ATR of baseline**   
    - Prevents late entries**🌉**** R3 — Bridge Too Far Rule**  
    - C1 signal must be **≤ 7 candles old**   
    - Prevents outdated signals**⏱️**** 1 Candle Rule**  
    - All confirmations must align within **1 candle**   
    - Otherwise, signal is invalid**💰**** 7. Trade Execution &amp; Risk Management****7.1 Position Structure**Each trade consists of **two positions**:
| **Order** | **Risk** | **SL** | **TP** | 
| :--- | :--- | :--- | :--- |
| **Order #1** | 1% | 1.5×ATR | 1×ATR | 
| **Order #2** | 1% | 1.5×ATR | No TP (runner) | 
**7.2 Trade Management Flow**![Image-2](📘 NNFX Trade Entry Strategy & Algorithm\📘 NNFX Trade Entry Strategy & Algorithm_2.png)
|  A |
| :--- |
| **Code \</&gt; Mermaid** | 
| flowchart TD    A\[Trade Opened] --&gt; B\[Order #1 hits TP]    B --&gt; C\[Move Order #2 SL to Break Even]    C --&gt; D{Profit &gt;= 2×ATR?}    D --&gt;\|Yes\| E\[Start Trailing SL at 1.5×ATR]    D --&gt;\|No\| F\[Continue Holding]    E --&gt; G\[Adjust SL every +0.5×ATR]    G --&gt; H\[Let Trade Run] | 
**🚪**** 8. Exit Strategy**A trade is closed when **any** of the following occurs:**Exit Conditions**  
    1. Exit indicator gives signal  
    1. Price crosses baseline  
    1. C1 gives **opposite signal** **📊**** Exit Flow**  
>![Image-3](📘 NNFX Trade Entry Strategy & Algorithm\📘 NNFX Trade Entry Strategy & Algorithm_3.png)  
      
>
|  A |
| :--- |
| **Code \</&gt; Mermaid** | 
| flowchart TD A\[Trade Active] --&gt; B{Exit Condition Met?} B --&gt;\|Yes\| C\[Close Trade] B --&gt;\|No\| D\[Continue Trade] | 
  
    **🧠**** 9. System Behavior Summary****✔️**** Strengths**  
    - Fully systematic (ideal for automation)  
    - Volatility-adaptive (ATR-based)  
    - Multi-entry flexibility  
    - Strong trend-following logic**⚠️**** Constraints**  
    - Requires strict rule adherence  
    - Performance depends on indicator selection  
    - Needs extensive backtesting (baseline + C1 combinations)**🏗️**** 10. Conceptual UML (Architecture View)**![Image-4](📘 NNFX Trade Entry Strategy & Algorithm\📘 NNFX Trade Entry Strategy & Algorithm_4.png)
|  A |
| :--- |
| **Code \</&gt; Mermaid** | 
| classDiagram    class NNFXEngine {        +EvaluateEntry()        +ManageTrade()        +CheckExit()    }    class Baseline    class ConfirmationC1    class ConfirmationC2    class VolumeV1    class ATR    class ExitIndicator    NNFXEngine --&gt; Baseline    NNFXEngine --&gt; ConfirmationC1    NNFXEngine --&gt; ConfirmationC2    NNFXEngine --&gt; VolumeV1    NNFXEngine --&gt; ATR    NNFXEngine --&gt; ExitIndicator | 
**🎯**** 11. Key Takeaways**  
    - NNFX is a **decision framework**, not a single strategy   
    - Entry depends on **context (4 entry types)**   
    - Success depends heavily on:  
        - Indicator selection  
        - Strict rule enforcement  
        - Proper risk management**🚀**** Final Insight (For Your EA Project)**To implement NNFX correctly, your system must:  
    1. Support **multiple entry pathways**   
    1. Enforce **R1 + R3 + 1 Candle Rule**   
    1. Maintain **state awareness** (for continuation trades)   
    1. Separate:  
        - Entry logic  
        - Trade management  
        - Exit logic
