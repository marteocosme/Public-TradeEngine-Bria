# 
**📘**** NNFX Money Management Algorithm**

**🧭**** 1. Overview**

The **No Nonsense Forex** money management model is designed to:  
    - Control downside risk through **fixed fractional risk**   
    - Secure profits early via **partial exit (scaling out)**   
    - Maximize trend gains using a **runner position**   
    - Adapt dynamically using **ATR-based volatility** 
    
**⚙️**** 2. Core Principles****
   
    📊**** 2.1 Fixed Risk Per Trade**  
    - Total risk per trade: **2% of account equity**   
    - Split into:  
        - **Order #1 → 1% risk **  
        - **Order #2 → 1% risk **
👉 Ensures:  
    - Controlled exposure  
    - Consistent position sizing
    
    **📐**** 2.2 Volatility-Based Stops (ATR)**
    All stop-loss and management rules are based on **ATR (Average True Range)**
    :**Parameter** | **Value** | :--- | :--- |
|   Initial SL | **1.5 × ATR** | 
|   TP (Order #1) | **1 × ATR** | 
|   TP (Order #2) | None (runner) | 

**🧩**** 3. Trade Structure****

📌**** Dual-Position Model**
| **Order** | **Role** | **Objective** | 
| :--- | :--- | :--- |
| **Order #1** | Scalp / Secure Profit | Lock in gains early | 
| **Order #2** | Runner | Capture extended trend | 

**🔄**** 4. Trade Lifecycle****
📊**** UML Activity Diagram (Lifecycle)**
| :--- |
| **Code \</&gt; Mermaid** | 
| flowchart TD    
    A\[Open Trade] --&gt; B\[Place Order #1 and #2]    
    B --&gt; C\[Set SL = 1.5×ATR for both]    
    C --&gt; D\[Set TP for Order #1 = 1×ATR]    
    
    D --&gt; E{Order #1 hits TP?}    
    E --&gt;\|Yes\| F\[Move Order #2 SL to Break Even]    
    E --&gt;\|No\| G\[Wait]    
    
    F --&gt; H{Order #2 Profit &gt;= 2×ATR?}    
    H --&gt;\|Yes\| I\[Activate Trailing Stop]    
    H --&gt;\|No\| G    
    
    I --&gt; J\[Trail SL at 1.5×ATR distance]    
    J --&gt; K\[Adjust every +0.5×ATR move]    
    
    K --&gt; L{Exit Condition?}    
    L --&gt;\|Yes\| M\[Close Trade]    
    L --&gt;\|No\| J | 


**💰 5. Risk Management Model****📉 5.1 Position Sizing Logic**  
    - Risk per order is calculated using:  
        - Account equity  
        - Stop-loss distance (ATR-based)
    👉 Result:  
    - Position size adjusts automatically to volatility**
    
    📌 Key Behavior**  
    - Larger ATR → smaller position size  
    - Smaller ATR → larger position size
    
**✂️ 6. Scaling Out (Partial Take Profit)**

    **📊 Mechanism**  
        - **Order #1 closes at +1×ATR **  
        - Locks in **guaranteed profit**   
        - Reduces overall trade risk
    
    **🧠 Purpose**  
        - Converts trade into **low-risk / risk-free scenario**   
        - Allows second position to run freely**📊 UML Sequence (Scaling Out)**
        
|  A |
| :--- |
| **Code \</&gt; Mermaid** | 
| sequenceDiagram    participant Market    participant Order1    participant Order2    Market-&gt;&gt;Order1: Price reaches +1×ATR    Order1--&gt;&gt;Market: Close position    Market-&gt;&gt;Order2: Adjust SL to Break Even | 
**🛡️ 7. Break-Even Mechanism****📌 Trigger**  
    - Activated **after Order #1 hits TP** **📌 Action**  
    - Move **Order #2 Stop Loss → Entry Price** **🧠 Result**  
    - Trade becomes **risk-free** **📈 8. Trailing Stop Strategy****📊 Activation Condition**  
    - When **Order #2 reaches +2×ATR profit** **⚙️ Trailing Rules**
| **Condition** | **Action** | 
| :--- | :--- |
| Profit ≥ 2×ATR | Start trailing | 
| Every +0.5×ATR | Adjust SL | 
| SL Distance | Maintain **1.5×ATR** | 
**🧠 Behavior**  
    - Locks in profits gradually  
    - Allows trend continuation  
    - Avoids premature exits**📊 UML Activity (Trailing Stop)**![Image-3](Forex Algorithm Trading Untitled Page\Forex Algorithm Trading Untitled Page_3.png)
|  A |
| :--- |
| **Code \</&gt; Mermaid** | 
| flowchart TD    A\[Order #2 Active] --&gt; B{Profit &gt;= 2×ATR?}    B --&gt;\|No\| C\[Hold Position]    B --&gt;\|Yes\| D\[Start Trailing Stop]    D --&gt; E\[Set SL = Price - 1.5×ATR]    E --&gt; F{Price Moves +0.5×ATR?}    F --&gt;\|Yes\| G\[Adjust SL]    F --&gt;\|No\| E    G --&gt; H\[Repeat Until Exit] | 
**🚪**** 9. Exit Integration****Exit Conditions (applies to runner)**  
    1. Exit indicator signal  
    1. Baseline cross  
    1. Opposite C1 signal  
    1. Stop-loss hit**📌**** Interaction with Money Management**  
    - Trailing stop works **in parallel with exit signals**   
    - Whichever triggers first → **trade closes** **🧠**** 10. Behavioral Summary****✔️**** Strengths**  
    - Converts trades into **risk-free positions early**   
    - Maximizes **trend capture potential**   
    - Fully **volatility adaptive**   
    - Reduces emotional decision-making**⚠️**** Considerations**  
    - Requires precise ATR calculation  
    - Needs accurate position sizing  
    - Trailing stop must be **state-aware** **🏗️**** 11. UML Class Design (Architecture)**![Image-4](Forex Algorithm Trading Untitled Page\Forex Algorithm Trading Untitled Page_4.png)
|  A |
| :--- |
| classDiagram    class RiskManager {        +CalculateLotSize()        +SetInitialSL()    }    class TradeManager {        +OpenOrders()        +ScaleOut()        +MoveToBreakEven()        +ApplyTrailingStop()    }    class ATR {        +GetATRValue()    }    class ExitManager {        +CheckExitConditions()    }    TradeManager --&gt; RiskManager    TradeManager --&gt; ATR    TradeManager --&gt; ExitManager | 
**🎯**** 12. Key Takeaways**  
    - NNFX money management is built on **3 phases**: **🧱**** Phase 1 — Risk Control**  
    - Fixed 2% risk  
    - ATR-based SL**✂️**** Phase 2 — Profit Securing**  
    - Scale out at **1×ATR**   
    - Move to break-even**🚀**** Phase 3 — Profit Maximization**  
    - Trail stop after **2×ATR**   
    - Let runner capture trend**🚀**** Final Insight (For Your EA)**To implement this correctly in your system:👉 You must track **trade state transitions**:OPEN → PARTIAL CLOSED → BREAK EVEN → TRAILING → EXIT👉 This is **NOT just math — it’s a state machine**
