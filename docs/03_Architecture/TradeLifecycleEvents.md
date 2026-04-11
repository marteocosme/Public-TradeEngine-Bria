
## 🔹 1. Pre‑Trade Events
### ✅ MM_TradeValidated
When

- MM confirms that risk, SL distance, and lot sizing are valid

Emitted by

- Risk & Position Sizing Module

Required Data

- Symbol
- Intended entry price
- Stop‑loss distance
- Risk %
- Calculated lot size
- Validation result (pass/fail)

📌 If this event does not occur, the trade must not open.

### ❌ MM_TradeRejected
When

- Trade fails MM validation (invalid SL distance, lot < min, risk exceeded)

Terminal

- Yes (trade never existed)

Required Data

- Rejection reason (enum/string)
- Failed invariant


## 🔹 2. Trade Initialization Events
✅ MM_TradeOpened
When

Broker confirms trade is open and MM accepts responsibility

Required Data

- Ticket
- Entry price
- Initial SL
- Initial risk (currency + R)
- Lot size

✅ This event marks the true start of the MM lifecycle.

## 🔹 3. Active Management Events
These events may occur zero or more times, but always under strict rules.

### 🔁 MM_BreakEvenTriggered
When

- Profit threshold is met
- BE conditions satisfied
- BE not yet applied

Rules

- Emits once per trade
- Irreversible

Required Data

- Trigger condition (R / price / ATR)
- Old SL
- New SL
- Buffer amount (if any)


### 🔁 MM_StopLossAdjusted
When

- Stop‑loss is modified for reasons other than BE
(e.g., trailing logic if/when enabled)

Rules

- Must never increase risk
- Must move in a favorable direction only

Required Data

- Adjustment reason
- Old SL
- New SL

📌 This keeps BE and trailing conceptually separate.

### 🔁 MM_PartialCloseExecuted
When

- A scale‑out condition is met
- Partial close is executed successfully

Rules

- Finite
- Ordered
- Must respect lot constraints

Required Data

- Closed lot size
- Remaining lot size
- Scale‑out level / index
- Execution price


## 🔹 4. Trade Termination Events
These are terminal events.

### ✅ MM_ExitSignalReceived
When

- Entry Strategy emits an exit signal
- MM acknowledges and prepares exit

Required Data

- Exit signal source
- Exit reason (enum)
- Market context snapshot (optional)

📌 Useful for diagnosing why an exit happened.

🛑 MM_TradeClosed
When

- Trade is fully closed and confirmed by broker

Terminal

- Yes

Required Data

- Close price
- Close reason (SL / exit signal / final scale‑out)
- Total R result
- Total P/L

📌 This event ends all MM actions.

## 🔹 5. Safety & Exceptional Events

### ⚠️ MM_SafetyTriggered
When

- Any invariant is threatened or violated
- Emergency exit or halt required

Examples

- Risk breach
- Inconsistent trade state
- Broker rejection loop

Terminal

- Usually yes


## 🔐 Event Authority & Ownership Matrix

| Event | Owner | Can Modify Trade? |
| --- | --- | --- |
| MM_TradeValidated |MM | ❌ |
| MM_TradeOpened | MM | ✅ |
| MM_BreakEvenTriggered | MM | ✅ |
| MM_StopLossAdjusted | MM | ✅ |
| MM_PartialCloseExecuted | MM | ✅ | 
| MM_ExitSignalReceived | Strategy → MM | ❌ |
| MM_TradeClosed | MM | ❌ |
| MM_TradeRejected | MM | ❌ |
| MM_SafetyTriggered | MM | ✅ |
This prevents responsibility leakage later.