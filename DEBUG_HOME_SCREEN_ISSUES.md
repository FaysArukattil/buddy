# Debug Home Screen Issues

## Date: October 28, 2025, 6:15 PM IST
## Status: 🔍 DEBUGGING IN PROGRESS

---

## Issues Identified from Images

### Image 1: Profile Screen
- **Current Balance:** ₹10,476 ✅ (Correct: ₹11,676 - ₹1,200 = ₹10,476)
- **Income:** ₹11,676 ✅
- **Expense:** ₹1,200 ✅
- **Status:** Profile screen is working correctly!

### Image 2: Home Screen
- **Current Balance:** ₹11,676 ❌ (Should be ₹10,476)
- **Income:** ₹11,676 ✅
- **Expense:** ₹0 ❌ (Should be ₹1,200)
- **Transactions:** Only showing 1 transaction ❌ (Should show all)

---

## Root Cause Analysis

### Issue 1: Expense Showing ₹0
**Possible Causes:**
1. Expense transaction has different date (not current month)
2. Type field in database is not exactly "expense"
3. Date parsing issue

### Issue 2: Only 1 Transaction Showing
**Possible Causes:**
1. Database only has 1 transaction
2. Other transactions filtered out
3. UI rendering issue

### Issue 3: Balance Calculation Wrong
**Cause:** If expense is ₹0, then balance = ₹11,676 - ₹0 = ₹11,676 (wrong!)
**Should be:** ₹11,676 - ₹1,200 = ₹10,476

---

## Debug Steps Added

### Added Debug Logging
```dart
// Debug: Print transaction details
debugPrint('Transaction: type=$type, amount=$amt, date=${dt.toString()}, currentMonth=${now.month}, txMonth=${dt.month}');

// Current month totals only
if (dt.year == now.year && dt.month == now.month) {
  if (type == 'income') {
    monthIncome += amt;
    debugPrint('Added to income: $amt, total: $monthIncome');
  } else if (type == 'expense') {
    monthExpense += amt;
    debugPrint('Added to expense: $amt, total: $monthExpense');
  }
}

debugPrint('Final totals - Income: $monthIncome, Expense: $monthExpense, Balance: ${monthIncome - monthExpense}');
debugPrint('Total transactions to display: ${rows.length}');
```

---

## How to Debug

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Check Console Output
Look for debug messages like:
```
Transaction: type=income, amount=11676.0, date=2025-10-28..., currentMonth=10, txMonth=10
Added to income: 11676.0, total: 11676.0
Transaction: type=expense, amount=1200.0, date=2025-10-28..., currentMonth=10, txMonth=10
Added to expense: 1200.0, total: 1200.0
Final totals - Income: 11676.0, Expense: 1200.0, Balance: 10476.0
Total transactions to display: 2
```

### Step 3: Identify the Problem
**If expense transaction shows different month:**
```
Transaction: type=expense, amount=1200.0, date=2025-09-28..., currentMonth=10, txMonth=9
```
This means the expense was added with September date, not October!

**If type is not "expense":**
```
Transaction: type=Expense, amount=1200.0, ...
```
The type might be capitalized or have spaces.

---

## Expected vs Actual

### Expected Console Output
```
Transaction: type=income, amount=11676.0, date=2025-10-28 18:11:00.000, currentMonth=10, txMonth=10
Added to income: 11676.0, total: 11676.0
Transaction: type=expense, amount=1200.0, date=2025-10-28 18:15:00.000, currentMonth=10, txMonth=10
Added to expense: 1200.0, total: 1200.0
Final totals - Income: 11676.0, Expense: 1200.0, Balance: 10476.0
Total transactions to display: 2
```

### Actual Console Output
(Need to check when app runs)

---

## Possible Fixes

### Fix 1: If Date is Wrong
The expense transaction might have been saved with wrong date.

**Solution:** Delete and re-add the expense transaction with today's date.

### Fix 2: If Type is Wrong
The type field might not be exactly "expense" (could be "Expense" or have spaces).

**Solution:** Update database to ensure type is lowercase:
```dart
final type = (r['type'] as String?)?.toLowerCase().trim() ?? '';
```
(Already implemented)

### Fix 3: If Only 1 Transaction in Database
The database might actually only have 1 transaction.

**Solution:** Add the expense transaction again.

---

## Verification Steps

### After Running with Debug Logs

1. **Open the app**
2. **Pull to refresh on home screen**
3. **Check console for debug output**
4. **Identify which scenario matches:**

#### Scenario A: Expense has wrong month
```
Transaction: type=expense, amount=1200.0, txMonth=9 (not 10)
```
**Fix:** The expense was added in September, not October. Add it again with October date.

#### Scenario B: Expense has wrong type
```
Transaction: type=Expense, amount=1200.0
```
**Fix:** Type is capitalized. The `.toLowerCase()` should handle this, but check database.

#### Scenario C: Only 1 transaction exists
```
Total transactions to display: 1
```
**Fix:** Database only has 1 transaction. Add the expense transaction.

---

## Next Steps

1. ✅ **Debug logs added** - Check console output
2. ⏳ **Run app and check logs** - Identify root cause
3. ⏳ **Apply appropriate fix** - Based on scenario
4. ⏳ **Verify fix works** - Check home screen matches profile screen

---

## Code Changes Made

### File: `home_screen.dart` (Lines 90-106)

**Added debug logging to identify:**
- Transaction type
- Transaction amount  
- Transaction date
- Current month vs transaction month
- Running totals
- Final totals

---

## Expected Result After Fix

### Home Screen Should Show:
- **Current Balance:** ₹10,476 (₹11,676 - ₹1,200)
- **Income:** ₹11,676
- **Expense:** ₹1,200
- **Transactions:** All transactions visible

### Should Match Profile Screen:
- ✅ Same Current Balance
- ✅ Same Income
- ✅ Same Expense
- ✅ All transactions visible

---

## Status: 🔍 AWAITING DEBUG OUTPUT

Please run the app and check the console output to identify the root cause.

**Next Action:** Share the console debug output to determine the exact fix needed.

---

**END OF DOCUMENT**
