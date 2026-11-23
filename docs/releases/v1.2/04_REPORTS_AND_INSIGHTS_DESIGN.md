# 04 — Advanced Reports, Business Insights & Export Design (Phase C)

**Objective:** Transform StitchFlow's existing 10-tab `ReportsPage` into a fast, accurate, filterable, Gujarati-safe reporting and business-insights engine grounded 100% in existing immutable SQLite records and pure Dart domain calculators.

---

## 1. Audit of Current Reports Architecture (`lib/features/reports/`)

| Current Behavior | Issue Found in Code | V1.2 Fix |
| :--- | :--- | :--- |
| `ReportsRepositoryImpl.getBusinessReports()` calls 5 separate repo methods (`getAllDesignColourBalances`, `getWorkerStockSummaries`, `getProcessStockSummaries`, `getOpenIssues`, `getMovementHistory`) | Queries entire `stock_movements` table **5 times** on every filter change or keystroke! | Fetch `stock_movements`, `labour_entries`, `payments`, `worker_ledger_adjustments`, and lookup tables **once** per query (using new v3 `transaction_at` indexes where bounded) and run a single-pass pure Dart `ReportsAnalyticsCalculator`. |
| Date filter (`fromUtcMillis`, `toUtcMillis`) only filters `damagedLostShortageMovements`, `labourEntries`, and `payments` | Worker Stock, Process Stock, and Worker Financial tabs silently ignore the selected date range! | Clearly separate **Period Flow Metrics** (filtered by `from..to` IST) from **Current Balance Snapshots** (always clearly labeled *"Current Pending"* / *"Current Outstanding Balance"*). |
| `ReportsPage` UI lacks Worker, Process, Lot, Design, Colour dropdowns and Date Presets | `ReportsCubit` already has `lotId`, `workerId`, `processId` fields that were never wired to UI controls! | Add 1-tap IST Date Presets + collapsible Filter Bar (Worker, Process, Lot, Design, Colour, Search) with active filter chips. |
| 10 flat horizontal chips | Adding Daily Report & Business Insights would make 12+ awkward chips on 360dp phones. | Organize cleanly into **6 clear Report Categories** with segmented sub-views inside Inventory & Financial categories so all 10 V1 reports remain accessible plus all new V1.2 reports! |
| No Export / Print | Deferred in V1.1 due to Gujarati shaping concerns in pure-Dart `pdf`. | Implement **Gujarati-accurate offline Print/PDF** (native Android WebView + `PrintManager` with bundled `NotoSansGujarati`) + **MIT-licensed Excel (`.xlsx`) & UTF-8 BOM `.csv`** export! |

---

## 2. C1 — The 6 Unified Report Categories

### Category 1: Daily Workshop Report
- **Purpose:** Day-by-day workshop pulse across any selected date range (default: `This Week` or `Today`).
- **Top Summary Strip:** Total Issued, Total Good Returned, Total Damaged, Total Lost + Shortage, End-of-Range Pending (current open pending), Total Labour Earned, Total Payments Paid.
- **Daily Breakdown Table / Mobile Cards** (grouped by `IstDateTimeHelper.toIstBusinessDate(transactionAt)` in `Asia/Kolkata`, newest day first):
  - IST Date (`dd MMM yyyy`)
  - Issued Qty
  - Good Returned Qty
  - Damaged Qty
  - Lost & Shortage Qty
  - Labour Earned (`₹`)
  - Payments Paid (`₹`)
- Tapping any day drills into that date's `DailySummaryPage` or movement list.

### Category 2: Worker Performance
- **Purpose:** Measure worker output, process specialization, and financial standing.
- **Per-Worker Metrics:**
  - **Period Flow (respects date/process/lot filters):** Period Issued Qty, Period Good Returned Qty, Period Damaged Qty, Period Lost/Shortage Qty, Period Labour Earned (`₹`), Period Payments Paid (`₹`).
  - **Current Standing (labeled clearly as Current):** Current Pending Qty (open issues), Current Advance Credit (`₹`), Current Outstanding Payable (`₹`).
  - **Expandable Process-Wise Productivity:** For each worker, shows breakdown by process (`Cutting: 320 good`, `Stitching: 180 good`, defect % = `damaged / (good + damaged)`).
