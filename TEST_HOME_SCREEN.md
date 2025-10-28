# Home Screen Test Plan

## CRITICAL: Full Restart Required

```bash
# Stop the app completely
# Then run:
flutter run
```

**DO NOT use hot reload! Must be full restart!**

---

## Test 1: Check Console Output ✓

After app starts, look for these lines in console:

```
✅ EXPECTED:
=== HOME SCREEN: Starting _refreshFromDb ===
Retrieved X transactions from database
Current date: 2025-10-28 ... (Year: 2025, Month: 10)
Transaction: income, ₹..., date: ... (Year: 2025, Month: 10)
  ✓ Added to INCOME: ₹... (Total: ₹...)
Transaction: expense, ₹..., date: ... (Year: 2025, Month: 10)
  ✓ Added to EXPENSE: ₹... (Total: ₹...)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HOME SCREEN FINAL TOTALS:
  Income:  ₹...
  Expense: ₹...
  Balance: ₹...
  Transactions to display: X
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ State updated:
   _income = ₹...
   _expenses = ₹...
   _totalBalance = ₹...
   _transactions.length = X
```

```
❌ BAD (If you see):
Error refreshing data: ...
Retrieved 0 transactions from database
Unsupported operation: read-only
```

---

## Test 2: Verify Home Screen Display ✓

### Current Balance Card (Big Blue Card)

**Expected:**
- Shows: "Current Balance"
- Amount: Income - Expense for this month
- Example: If Income=₹11,676 and Expense=₹1,200
  - Should show: **₹10,476**

**Check:**
- [ ] Shows a number (not ₹0)
- [ ] Shows full amount (not 11K)
- [ ] Matches: Income tile - Expense tile

---

### Income Tile (Left, Green)

**Expected:**
- Label: "Income"
- Icon: Up arrow
- Amount: Sum of all income for current month

**Check:**
- [ ] Shows correct amount
- [ ] NOT showing ₹0 (unless you have no income)
- [ ] Full amount (not compact K notation)

---

### Expense Tile (Right, Red)

**Expected:**
- Label: "Expenses"
- Icon: Down arrow
- Amount: Sum of all expenses for current month

**Check:**
- [ ] Shows correct amount
- [ ] NOT showing ₹0 (unless you have no expenses)
- [ ] Full amount (not compact K notation)

---

### Transaction History List

**Expected:**
- Shows ALL transactions from database
- Newest first
- Each transaction has:
  - Icon
  - Category/Note
  - Amount
  - Time
  - Type badge (Income/Expense)

**Check:**
- [ ] All transactions visible
- [ ] Can scroll through list
- [ ] Each transaction is tappable
- [ ] Shows correct count (matches console)

---

## Test 3: Compare with Profile Screen ✓

1. **Note Home Screen values:**
   - Current Balance: ₹_______
   - Income: ₹_______
   - Expense: ₹_______

2. **Go to Profile Screen** (tap profile icon)

3. **Note Profile Screen values:**
   - Current Balance: ₹_______
   - Income: ₹_______
   - Expense: ₹_______

4. **Verify:** 
   - [ ] Home Balance = Profile Balance
   - [ ] Home Income = Profile Income
   - [ ] Home Expense = Profile Expense

**ALL THREE MUST MATCH!**

---

## Test 4: Add New Transaction ✓

1. **Tap the + button** (floating action button)
2. **Add a new expense:**
   - Type: Expense
   - Amount: ₹500
   - Category: Food
   - Date: Today

3. **Save transaction**

4. **Check Home Screen updates:**
   - [ ] Balance decreased by ₹500
   - [ ] Expense increased by ₹500
   - [ ] New transaction appears in list
   - [ ] Transaction is at the top (newest first)

5. **Check Profile Screen:**
   - [ ] Values match Home Screen

---

## Test 5: Edit Transaction ✓

1. **Tap any transaction** in the list
2. **Tap Edit button**
3. **Change amount** (e.g., ₹500 → ₹600)
4. **Save**

