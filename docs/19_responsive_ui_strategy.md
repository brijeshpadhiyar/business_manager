# 19 — Responsive UI Strategy

## 1. Android-First Principle

Android smartphone usability (`360dp – 430dp` width) is the **non-negotiable baseline**. Every workflow—creating a lot, issuing stock, recording a partial return with damaged/lost pieces, checking a worker's ledger, or recording an advance payment—must be fast and effortless with one hand on a phone. Tablet and desktop layouts progressively enhance screen utilization without compromising mobile ergonomics.

---

## 2. Breakpoints (`AppBreakpoints`)

| Class | Width Range | Primary Devices | Navigation Shell |
| :--- | :--- | :--- | :--- |
| **Compact (Mobile)** | `< 600 dp` | Android / iOS phones (portrait) | Bottom `NavigationBar` (4–5 primary tabs) + Drawer/More |
| **Medium (Tablet)** | `600 – 1023 dp` | Android tablets, iPads, foldables | `NavigationRail` (compact icons + labels) |
| **Expanded (Desktop)** | `>= 1024 dp` | Windows, macOS, Linux, Web desktop | Permanent collapsible left Sidebar (`NavigationDrawer`) |

---

## 3. Adaptive Component Patterns

1. **Primary Navigation (`AdaptiveShellScaffold`):**
   - Primary destinations: **Dashboard**, **Lots**, **Movements**, **Members**, **Reports / More** (Settings, Processes, Backup).
   - Preserves tab navigation state using `go_router` `StatefulShellRoute.indexedStack`.
2. **Responsive Forms:**
   - **Mobile:** Single-column vertical form (`16dp` horizontal padding, `8dp` field gaps) with sticky bottom primary action button.
   - **Tablet / Desktop:** Centered max-width container (`720dp – 960dp`) with 2-column grouped fields (e.g., Quantity + Rate side-by-side) to eliminate awkward full-width stretching.
3. **Responsive Data Tables (`AppDataTable`):**
   - **Mobile:** Compact, scannable `AppCard` list tiles showing key metrics (Lot #, Design/Colour, Pending Qty, Status Badge) with tap-to-detail.
   - **Tablet / Desktop:** Dense, sortable Material 3 `DataTable` with tabular numeric columns and inline quick-actions.
4. **Adaptive Dialogs & Bottom Sheets:**
   - **Mobile:** Quick pickers, filters, and partial-return forms open as draggable `AppBottomSheet` (easy thumb reach).
   - **Tablet / Desktop:** Same content opens as a centered constrained `AppDialog` (`maxWidth: 520dp`).
5. **Master-Detail Split View (Expanded Screens):**
   - On desktop/large tablets (`>= 1024dp`), Lot List + Lot Detail and Member List + Member Ledger can render side-by-side (`360dp` list pane + flexible detail pane), while mobile navigates push-style via `go_router`.