- Tapping a worker navigates to `WorkerLedgerPage`.

### Category 3: Process Performance
- **Purpose:** Identify throughput, active workload, worker contribution, and reliable turnaround times across dynamic `processes`.
- **Per-Process Metrics:**
  - Period Issued Qty
  - Period Completed (Good Returned) Qty
  - Period Damaged / Lost / Shortage Qty
  - Current Pending Work (pcs + open issue count)
  - **Average Completion Time (Strictly Verified Formula — see Section 4):** Computed ONLY from non-reversed `ISSUE` rows that are **100% settled** (`remainingPending == 0`), where `lastSettlement.transactionAt >= issue.transactionAt`. Displayed in hours (`18.5h`) or days (`2.3d`) along with sample count `(n = 14 issues)`. Displays `—` (`N/A`) when `n == 0` so backdated or partial data never produces misleading numbers!
  - **Worker Contribution Breakdown:** Expandable list of workers who contributed to that process in the period (with piece count & % share).

### Category 4: Inventory Reports
Consolidates 4 existing/expanded inventory views via clean sub-chips inside the Inventory category:
1. **Stock Summary:** Initial Stock, Available Good Stock, In-Process (Pending w/ Workers), Damaged Bucket, Lost, Shortage (current live state respecting Lot/Design/Colour filters).
2. **Lot-Wise Stock:** Per-lot Designs, Colours, Initial Qty, Available Good, In-Process/Pending, Damaged, Lost, Shortage, and **Estimated Good Stock Cost/Value (Reference)** (`totalGoodPhysicalStock × unitPricePaise` — explicitly NOT labeled profit!).
3. **Design & Colour-Wise Stock:** Atomic SKU view (`Lot • Design • Colour`) with Available Good, Pending, Damaged, Lost, Shortage.
4. **Stock Movement History:** Full date-filtered, type-filtered, search-filtered non-reversed (plus optional "Show Reversed" toggle) ledger history with tap-to-inspect.

### Category 5: Labour & Financial Reports
Consolidates 3 financial views via clean sub-chips (100% consistent with `LedgerCalculator`):
1. **Labour Earned:** Period payable labour entries (`is_payable == 1`, excluding reversals) with Worker, Process, Lot, Qty, Locked Rate, Amount, and total summary.
2. **Worker Financial Summary:** Earned Labour (period + all-time), Adjustments Net, Regular Payments, Advances Paid, Advance Refunds, Current Outstanding Payable, Current Advance Credit.
3. **Date-Wise Payment History:** Chronological payments (`REGULAR`, `ADVANCE`, `ADVANCE_REFUND`, excluding reversed) filterable by worker, payment type, payment mode (`CASH`, `UPI`, `BANK_TRANSFER`, `CHEQUE`, `OTHER`), and date range.

### Category 6: Business Insights
Actionable, non-speculative workshop intelligence derived strictly from recorded transactions:
1. **Production Trends:** Daily (<= 31 days) or Weekly (> 31 days) dual-bar visual (`Issued` vs. `Good Returned`) rendered with a crisp StitchFlow `CustomPainter` chart (zero third-party chart package bloat, 100% Light/Dark theme aware).
2. **Period-over-Period Comparison:** Automatically compares the selected period against the **immediately preceding equal-length IST period** (e.g., *This Month vs. Previous Month*, *This Week vs. Last Week*, *Today vs. Yesterday*, or *Custom N-day window vs. Prior N-day window*):
   - Issued Qty delta (`+14%` / `-8%`)
   - Good Returned delta
   - Labour Cost delta (`₹`)
   - Damaged/Lost Rate delta (`2.1% -> 1.4%`)
   - *(Shows `"No prior data"` cleanly when previous period is 0 — never divides by zero or prints `Infinity%`!)*
3. **Process Bottlenecks:** Ranks active processes by bottleneck severity score: `(currentPendingQty > 0)` ordered by **oldest pending issue age** and **highest pending-to-completed ratio**, highlighting e.g. *"Stitching has 140 pcs pending (oldest: 6 days)"* with 1-tap jump to `/stock/return?processId=...`.
4. **Worker Productivity Trends:** Top contributors by Good Returned pieces in period + period-over-period change.
5. **Damaged & Lost Stock Trends:** Defect/loss rate `% = (Damaged + Lost + Shortage) / Total Settled` over time + top reasons recorded in `stock_movements.reason`.
6. **Labour Cost Trends:** Period labour cost trend (`₹`) broken down by Process (shows where workshop labour spend goes — explicitly labeled **"Labour Cost"**, NEVER profit/revenue!).

