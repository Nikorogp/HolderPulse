💡 HolderPulse
==============

Contract Overview
-----------------

The `HolderPulse` Clarity smart contract (originally named `TokenBehavioralAnalytics`) implements a sophisticated **Behavioral Analysis System** for token holders. Its core purpose is to **track, score, and flag** holder activities based on metrics like transfer volume, frequency, holding duration, and consistency. This system is vital for **maintaining healthy token economics**, identifying **suspicious behaviors** (e.g., wash trading), and accurately **rewarding loyal, long-term holders**.

* * * * *

🛠️ Function Reference
----------------------

I've categorized the functions to provide a clear understanding of contract interactions and accessibility.

### 🌐 Public Functions (State Modifying)

These functions require a transaction, change the contract's state, and are restricted to the `contract-owner` to ensure data integrity and system control.

| Function | Parameters | Description |
| --- | --- | --- |
| `register-holder` | `(holder principal)` | Initializes a new profile in the `holder-profiles` map for a given principal. **Owner-only.** |
| `record-transfer` | `(holder principal) (recipient principal) (amount uint) (transfer-type (string-ascii 20))` | Records a transfer event, updates the holder's profile, aggregates daily activity, and recalculates the **risk and loyalty scores**. **Owner-only.** |
| `analyze-holder-behavior-advanced` | `(holder principal) (time-window uint) (include-predictions bool)` | Generates a deep, multi-metric behavioral report, including velocity metrics, composite risk assessment, holder tier, and optional predictive insights. **Owner-only.** |

* * * * *

### 🔒 Private Functions (Internal Logic)

These functions are callable only by other functions within the contract and handle the complex scoring and flagging logic internally.

| Function | Parameters | Description |
| --- | --- | --- |
| `max` | `(a uint) (b uint)` | Helper to return the greater of two `uint` values. |
| `min` | `(a uint) (b uint)` | Helper to return the smaller of two `uint` values. |
| `calculate-risk-score` | `(holder principal)` | Computes the holder's risk score based on volume, frequency, and active behavior flags. |
| `calculate-loyalty-score` | `(holder principal)` | Computes the holder's loyalty score based on holding duration, consistency, and balanced activity. |
| `check-rapid-trading` | `(holder principal) (day uint)` | Checks the daily activity logs to determine if the holder has exceeded the `max-transfers-per-day` threshold. |
| `update-behavior-flags` | `(holder principal) (amount uint)` | Sets or unsets specific behavior flags (e.g., `rapid-trading`, `whale-activity`, `dormant-reactivation`) based on the most recent activity. |

* * * * *

### 🔎 Read-Only Functions (On-Chain Data Access)

These functions can be called by anyone without a transaction to safely retrieve calculated metrics and global data from the contract state.

| Function | Parameters | Description |
| --- | --- | --- |
| `get-holder-profile` | `(holder principal)` | Retrieves the holder's full profile, including scores, volumes, and activity timestamps. |
| `get-behavior-flags` | `(holder principal)` | Retrieves the current boolean status of all specific behavioral flags for a holder. |
| `get-transfer-details` | `(holder principal) (transfer-id uint)` | Retrieves the details of a specific recorded transfer. |
| `get-daily-activity` | `(holder principal) (day uint)` | Retrieves the aggregated transfer count and total volume for a holder on a specific day. |
| `get-global-analytics` | (None) | Retrieves contract-wide summary data, such as `total-holders` and `total-flagged-holders`. |

* * * * *

📊 Scoring Overview
-------------------

The analysis system operates on two core scoring metrics:

### 🚨 Risk Score

The Risk Score identifies potential suspicious activity. Scores ≥u75 result in the holder being **flagged** (`is-flagged: true`). The score aggregates points from high volume transfers, high transfer frequency, and specific pattern flags (e.g., `suspicious-pattern` from concurrent rapid trading and large volume).

![Image of a simple risk meter with zones labeled low, medium, and high](https://encrypted-tbn2.gstatic.com/licensed-image?q=tbn:ANd9GcRFZQQ2gmEkFpVQJ2F3ylhUHdwp-0MkxAOgBxGakkRj3prt1m5Rm6qGCR-53blED7Q8SYGgzOUdTygneRC7bCK1dWjnD62qpamnXN3Qkx1WM5sr1Fo)

Shutterstock

Explore

### 🏅 Loyalty Score

The Loyalty Score measures long-term commitment. It weights **holding duration** (up to u40 points), **hold consistency** (up to u30 points), and a **balanced activity level** (up to u30 points). High loyalty scores place the holder in desirable tiers, such as **Gold** (≥u60) or **Platinum** (≥u80).

* * * * *

⚖️ MIT License
--------------

```
MIT License

Copyright (c) 2025 HolderPulse

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

* * * * *

🤝 Contribution and Security
----------------------------

I welcome community contributions to further enhance the behavioral detection models.

### Contributing

1.  **Fork** the repository.

2.  Develop your feature on a new branch.

3.  Ensure all changes are thoroughly tested and comply with Clarity best practices.

4.  Submit a Pull Request with a clear description of your contribution.

### Security

Please report any security vulnerabilities confidentially to `security@example.com` (placeholder) immediately, following responsible disclosure guidelines. This contract has not yet been formally audited and should be considered **experimental**.
