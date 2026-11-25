# StitchFlow V1.3 – Business Workflow QA Report

**Date:** 2026-11-24  
**Test Suite:** `test/features/complete_workflow_qa_test.dart`  
**Result:** 12 / 12 Scenarios Verified & Passing

| Scenario | Workflow Verified | Key Assertions | Status |
|---|---|---|---|
| **1. Lot Creation** | Multi-design (`D-101`, `D-102`) × multi-colour (`Red`, `Blue`, `Green`, `Black`, `Yellow`) | Design totals `300 + 200 = 500 pcs` | PASS |
| **2. Colour-Only Lot** | `Red 200`, `Blue 150`, `Black 150` without explicit design | Internal `__NO_DESIGN__` hidden in UI labels; total `500 pcs` | PASS |
| **3. Worker Assignment** | `D-101 Red (200)` split: Dharmesh `60`, Ramesh `40` | Remaining Factory stock `100`, pending `100` | PASS |
| **4. Multiple Variants** | Dharmesh holds `D-101 Red (60)` + `D-101 Blue (100)` | Independent SKU tracking, zero cross-variant mixing | PASS |
| **5. Direct Worker Transfer** | Dharmesh `100` -> `60` to Packing Dept, `40` remain | `TRF-...` reference, receipt confirmation, Factory stock conserved (`0` change) | PASS |
| **6. Factory Return** | Partial return (`145` good + `5` damaged with reason) | Factory good `145`, damaged bucket `5`, worker pending updated | PASS |
| **7. Partial Split** | `500` = `300` Direct Transfer + `150` Factory Return + `50` Pending | Exact conservation: `145 + 5 + 350 = 500` | PASS |
| **8. Dynamic Pricing** | Default ₹5.00 vs agreed ₹5.90 + mandatory override reason; default updated to ₹8.00 | Historical assignment preserved at ₹5.90; immutable `process_rate_history` logged | PASS |
| **9. Charges & Deductions** | Base ₹2,950 + Extra ₹150 - Deduction ₹50 | Exact integer-paise net payable = `305000` (₹3,050.00) | PASS |
| **10. Worker Payments** | Pending -> Partial ₹1,000 (+ duplicate retry) -> Full ₹2,050 | Duplicate `clientRequestId` idempotent; outstanding `0`; status `PAID` | PASS |
| **11. End-to-End Lifecycle** | Lot -> Design/Colour -> Cutting -> Transfer -> Receipt -> Return -> Complete -> Pay | All 120 pcs back in Factory, 0 pending, ₹600 paid | PASS |
| **12. Negative Workflows** | Zero/negative qty, excess dispatch/transfer/return, missing override/damage reason, premature completion, zero payment | All rejected safely with `DomainValidationException` | PASS |