---

## 3. C2 — Report Filter Architecture (`ReportFilter`)

### 3.1 IST Date Presets (`IstDateRangePresets`)
All boundaries are computed strictly in **`Asia/Kolkata` (`UTC+05:30`)** from `00:00:00.000 IST` to `23:59:59.999 IST` converted to UTC epoch milliseconds:
- **`Today`**: `[today 00:00:00.000 IST, today 23:59:59.999 IST]`
- **`Yesterday`**: `[yesterday 00:00:00.000 IST, yesterday 23:59:59.999 IST]`
- **`This Week`**: Monday `00:00:00.000 IST` through Sunday `23:59:59.999 IST` (standard Indian business week)
- **`This Month`**: 1st of current IST month `00:00:00.000 IST` through last day `23:59:59.999 IST`
- **`Previous Month`**: 1st through last day of previous IST month
- **`All Time`**: `fromUtcMillis = null, toUtcMillis = null`
- **`Custom`**: User-selected IST From & To dates (validated `to >= from`)

### 3.2 Dimension Filters
- **Worker** (`workerId`) — active + historical workers with transactions
- **Process** (`processId`) — dynamic rows from `processes`
- **Lot** (`lotId`) — non-deleted lots
- **Design** (`lotDesignId`) — cascades automatically when a Lot is selected
- **Colour** (`designColourId`) — cascades automatically when a Design is selected
- **Search Query** (`searchQuery`) — debounced (250ms) so typing never triggers redundant DB queries!

---

## 4. C3 — Accuracy Rules & Exact Metric Formula Registry

### Strict Accounting Truthfulness Rules
1. **NO Fabricated Profit or Revenue:** StitchFlow does not record customer sales invoices. Reports MUST **never** display "Profit", "Margin", or "Sales Revenue".
2. **Labour Cost != Revenue:** Always label `labour_entries` totals as **"Labour Cost / Earned Labour"** (`મજૂરી ખર્ચ / કમાયેલી મજૂરી`).
3. **Inventory Value != Profit:** `totalGoodPhysicalStock × design_colours.unit_price_paise` MUST be labeled **"Reference Stock Value"** (`અંદાજિત સ્ટોક કિંમત`), never revenue or profit.
4. **Reversal Exclusion Guarantee:** Every metric uses `StockCalculator.reversedMovementIds`, `LedgerCalculator.reversedLabourIds`, `LedgerCalculator.reversedPaymentIds`, and `LedgerCalculator.reversedAdjustmentIds` — reversed rows and `REVERSAL` rows are **never** double-counted.
5. **Timestamp Semantics:** All business filtering uses `transaction_at` (the actual workshop event date/time converted to `Asia/Kolkata`), NOT `recorded_at` (system write time).
6. **Historical Rate Integrity:** Labour amounts always sum `labour_entries.amount_paise` (which locked `applied_rate_paise` and `locked_billing_mode` at `ISSUE` time) — never retroactively recalculated from current `member_process_rates`!

### Verified Formula Table

