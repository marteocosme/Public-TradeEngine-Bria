# 🚀 TradeEngine Bria (NNFX-Based EA)

TradeEngine Bria is an algorithmic trading system built in MQL5, inspired by the NNFX methodology.
It focuses on rule-based decision-making, strict risk management, and systematic validation through backtesting and forward testing.

--- 

## 🧠 Strategy Overview

This EA follows the NNFX framework:

Baseline Indicator
Confirmation Indicator
Volume / Volatility Filter
ATR-based Stop Loss & Take Profit
One trade per symbol logic
New candle execution (M15)

---

## ⚙️ Core Features
- ✅ Entry validation only on new candles
- ✅ ATR-based SL/TP
- ✅ Trade frequency control (1 trade per symbol)
- 🚧 Confirmation & baseline integration (in progress)
- 🚧 Trade management (trailing stop, scaling out)

---

## 📊 Backtesting Status
| Component | Status |
| --- | --- |
| Entry Timing	| ✅ Done |
| SL / TP Logic | ✅ Done |
| Money Management | 🚧 In Progress |
| Signal Validation |🚧 In Progress |
| Risk Management |	🚧 In Progress |


---
## 🧪 Testing Approach
- Backtesting via MT5 Strategy Tester
- Forward testing in demo environment
- Logging trade execution for validation

## 🛠 Tech Stack
- MQL5
- MetaTrader 5
- Algorithmic Trading Logic
- Data-driven testing approach

## 📌 Roadmap
 Integrate full NNFX confirmation logic
 Add trailing stop system
 Implement scaling out
 Optimize for multiple symbols
 Performance analytics dashboard (future)

---

## 👤 Author

- Developed by Marteo Cosme 
- Reporting Analyst transitioning into Algorithmic Trading & Analytics Engineering
- https://www.linkedin.com/in/marteocosme/

## License

Source-available for noncommercial use under **PolyForm Noncommercial License 1.0.0**.

Commercial use requires a separate paid license/permission — see `COMMERCIAL-LICENSE.md`.

This project separates trading logic (01_Algorithm) from software specifications (02_Specs), architecture (03_Architecture), and phased implementation (04_Implementation).


