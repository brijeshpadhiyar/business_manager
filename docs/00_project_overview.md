# 00 — Project Overview

## 1. Executive Summary

**Business Manager (`બિઝનેસ મેનેજર`)** is an offline-first, multi-platform Flutter application built to digitize and streamline daily production, inventory, worker assignment, labour calculation, and payment ledger operations for a garment / silai (tailoring & job-work) business.

The primary initial user is the business owner operating on a **personal Android smartphone** in an environment where internet connectivity may be unavailable or unreliable, and where rapid, error-free tracking of lots, workers (*karigars*), partial returns, historical piece rates, and worker advances is critical to daily operations.

---

## 2. Business Domain Context

In a garment / silai workshop:
- Fabric or semi-finished garments arrive or are created in numbered **Lots** (e.g., Lot `1001`).
- Each Lot contains one or more **Designs** (e.g., *Design A*, *Design B*), and each Design comes in multiple **Colours** (e.g., *Red*, *Blue*, *Black*) with specific piece counts and pricing.
- Garments pass through various **Production Processes** (e.g., *Cutting*, *Press*, *Stitching*, *Finishing*, *Packing*). The sequence is **not fixed**—different lots or designs may skip processes or execute them in different orders.
- **Workers / Members** (e.g., *Ravi Bhai*, *Darshan Bhai*, *Hasmukh Bhai*, *Rakesh Bhai*) are assigned piece quantities for specific processes and often return work in **multiple partial batches**, occasionally with damaged, lost, or missing pieces.
- Each worker can have **different piece rates per process**, and rates change over time (e.g., ₹20 until Nov 30, ₹30 from Dec 1).
- Workers frequently take **advance payments** before completing work, creating credit balances that automatically offset future earned labour.

---

## 3. Project Goals

1. **100% Offline-First Operation:** All data, photos, attachments, calculations, reports, and backups work locally with zero cloud or internet dependency.
2. **Android-First Ergonomics, Multi-Platform Readiness:** Deliver a fast, compact, thumb-friendly Android experience first while sharing a single clean Flutter codebase across iOS, Web, Windows, macOS, and Linux.
3. **Zero-Rework Financial & Inventory Integrity:** Prevent common real-world errors (over-issuing stock, over-returning stock, double-counting labour, retroactively corrupting old bills after a rate hike, or losing track of damaged/lost pieces).
4. **Complete Auditability:** Preserve immutable history with UTC timestamps displayed in `Asia/Kolkata` (IST), distinguishing actual transaction dates (`transactionAt`) from entry timestamps (`recordedAt`).
5. **Bilingual Accessibility:** First-class **English** (`Business Manager`) and **Gujarati** (`બિઝનેસ મેનેજર`) support from day one.
6. **Data Portability:** Allow the owner to export the raw `.sqlite` database for inspection in external SQLite tools, and create/restore complete `.zip` backups containing the database, photos, attachments, and metadata.

---

## 4. Scope & Non-Goals (Version 1)

### In Scope (V1)
- Lot, Design, Colour, and quantity-based inventory management with lot photos.
- Dynamic user-defined Production Processes (no hardcoded sequence).
- Worker / Member management and many-to-many process assignments.
- Effective-dated historical Member Pricing with rate locking on stock issue.
- Stock Issue, multiple Partial Returns, Damaged/Lost/Shortage settlements, and authorized Damaged-to-Good repair adjustments.
- Configurable Labour Calculation (Given vs. Received, default Pay on Received Good Quantity, optional per-process damaged inclusion).
- Member Ledger, Advance Payments, Regular Payments, Advance Refunds, and complete date-wise history.
- Operational & Financial Reports.
- Local private storage, raw `.sqlite` export, and unencrypted full `.zip` backup/restore.
- System/Light/Dark Material 3 theme, English/Gujarati localization, and `dev`/`prod` flavor isolation.

### Out of Scope (V1 — Deferred to Future Versions)
- Backend servers, REST/GraphQL APIs, Firebase, Supabase, or multi-device cloud sync.
- Online user accounts, role-based cloud authentication, or multi-tenant SaaS features.
- Complex multi-stage damaged-garment repair shop workflows (V1 supports Damaged Stock bucket + authorized repair adjustment).
- Mandatory backup encryption and app-level PIN/biometric lock (documented as future enhancements).
- Barcode/QR individual-piece serialization (inventory is strictly quantity-based).

---

## 5. Domain Glossary

| Term | Definition |
| :--- | :--- |
| **Lot** | A numbered production batch (e.g., `1001`) grouping designs, colours, quantities, and reference photos. |
| **Design + Colour (SKU Unit)** | The atomic quantity-tracked inventory unit within a Lot (e.g., `Lot 1001 / Design A / Red: 100 pcs`). |
| **Process** | A dynamic, user-defined production operation (e.g., Cutting, Stitching, Press) with no hardcoded order. |
| **Member (Worker / Karigar)** | A person who performs one or more processes and earns piece-rate labour. |
| **Stock Issue (`ISSUE`)** | Handing over a quantity of good in-house pieces to a Member for a specific Process. |
| **Partial Return / Settlement** | Returning or settling pieces against a specific `ISSUE` (`RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE`). |
| **Physical Available In-House** | Surviving good pieces currently in the workshop and eligible to be issued to a process. |
| **Damaged Stock Bucket** | Segregated count of pieces returned damaged; excluded from good available stock until an authorized repair adjustment is recorded. |
| **Locked Rate** | The historical member-process rate captured at `ISSUE` time (based on `transactionAt` in IST) and inherited by all partial returns of that issue. |
| **Advance Credit** | Negative pending payable balance representing advance money paid to a Member ahead of earned labour. |
| **Paise** | Integer sub-unit of Indian Rupee (`100 paise = ₹1.00`) used for exact monetary storage. |