| Metric | Exact Source & Formula |
| :--- | :--- |
| **Issued Qty (Period)** | `SUM(stock_movements.quantity)` where `movement_type = 'ISSUE'`, active (not reversed), `transaction_at IN [from, to]` |
| **Good Returned Qty (Period)** | `SUM(quantity)` where `movement_type = 'RETURN_GOOD'`, active, `transaction_at IN [from, to]` |
| **Damaged Returned Qty (Period)** | `SUM(quantity)` where `movement_type = 'RETURN_DAMAGED'`, active, `transaction_at IN [from, to]` |
| **Lost & Shortage Qty (Period)** | `SUM(quantity)` where `movement_type IN ('SETTLEMENT_LOST', 'SETTLEMENT_SHORTAGE')`, active, `transaction_at IN [from, to]` |
| **Current Available Good Stock** | Delegated to `StockCalculator.calculateDesignColourBalance`: `initialQuantity - damagedBucket - totalLost - totalShortage - totalPendingWithWorkers` |
| **Current Pending Qty** | `SUM(active ISSUE qty) - SUM(active RETURN_GOOD + RETURN_DAMAGED + SETTLEMENT_LOST + SETTLEMENT_SHORTAGE)` |
| **Current Damaged Bucket** | `SUM(active RETURN_DAMAGED) - SUM(active ADJUSTMENT_DAMAGED_TO_GOOD)` |
| **Labour Earned (Period)** | `SUM(labour_entries.amount_paise)` where `is_payable = 1`, `basis_type != 'REVERSAL'`, not reversed, `transaction_at IN [from, to]` |
| **Payments Paid (Period)** | `Regular = SUM(REGULAR)`, `Advance = SUM(ADVANCE)`, `Refund = SUM(ADVANCE_REFUND)`, `Net Paid = Regular + Advance - Refund` (active, `transaction_at IN [from, to]`) |
| **Current Worker Net Balance** | Delegated to `LedgerCalculator.calculateWorkerSummary`: `EarnedLabour + AdjCredits - AdjDebits - (Regular + Advance - AdvanceRefund)` -> `Outstanding = max(0, Net)`, `AdvanceCredit = max(0, -Net)` |
| **Process Avg Completion Time** | Over all active `ISSUE` rows in process (whose final settlement falls in `[from, to]`) where `remainingPending == 0`: let `t_complete = MAX(child.transaction_at)` for active settlements of that issue. Include only pairs where `t_complete >= issue.transaction_at`. `AvgHours = MEAN((t_complete - issue.transaction_at) / 3600000.0)`. Returns `null` (`N/A`) if count == 0. |
| **Defect / Loss Rate %** | `(PeriodDamaged + PeriodLost + PeriodShortage) / (PeriodGood + PeriodDamaged + PeriodLost + PeriodShortage) × 100` (`null` if denominator == 0) |
| **Period-over-Period % Change** | `((Current - Previous) / Previous) × 100` (`null` if `Previous == 0`) |

---

## 5. C4 — Export & Print Investigation (Solving Gujarati Shaping Properly!)

### 5.1 Why V1.1 Deferred PDF/Excel Export
Pure-Dart `package:pdf` (`pw.Text`) draws glyphs one codepoint at a time without OpenType Indic GSUB/GPOS shaping (HarfBuzz). In Gujarati, words like `કારીગર`, `પ્રક્રિયા`, `સ્ટોક`, `હિસાબ`, and `રિપોર્ટ` contain left-reordering matras (`િ`), conjunct half-forms (`ક્ર`, `સ્ટ`), and reph (`ર્`) — rendering them with raw `pw.Text` produces garbled, unreadable text! Furthermore, `printing`'s `Printing.convertHtml()` was **deprecated in `printing` v5.12.0**.

### 5.2 Technical Evaluation of Export Options

| Export Need | Evaluated Approach | Gujarati Shaping Accuracy | APK Size / Dependencies | Verdict |
| :--- | :--- | :---: | :--- | :---: |
| **PDF & Print (Option A — RECOMMENDED)** | Pure Dart `ReportHtmlBuilder` + thin Kotlin `MethodChannel` (`com.brijesh.stitchflow/report_print`) using Android's native `WebView` + `PrintManager` (`createPrintDocumentAdapter`) loading bundled `NotoSansGujarati-Regular.ttf` via `file:///android_asset/` | **100% Perfect** (Android Chromium/Skia HarfBuzz engine) | **0 new pub packages, 0 MB native FFI bloat**, 100% offline, supports BOTH physical/Wi-Fi printing AND Android's native **"Save as PDF"** | **RECOMMENDED** |
| **PDF (Option B — Alternative)** | `pdf` + `printing` + `pdf_text_shaper` + `harfbuzz_ffi` | High (uses HarfBuzz FFI) | +3–5 MB native `.so` binaries, newer third-party FFI maintenance risk | Fallback only if cross-platform desktop PDF bytes required |
| **Excel `.xlsx` (RECOMMENDED)** | **`excel_plus: ^2.29.3`** (Pure Dart, **MIT license**; *alternative: `excel_community: ^2.6.2` MIT*). Reject `syncfusion_flutter_xlsio` due to commercial/community license restrictions. | **100% Perfect** (`.xlsx` stores standard UTF-8 XML; Excel / Google Sheets / LibreOffice render Gujarati natively) | Pure Dart, small footprint, multi-sheet styled workbooks, tabular numbers | **RECOMMENDED** |
| **CSV Fallback** | Pure Dart **UTF-8 with BOM (`\uFEFF`)** `.csv` exporter (zero packages!) | **100% Perfect** (UTF-8 BOM forces Microsoft Excel on Windows/Android to decode Gujarati properly instead of Latin-1!) | 0 dependencies, instant for 50,000+ rows | **RECOMMENDED (Bonus/Large-data fallback)** |

