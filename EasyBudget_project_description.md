# Easy Budget — iOS Budgeting App

## Project Description for Claude Code

---

## Overview

Easy Budget is a personal budgeting iOS app built around a single core mechanic: a monthly budget that self-corrects every day. The user sets a monthly spending budget, picks their reset date (e.g. payday), and the app divides the remaining budget by the remaining days each morning. At the end of each day, the user logs what they spent. Any overage or underspend is redistributed evenly across the remaining days of the month. Every morning, a push notification tells them exactly how much they can spend today.

The philosophy: don't track every category, don't obsess over charts — just know your number for the day.

---

## Tech Stack

**Recommended: Swift \+ SwiftUI (native iOS)**

- Best-in-class push notification support via `UserNotifications` framework  
- Native feel, best performance  
- Local data persistence with SwiftData (or Core Data)  
- No backend required for Phase 1  
- Phase 2 bank sync via Plaid will require a lightweight backend (Node.js or Swift Vapor)

---

## Phase 1 — Core App (Build First)

### Onboarding Flow

1. **Welcome screen** — brief explanation of the concept (one sentence: "Know your number for today.")  
2. **Set monthly budget** — single number input (e.g. $3,000)  
3. **Set reset date** — day of the month the budget resets (1–28; default: 1st). Label it "payday or billing cycle start."  
4. **Enable notifications** — request permission for daily morning push. Explain what it sends: "Your daily budget for today: $94."  
5. Done — go straight to the home screen.

### Home Screen

The home screen has one job: show today's number, prominently.

**Layout (top to bottom):**

- Date (small, muted) — e.g. "Tuesday, June 10"  
- Label: "Available today"  
- Large display number — today's daily budget (e.g. **$94.00**)  
- Secondary line: "X days left in cycle · $Y remaining this month"  
- CTA button: "Log today's spending" (opens the check-in sheet)  
- Small link: "View this month" (goes to month view)

**Visual state variants:**

- Normal: neutral/calm color  
- Under budget (surplus carried forward): soft green accent  
- Over budget (deficit carried forward): soft amber/orange accent — never alarming red, just a gentle warning

### Daily Check-in (End-of-Day)

Triggered by:

1. User tapping "Log today's spending" on home screen  
2. Evening push notification at a user-set time (default: 9pm) — "How much did you spend today?"

**Check-in sheet:**

- Large number input — dollar amount spent today  
- Optional: note field (e.g. "groceries \+ gas")  
- Confirm button: "Done"  
- On confirm: recalculate and show a brief result card:  
  - If under: "Nice. You saved $X — spread across your remaining Y days."  
  - If over: "You went $X over. Adjusting your daily budget for the rest of the month."

### Budget Recalculation Logic

remaining\_budget \= monthly\_budget \- total\_spent\_this\_cycle

days\_remaining \= reset\_date \- today (accounting for month length)

daily\_budget \= remaining\_budget / days\_remaining

This recalculation runs:

- After every daily check-in  
- At midnight (new day begins)  
- On app launch

Edge cases to handle:

- User misses a day: treat as $0 spent (or prompt to fill in retroactively)  
- Budget goes negative: show $0 daily, display deficit message, still track  
- Reset date: clear spent total, keep budget setting, restart cycle

### Morning Push Notification

- Time: user-configurable (default: 8am)  
- Content: "Today's budget: $\[amount\]"  
- No other content — keep it dead simple  
- Tap opens the app to home screen

### Evening Push Notification

- Time: user-configurable (default: 9pm)  
- Content: "How much did you spend today?"  
- Tap opens directly to the check-in sheet

### Month View

A simple scrollable list of the current cycle's days:

| Day | Budget | Spent | \+/- |
| :---- | :---- | :---- | :---- |
| Jun 1 | $97 | $112 | \-$15 |
| Jun 2 | $92 | $80 | \+$12 |
| ... |  |  |  |

- Days with no entry show "—" for spent  
- Current day highlighted  
- Footer: "Monthly budget: $X · Spent so far: $Y · Remaining: $Z"

### Data Model (SwiftData)

// BudgetCycle

\- id: UUID

\- monthlyBudget: Double

\- resetDay: Int (1–28)

\- createdAt: Date

// DailyEntry

\- id: UUID

\- date: Date

\- amountSpent: Double

\- note: String?

\- dailyBudgetAtTime: Double  // snapshot of what budget was that day

\- cycleId: UUID

All data stored locally on device. No account, no login, no server in Phase 1\.

### Settings Screen

- Monthly budget (editable)  
- Reset date (editable) — with warning: "Changing this will restart your current cycle"  
- Morning notification time  
- Evening notification time  
- Toggle notifications on/off  
- "Reset this cycle" (destructive, confirmation required)

