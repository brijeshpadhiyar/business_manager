# 03 — Daily Workshop Operations & UX Plan (Phase B)

**Primary Persona:** Garment workshop owner's father operating StitchFlow one-handed on a 360dp–412dp Android phone in Gujarati (`ગુજરાતી`) or English, amidst fast-paced cutting, stitching, embroidery, ironing, and packing handoffs.  
**Core Rule:** Every speed improvement MUST preserve 100% of StitchFlow's existing stock invariants (`StockCalculator`), locked historical rates (`MemberProcessRateResolver`), locked billing rules (`LabourCalculator`), atomic transactions (`DatabaseTransactionRunner`), and `clientRequestId` idempotency. **Never perform silent or automatic business transactions.**

---

## 1. Current Workflow Audit (What V1.1 Already Does Well vs. Remaining Friction)

| Workflow | Existing V1.1 Strength | Daily Friction Remaining for V1.2 |
| :--- | :--- | :--- |
| **Dashboard (`DashboardPage`)** | Clean Navy-Teal hero banner, 7 Quick Action buttons, 4 all-time Stock KPIs, 4 all-time Financial KPIs, Process-wise Pending card, Recent Activity. | 1. Shows **all-time** totals only — father cannot see **Today's** issued, returned, labour earned, or payments at a glance.<br>2. No **Important Pending Work** list with 1-tap `Return`.<br>3. Process-wise Pending rows are non-tappable.<br>4. No 1-tap `Daily Summary`, `Pending Work`, or `Worker Ledger` shortcut. |
| **Issue Stock (`StockIssuePage`)** | 4-step single-flow + Step 5 Success, `In Stock Only` filter, Process/Worker chips, live rate & billing preview, `+10/+25/+50/All` chips, over-stock guard. | 1. No **recent `(Process, Worker)` or recent Stock suggestions** — defaults blindly to `procs.first` and `activeAssigned.first`.<br>2. No confirmation dialog for **unusual/high-risk actions** (e.g., issuing 100% of available stock or rate override). |
| **Receive Return (`ReceiveReturnPickerPage` & `StockSettlementPage`)** | Worker/Process chips, live Remaining Pending bar, `All Good` chip, Lost vs. Shortage helpers, mandatory reason guard, Consequences card, Step 5 Next-Process shortcut. | 1. Picker only sorts newest-first (oldest delayed work is buried at the bottom!).<br>2. No pending-age badges (`3d`, `7d+`) or route pre-filters (`?workerId=&processId=`).<br>3. Settlement screen has only `All Good` — no `Half`, `+10`, `+25`, or "Fill Remaining as Good" shortcut after typing damaged/lost.<br>4. Next-process shortcut jumps to Stock Issue without suggesting which active processes haven't been run yet on that colour. |
| **Worker Detail (`WorkerDetailPage`)** | Profile, assigned processes, current & historical rates, links to Ledger & Payment. | **Major Gap:** Explicitly omits live worker pending stock, open issues, earned labour, and outstanding balance! Father has to open 2 separate screens to answer *"How many pieces does Ramesh have right now and how much do I owe him?"* |
| **Daily Production Summary** | Not yet built. | No fast 1-tap daily recap screen for evening workshop review (Today / Yesterday / Any Date). |

---

## 2. B1 — Redesigned Daily Workshop Dashboard

### 2.1 Visual Hierarchy (Anti-Overcrowding Layout for 360dp Phones)
To deliver richer daily insight **without overcrowding**, we organize `DashboardPage` into **5 scannable sections** (replacing the 8-tile all-time wall):

1. **Compact Branded Hero Header:**
   - Displays StitchFlow logo, Workshop Name (`nameEn` / `nameGu`), today's IST date (`dd MMM yyyy`), Refresh button, and a compact **Lock Now** icon button (visible only when PIN lock is enabled).
2. **Primary Quick Actions Bar (5 High-Frequency Workshop Buttons):**
   - Primary row (high contrast): **`Issue Stock`** (Primary Navy) + **`Receive Return`** (Secondary Teal).
   - Compact pill row (`Wrap`, >=48dp touch targets): **`Pending Work`** (`/stock/return`), **`Worker Ledger`** (`/accounting`), **`Daily Summary`** (`/daily-summary`), plus compact **`Reports`** (`/reports`).
   - *(Processes and Inventory remain 1 tap away via AppBar/Drawer and Quick Dock overflow, keeping the fold clean on 360dp!)*
3. **"Today's Workshop" Card (IST Business Day `00:00–23:59`):**
   - Header: *"Today's Workshop"* + 1-tap *"View Summary ->"* link to `/daily-summary`.
   - 2×2 (mobile) / 4-column (tablet+) high-contrast `AppMetricTile` grid:
     - **Issued Today** (`todayIssuedQty` pcs)
     - **Good Returned Today** (`todayReceivedGoodQty` pcs, green tone)
     - **Labour Earned Today** (`todayLabourEarnedPaise`, formatted `₹`, payable entries only)
     - **Payments Today** (`todayPaymentsPaise`, regular + advance net paid today)
   - Conditional warning chip inside card ONLY when `todayDamagedQty + todayLostQty + todayShortageQty > 0`: *"Damaged / Lost Today: X pcs"*.