### 5.3 Implementation Details for Gujarati-Safe Print/PDF & Excel
1. **Asset Wiring for Android WebView:** Copy/reference `NotoSansGujarati-Regular.ttf` and `NotoSansGujarati-Bold.ttf` via Flutter asset path (`file:///android_asset/flutter_assets/assets/fonts/NotoSansGujarati-Regular.ttf`) in CSS `@font-face` inside `ReportHtmlBuilder`, wait for `WebViewClient.onPageFinished`, then invoke `PrintManager.print(jobName, webView.createPrintDocumentAdapter(jobName), isoA4Attributes)`.
2. **Branded Report Header:** Includes StitchFlow Workshop Name (EN/GU matching active locale), Report Title, Applied Filters & IST Date Range, Generated Timestamp (`IST`), and a truthful footer disclaimer (*"Generated offline by StitchFlow — Reference data from local workshop ledger"*).
3. **Excel Workbook Structure (`.xlsx`):**
   - Exports the currently active report category (or **"Full Multi-Sheet Workbook"** with sheets: `Daily`, `Workers`, `Processes`, `Inventory`, `Labour`, `Payments`).
   - Saves to app temp export dir (`stitchflow_exports/stitchflow_report_<type>_<IST_STAMP>.xlsx`) and shares via existing `share_plus` (WhatsApp, Drive, Files).
4. **Large Report Performance:**
   - All `.xlsx` / `.csv` / HTML string generation runs inside `Isolate.run(...)` so UI stays responsive.
   - If a report exceeds `1,000` rows, show a helpful notice suggesting Excel/CSV export instead of printing a 100-page PDF.
   - All UI tables/lists use lazy `ListView.builder` / paginated chunks rather than eager `for` loops inside a `Column`.

---

## 6. Module Structure (`lib/features/reports/`)

```text
lib/features/reports/
├── domain/
│   ├── entities/
│   │   ├── dashboard_report_entities.dart     # Extended DashboardSnapshot + DailyWorkshopSummary
│   │   ├── report_filter.dart                 # ReportFilter + ReportDatePreset + IstDateRangePresets
│   │   └── advanced_report_entities.dart      # DailyRow, WorkerPerfRow, ProcessPerfRow, InsightsBundle, PeriodComparison
│   ├── calculators/
│   │   └── reports_analytics_calculator.dart  # Pure Dart single-pass aggregator (0 Drift/Flutter imports)
│   ├── repositories/reports_repository.dart
│   └── services/report_export_service.dart    # Abstract printPdf(), exportExcel(), exportCsv()
├── data/
│   ├── repositories/reports_repository_impl.dart
│   └── services/
│       ├── report_html_builder.dart           # Pure Dart bilingual HTML template + NotoSansGujarati CSS
│       ├── android_report_print_channel.dart  # MethodChannel wrapper for Android WebView + PrintManager
│       └── excel_csv_export_service.dart      # Isolate-backed .xlsx (excel_plus) + UTF-8 BOM .csv generator
└── presentation/
    ├── bloc/reports_cubit.dart                # Manages 6 categories, presets, cascading filters, export status
    ├── pages/
    │   ├── reports_page.dart                  # 6-category hub + Export menu + Filter bar
    │   └── daily_summary_page.dart            # Fast /daily-summary screen shared with Phase B & D
    └── widgets/
        ├── report_filter_bar.dart             # IST presets + Worker/Process/Lot/Design/Colour dropdowns
        ├── report_trend_chart.dart            # Lightweight CustomPainter bar/trend visualizer (no heavy pkg)
        └── report_export_sheet.dart           # Print / Save PDF / Export Excel (.xlsx) / Export CSV bottom sheet
```