---

## Phase 2 — Plaid Bank Sync (Build After Phase 1 Ships)

Do not build Phase 2 until Phase 1 is complete and tested.

### What Plaid Enables

Instead of manually entering daily spend, the app pulls transactions from the user's connected bank/credit card automatically. The daily check-in becomes a review step ("here's what we found — confirm?") rather than a manual entry.

### Architecture Changes Required

Phase 2 requires a backend because Plaid tokens cannot be stored client-side securely.

**Recommended backend: Node.js \+ Express (or Swift Vapor)**

- Endpoints:  
  - `POST /link` — create Plaid Link token  
  - `POST /exchange` — exchange public token for access token  
  - `GET /transactions` — fetch transactions for date range  
- Store: access tokens in a database (PostgreSQL or SQLite), keyed by a device ID or anonymous user ID (no email/login required if you want to stay anonymous)  
- Host: Railway, Fly.io, or Render (free tiers available)

**Plaid integration steps (iOS side):**

1. Add `LinkKit` (Plaid iOS SDK) via Swift Package Manager  
2. On "Connect Bank" tap: call backend `/link`, get Link token, launch Plaid Link flow  
3. On success: send public token to backend `/exchange`, backend stores access token  
4. Daily: backend fetches yesterday's transactions, returns sum to app  
5. App pre-fills the check-in with the pulled total; user can adjust before confirming

**Plaid account:**

- Sign up at dashboard.plaid.com  
- Use Sandbox environment for development (free, fake data)  
- Switch to Development/Production when ready to test with real banks  
- Required products: `transactions`

### UI Changes for Phase 2

- Settings: add "Connect your bank" section with Plaid Link button  
- Check-in sheet: if bank connected, show "Pulled from bank: $X" pre-filled, with "Edit" option  
- If pull fails (network, pending transactions): fall back to manual entry gracefully  
- Clearly label which transactions were auto-pulled vs manually entered in month view

---

## UI/UX Principles

- **One number at a time.** The home screen should never feel cluttered. The daily number is the hero.  
- **Calm, not alarming.** Going over budget happens. The app should be matter-of-fact, not stressful. Avoid red, avoid language like "warning" or "exceeded."  
- **Minimal friction for check-in.** Logging spend should take under 10 seconds. Number pad, one tap to confirm.  
- **No accounts, no cloud (Phase 1).** Privacy-first. Data lives on the device.  
- **Dark mode support.** Required from day one.

---

## File/Folder Structure (SwiftUI)

Easy Budget/

├── App/

│   └── Easy BudgetApp.swift

├── Models/

│   ├── BudgetCycle.swift

│   └── DailyEntry.swift

├── ViewModels/

│   ├── HomeViewModel.swift

│   ├── CheckInViewModel.swift

│   └── MonthViewModel.swift

├── Views/

│   ├── Onboarding/

│   │   ├── WelcomeView.swift

│   │   ├── SetBudgetView.swift

│   │   ├── SetResetDateView.swift

│   │   └── NotificationPermissionView.swift

│   ├── Home/

│   │   └── HomeView.swift

│   ├── CheckIn/

│   │   └── CheckInSheet.swift

│   ├── Month/

│   │   └── MonthView.swift

│   └── Settings/

│       └── SettingsView.swift

├── Services/

│   ├── BudgetCalculator.swift

│   └── NotificationService.swift

└── Resources/

    └── Assets.xcassets

---

## Build Order for Claude Code

Execute in this order to avoid dependency issues:

1. Data models (`BudgetCycle`, `DailyEntry`) \+ SwiftData setup  
2. `BudgetCalculator` service — pure logic, testable in isolation  
3. `NotificationService` — scheduling morning \+ evening notifications  
4. Onboarding flow (4 screens)  
5. `HomeView` \+ `HomeViewModel`  
6. `CheckInSheet` \+ `CheckInViewModel`  
7. `MonthView`  
8. `SettingsView`  
9. Edge case handling (missed days, negative budget, cycle reset)  
10. Polish: animations, haptics, dark mode, dynamic type support

---

## Success Criteria for Phase 1

- [ ] User can set a monthly budget and reset date  
- [ ] App correctly calculates daily budget for any day in the cycle  
- [ ] Daily check-in recalculates and redistributes remaining budget  
- [ ] Morning push notification fires at configured time with correct amount  
- [ ] Evening push notification fires at configured time  
- [ ] Month view shows full cycle history  
- [ ] App handles missed days gracefully  
- [ ] App handles going over monthly budget gracefully (shows $0, not crash)  
- [ ] Full dark mode support  
- [ ] Data persists across app restarts

