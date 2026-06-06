# Easy Budget — iOS

A personal budgeting app built around one idea: **know your number for today.**

Set a monthly budget and a reset day. Every morning the app divides your
remaining budget by the remaining days. Log what you spend; any overage or
underspend is redistributed evenly across the rest of the cycle.

This repository contains a complete **Phase 1** implementation (no backend,
no account — all data lives on device via SwiftData).

## Requirements

- **Xcode 16+** (the project uses file-system-synchronized groups and SwiftData)
- iOS 17.0+ deployment target

## Getting started

```bash
open EasyBudget.xcodeproj
```

Select the **EasyBudget** scheme and run on an iOS 17+ simulator or device.

> Note: this machine only has the Command Line Tools installed, so the project
> was authored but not compiled here. Open it in Xcode to build and run.

## How the math works

The cycle runs from `resetDay` to the day before the next `resetDay`.

```
remaining_budget = monthly_budget - spent_before_today
days_remaining   = days from today through the last day of the cycle (inclusive)
daily_budget     = remaining_budget / days_remaining   (clamped at $0 for display)
```

Today's number is derived from spending *before* today, so it stays stable
through the day. Logging today's spend redistributes the difference across the
remaining days automatically. Recalculation runs on app launch, at cycle
rollover (a new day/cycle begins), and after every check-in.

### Edge cases handled

- **Missed days** — treated as $0 spent (no entry shows `—` in the month view).
- **Over budget** — daily number shows `$0` (never negative) with a calm amber message; spending is still tracked.
- **Reset day / rollover** — entries clear, the budget and notification settings persist, the cycle restarts.

## Project structure

```
EasyBudget/
├── App/                EasyBudgetApp.swift (entry + ModelContainer)
├── Models/             BudgetCycle, DailyEntry (SwiftData)
├── ViewModels/         HomeViewModel, CheckInViewModel, MonthViewModel
├── Views/
│   ├── Onboarding/     Welcome, SetBudget, SetResetDate, NotificationPermission
│   ├── Home/           HomeView (the hero number)
│   ├── CheckIn/        CheckInSheet (log spend + result card)
│   ├── Month/          MonthView (cycle history table)
│   └── Settings/       SettingsView
├── Services/
│   ├── BudgetCalculator.swift   pure, testable cycle math
│   ├── CycleManager.swift       rollover + reset
│   └── NotificationService.swift morning + evening local notifications
├── Utilities/          Formatters, Theme, Components
└── Assets.xcassets     AccentColor, AppIcon
```

## Notifications

- **Morning** (default 8am): "Today's budget: $94.00" — one per remaining day,
  with the projected amount baked in. Rescheduled on launch / after check-in so
  amounts stay accurate. Tapping opens the home screen.
- **Evening** (default 9pm): "How much did you spend today?" Tapping opens the
  check-in sheet directly.

Both times are configurable in Settings, and notifications can be toggled off.

## Phase 2 (not built)

Plaid bank sync is intentionally out of scope until Phase 1 ships, per the
project description. It will require a lightweight backend to hold Plaid access
tokens.