5. **Check updates:**
   - [ ] Balance adjusted correctly
   - [ ] Totals updated
   - [ ] Profile matches Home

---

## Test 6: Delete Transaction ✓

1. **Tap any transaction** in the list
2. **Tap Delete button**
3. **Confirm deletion**

4. **Check updates:**
   - [ ] Transaction removed from list
   - [ ] Balance updated
   - [ ] Totals recalculated
   - [ ] Profile matches Home

---

## Test 7: Pull to Refresh ✓

1. **On Home Screen, pull down** from top
2. **Release to trigger refresh**

3. **Check:**
   - [ ] Refresh indicator shows
   - [ ] Console shows "_refreshFromDb" logs
   - [ ] Values reload correctly
   - [ ] No errors in console

---

## 📊 EXPECTED RESULTS SUMMARY

### If You Have These Transactions:
```
1. Income: ₹11,676 (Salary) - Oct 28, 2025
2. Expense: ₹1,200 (Food) - Oct 28, 2025
```

### Home Screen Should Show:
```
┌─────────────────────────────────┐
│ Current Balance                 │
│ ₹10,476                        │
│                                 │
│ Income: ₹11,676  Expense: ₹1,200│
└─────────────────────────────────┘

Transactions History
────────────────────────────────
[Expense] Food          ₹1,200
6:30 PM

[Income] Salary      ₹11,676
6:25 PM
```

### Console Should Show:
```
Retrieved 2 transactions from database
  ✓ Added to INCOME: ₹11676.0 (Total: ₹11676.0)
  ✓ Added to EXPENSE: ₹1200.0 (Total: ₹1200.0)
HOME SCREEN FINAL TOTALS:
  Income:  ₹11676.0
  Expense: ₹1200.0
  Balance: ₹10476.0
✅ State updated:
   _totalBalance = ₹10476.0
```

---

## 🚨 COMMON ISSUES & SOLUTIONS

### Issue 1: Balance shows ₹0
**Solution:**
- Check console: "Retrieved X transactions"
- If X = 0, database is empty
- Add transactions first
- If X > 0 but balance = 0, check console for calculation errors

### Issue 2: Not all transactions showing
**Solution:**
- Check console: "_transactions.length = X"
- Should match "Retrieved X transactions"
- If different, share console output

### Issue 3: Values don't match Profile
**Solution:**
- Do FULL RESTART (not hot reload)
- Check console for both Home and Profile calculations
- Share screenshots of both screens

### Issue 4: "read-only" error
**Solution:**
- This should be fixed
- If still happening, share full console output
- May need to clear app data

---

## 📝 WHAT TO SHARE IF STILL NOT WORKING

**1. Full Console Output:**
```
Copy from:
"=== HOME SCREEN: Starting _refreshFromDb ==="
To:
"✅ State updated:"
```

**2. Screenshots:**
- Home Screen (full screen showing balance and transactions)
- Profile Screen (showing balance)

**3. Specific Values:**
```
Home Screen:
- Current Balance: ₹_______
- Income: ₹_______
- Expense: ₹_______
- Transactions visible: _____ (count)

Profile Screen:
- Current Balance: ₹_______
- Income: ₹_______
- Expense: ₹_______
```

**4. Any Error Messages**

---

## ✅ SUCCESS CRITERIA

All these must be TRUE:

- [x] Console shows detailed logs with ✓ markers
- [x] Current Balance = Income - Expense
- [x] Balance is NOT ₹0 (if you have transactions)
- [x] Expense is NOT ₹0 (if you have expense transactions)
- [x] All transactions visible in list
- [x] Home values = Profile values
- [x] Values update after add/edit/delete
- [x] No "read-only" errors
- [x] No exceptions in console

---

## 🎯 QUICK CHECK

**30-Second Test:**
1. Restart app → Check console for "✅ State updated"
2. Look at Home Screen → Is balance showing?
3. Tap Profile → Does balance match?

**If YES to all three:** ✅ WORKING!
**If NO to any:** Share console output and screenshots

---

**Status: Ready to Test!**