4. **Live Workshop Status & Important Pending Work:**
   - **Compact 2×2 Status Strip** (tappable):
     - **Available Good Stock** (taps -> Stock Live Balances)
     - **Pending w/ Workers** (taps -> Pending Returns)
     - **Outstanding Payable** (taps -> Accounting Overview; with Advance Credit subtitle if > 0)
     - **Damaged Stock** (taps -> Damaged Repair)
   - **Important Pending Work Card** (Top 3–5 open issues prioritized by **oldest pending age**, then **largest remaining quantity**):
     - Each row shows: `Worker • Process`, `Lot • Colour`, amber/red age badge (`4d` / `8d+`), remaining pending pcs, and a 1-tap **`Return`** button jumping straight to `/stock/return/:issueId`.
     - Footer: *"View All Pending (N)"* -> `/stock/return`.
5. **Tappable Process-Wise Pending Breakdown:**
   - Same clean card as V1.1, upgraded so tapping any process row (e.g., `Stitching — 65 pcs pending`) navigates directly to `/stock/return?processId=<id>`!
   - *(Recent Audit Activity becomes a collapsible/compact last-4-items card at the bottom so daily metrics stay above the fold.)*

### 2.2 Domain & Repository Extensions (`DashboardSnapshot`)
Extend `DashboardSnapshot` (additive fields, keeping all existing fields intact for backward compatibility with existing tests):
- `todayIstDateLabel` (`YYYY-MM-DD`)
- `todayIssuedQty` (`int`)
- `todayReceivedGoodQty` (`int`)
- `todayDamagedQty` (`int`)
- `todayLostShortageQty` (`int`)
- `todayLabourEarnedPaise` (`int`, payable non-reversed entries with `transactionAt` in Today IST)
- `todayPaymentsPaise` (`int`, active non-reversed `REGULAR + ADVANCE` payments with `transactionAt` in Today IST)
- `importantPendingIssues` (`List<OpenIssueSummary>`, top 5 sorted by `transactionAt ASC`, then `remainingPending DESC`)

All calculations execute in a pure Dart helper (`WorkshopDailyCalculator`) using `StockCalculator` and `LedgerCalculator` reversal-exclusion rules — zero logic in `DashboardCubit` or widgets.

---

## 3. B2 — Quick Stock Issue Improvements (`StockIssuePage`)

Builds directly on V1.1's 4-step + Step 5 flow without breaking any existing test or validation:

1. **Smart Recent Suggestions Strip (Top of Step 1 & Step 2):**
   - **Recent Work Pairs** (up to 3 chips in Step 2): Derived from the last 20 non-reversed `ISSUE` movements in SQLite, filtered to **currently active** process + **currently active** worker + **still actively assigned** link!
   - Example chip: `Stitching • Ramesh Bhai`. Tapping a chip selects both Process and Worker in **1 tap** and immediately previews the locked historical rate for `_transactionAtUtc`!
   - **Recent In-Stock Items** (up to 3 chips in Step 1 when picking stock): Derived from recent issued `designColourId`s that currently have `physicalAvailableInHouse > 0`.
   - **Zero Blind Auto-Issue:** Suggestions only pre-fill selection chips — the user still explicitly sees available stock, locked rate, expected labour, and taps **Confirm & Issue Stock**.
2. **Expected Labour Preview (Step 3 & Step 4):**
   - Already shows locked rate & billing mode; V1.2 highlights **Estimated Labour** (`qty × ratePaise`) prominently next to the quantity field as the user types, clearly noting whether it becomes payable immediately (`GIVEN_QTY`) or on good return (`RECEIVED_QTY`).
3. **Confirmation Guard for Unusual or Irreversible Actions:**
   - Standard normal issues keep the fast 1-tap `Confirm & Issue Stock` button (no annoying extra popups for routine entries!).
   - An explicit confirmation `AppDialog` appears ONLY when:
     - **Rate Override is enabled** (shows normal rate vs. overridden rate & reason), OR
     - **Issuing 100% of available stock** when `available >= 50` pcs (*"This will issue all X remaining pieces of Lot/Colour. Continue?"*), OR
     - **Backdated transaction** (`transactionAt` is > 7 days in the past — verifies intentional historical date).
4. **Preserve All V1.1 Safety Guarantees:**
   - Pre-issue available good stock check, over-issue block, atomic 5-point worker/process/rate validation inside `DatabaseTransactionRunner`, and `clientRequestId` idempotency remain untouched.

---

## 4. B3 — Quick Return Improvements (`ReceiveReturnPickerPage` & `StockSettlementPage`)

### 4.1 `ReceiveReturnPickerPage` Enhancements
- **Route Pre-Filtering:** Accept optional query parameters `/stock/return?workerId=...&processId=...&lotId=...` so tapping a Process row on Dashboard, a Worker on Worker Detail, or a Pending Work Notification opens the exact filtered list immediately!
- **Priority Sorting Chips:**
  - **`Oldest First`** *(New Default)* — brings delayed/aging pending work straight to the top.
  - **`Highest Pending`** — brings largest batch counts to the top.
  - **`Newest First`** — shows most recently issued batches first.
- **Pending Age Badge:** Computes IST business-day age (`todayIst - issueIstDate`):
  - `Today` (neutral), `1–2d` (info), `3–6d` (amber `pending`), `7d+` (red `damaged` tone for urgency).

### 4.2 `StockSettlementPage` Enhancements
- **Safe Quantity Shortcuts Row** (above Good Return field):
  - **`All Good (N)`** (existing V1.1 chip, preserved)
  - **`Half (N/2)`** (shown when `remainingPending >= 4`)
  - **`+10`**, **`+25`** (clamped safely to remaining pending)
  - **`Fill Remaining Good`** (appears dynamically when user enters Damaged / Lost / Shortage > 0 and `remainingAfter > 0` — e.g., out of 50 pending, father enters `2` damaged and taps `Fill Remaining Good (48)` in 1 tap!).
- **Preserve All V1.1 Safety Rules:**
  - Live Remaining Pending bar, Lost vs. Shortage helper labels, mandatory Reason check whenever `damaged + lost + shortage > 0`, locked rate & billing mode, live Consequences & Labour Earned preview, and `clientRequestId` idempotency remain 100% enforced.
- **Convenient Next-Process Issuing (Step 5 Success Screen):**
  - Existing V1.1 button *"Issue Returned Stock to Next Process"* already passes `designColourId` to `/stock/issue`.
  - V1.2 enhances Step 5 by also showing small 1-tap process shortcut chips (e.g., active processes other than the one just completed) that navigate to `/stock/issue?designColourId=...&processId=...` — **strictly dynamic from `processes` table, never hardcoded!**

---

## 5. B4 — Workshop Productivity Features

### 5.1 New Daily Production Summary Page (`/daily-summary`)
- Accessible in 1 tap from Dashboard Quick Actions, Today's Workshop card, or Daily Summary Notification.
- **Date Switcher Strip:** `Today` | `Yesterday` | `Pick Date (IST)` (clean single-tap switching).
- **Content Sections (100% IST `transactionAt` scoped, reversals excluded):**
  1. **Production KPIs:** Issued Qty, Good Returned Qty, Damaged Qty, Lost & Shortage Qty, Active Pending Qty (current).
  2. **Financial KPIs:** Labour Earned on Selected Day (`isPayable == true`), Regular Payments Paid, Advances Paid, Net Paid.
  3. **Today's Worker Activity List:** Each worker who had issues, returns, or payments on that day (issued, returned, earned, paid — tapping opens Worker Ledger).
  4. **Quick Footer Actions:** `Issue Stock`, `Receive Return`, `Open Full Daily Report` (jumps to Reports -> Daily Workshop tab with that date pre-selected!).

### 5.2 Worker-Specific Work Overview (`WorkerDetailPage`)
Upgrades `WorkerDetailPage` (which currently omits work/financial status) by inserting a live **Work & Balance Overview** card right below the worker header:
- **4 Compact KPI Badges / Tiles:**
  - **Pending Pieces** (`stockSummary.pending` pcs, open issues count)
  - **Outstanding Payable** or **Advance Credit** (color-coded clearly, never conflated)
  - **Total Earned Labour**
  - **Good Returned** (total pieces completed)
- **Open Pending Issues for This Worker (Inline Preview):**
  - Lists up to 3 active open issues for this worker with 1-tap **`Return`** button -> `/stock/return/:issueId`, plus *"View All Pending"* -> `/stock/return?workerId=:id`.
- **1-Tap Quick Actions:** `Issue Stock` (pre-selects worker when eligible), `Receive Return`, `Open Ledger`, `Record Payment`.

### 5.3 Actionable Empty States
Audit and enhance empty states across Dashboard, Daily Summary, Pending Returns, Worker Detail, and Reports so every empty state tells the workshop owner **what it means** and gives **one clear next action** in plain Gujarati and English (e.g., *"No pending work right now — all issued stock has been returned!"* + `Issue Stock` button).

---

## 6. Architecture & Files Summary (Phase B)

- **Domain (`lib/features/reports/domain/` & `lib/features/stock_movements/domain/`):**
  - `WorkshopDailyCalculator` (pure Dart calculator for IST day summary, recent `(processId, workerId)` & `designColourId` suggestions, pending-age sorting).
  - `DailyWorkshopSummary` entity + additive fields on `DashboardSnapshot`.
  - Additive `WorkerWorkOverview` bundle in `WorkerDetailCubit` (composed via `StockMovementRepository` + `AccountingRepository`, keeping zero DB imports in widgets/cubits).
- **Routes (`RoutePaths` & `app_router.dart`):**
  - Add `/daily-summary` -> `DailySummaryPage`.
  - Extend `/stock/issue` to accept optional `processId` and `workerId` query params alongside existing `designColourId`.
  - Extend `/stock/return` (`ReceiveReturnPickerPage`) to accept optional `workerId`, `processId`, `lotId` query params.
