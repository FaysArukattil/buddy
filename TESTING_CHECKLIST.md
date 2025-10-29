# ✅ Testing Checklist - Auto Transaction Detection

## 🎯 Pre-Testing Setup

### Environment Check:
- [ ] Flutter SDK installed and updated
- [ ] Android device/emulator ready
- [ ] USB debugging enabled (for physical device)
- [ ] Android Studio / VS Code ready

### Build Check:
- [ ] Run `flutter pub get` - ✅ Already done
- [ ] Run `flutter analyze` - Check for errors
- [ ] No compilation errors

---

## 📱 Installation Testing

### Step 1: Install App
```bash
flutter run
```

**Expected Result:**
- [ ] App installs successfully
- [ ] No crash on startup
- [ ] Database initializes (check logs for "✅ MAIN: Database initialized")
- [ ] Notification service attempts initialization

**Logs to Check:**
```
✅ MAIN: Database initialized
✅ DATABASE: Upgraded to version 2 - Added auto-detection fields
⚠️ MAIN: Notification permission not granted. User needs to enable it in settings.
```

---

## 🔐 Permission Testing

### Step 2: Grant Notification Permission

**Actions:**
1. [ ] Open app
2. [ ] Navigate to Profile tab
3. [ ] Scroll to "Auto Transaction Detection" section
4. [ ] Tap "Notification Permission" button
5. [ ] Android settings should open
6. [ ] Find "Buddy" in the list
7. [ ] Enable notification access
8. [ ] Return to app

**Expected Result:**
- [ ] Settings open correctly
- [ ] "Buddy" appears in notification access list
- [ ] Can enable permission
- [ ] App shows confirmation when returning

**Logs to Check:**
```
🔔 NOTIFICATION: Requesting notification access...
✅ NOTIFICATION: Permission already granted (after enabling)
```

---

## ⚙️ Settings Testing

### Step 3: Enable Auto-Detection

**Actions:**
1. [ ] In Profile screen, find "Auto-Detect Transactions" toggle
2. [ ] Toggle should be OFF initially (or ON if permission already granted)
3. [ ] Tap toggle to turn ON
4. [ ] Should see confirmation snackbar

**Expected Result:**
- [ ] Toggle switches smoothly
- [ ] Snackbar shows "Auto-detection enabled"
- [ ] Setting persists after app restart

**Logs to Check:**
```
🎧 NOTIFICATION: Starting notification listener...
✅ NOTIFICATION: Listener started successfully
```

### Step 4: Disable Auto-Detection

**Actions:**
1. [ ] Toggle OFF
2. [ ] Should see confirmation snackbar

**Expected Result:**
- [ ] Toggle switches to OFF
- [ ] Snackbar shows "Auto-detection disabled"
- [ ] Listener stops

**Logs to Check:**
```
🛑 NOTIFICATION: Listener stopped
```

---

## 🧪 Transaction Detection Testing

### Test Case 1: Simple Debit Transaction

**Test SMS:**
```
Your A/C 1234 debited by Rs.500 for shopping
```

**How to Send:**
- Option 1: Send from another phone
- Option 2: Use ADB command:
```bash
adb shell service call notification 1
```

**Expected Result:**
- [ ] Transaction appears in Home screen
- [ ] Amount: 500.00
- [ ] Type: Expense
- [ ] Category: Other or Shopping
- [ ] Note contains original notification text
- [ ] Auto-detected flag set

**Logs to Check:**
```
📬 NOTIFICATION: Received from com.google.android.apps.messaging
   Title: [Bank Name]
   Content: Your A/C 1234 debited by Rs.500 for shopping
🤖 DATABASE: Auto-inserting transaction: expense ₹500.0 from com.google.android.apps.messaging
✅ DATABASE: Auto-transaction saved with ID: [number]
✅ NOTIFICATION: Auto-transaction added successfully!
   Type: expense
   Amount: ₹500.0
   Category: Other
```

---

### Test Case 2: Credit Transaction

**Test SMS:**
```
Your A/C 5678 credited with Rs.2000 via UPI from John
```

**Expected Result:**
- [ ] Transaction appears in Home screen
- [ ] Amount: 2000.00
- [ ] Type: Income
- [ ] Category: Other
- [ ] Note contains original notification text

**Logs to Check:**
```
✅ NOTIFICATION: Auto-transaction added successfully!
   Type: income
   Amount: ₹2000.0
```

---

### Test Case 3: Shopping Transaction (Category Detection)

**Test SMS:**
```
Rs.1250 debited for Amazon purchase
```

**Expected Result:**
- [ ] Transaction appears
- [ ] Amount: 1250.00
- [ ] Type: Expense
- [ ] Category: **Shopping** (auto-detected from "Amazon")
- [ ] Icon: Shopping bag icon

**Logs to Check:**
```
   Category: Shopping
```

---

### Test Case 4: Food Transaction

**Test SMS:**
```
Payment of Rs.450 to Swiggy successful
```

**Expected Result:**
- [ ] Category: **Food** (auto-detected from "Swiggy")
- [ ] Icon: Restaurant icon

---

### Test Case 5: Transport Transaction

**Test SMS:**
```
Rs.300 paid to Uber for ride
```

**Expected Result:**
- [ ] Category: **Transport** (auto-detected from "Uber")
- [ ] Icon: Car icon

---

### Test Case 6: Amount with Commas

**Test SMS:**
```
Your account debited by Rs.1,25,500 for property purchase
```

**Expected Result:**
- [ ] Amount: 125500.00 (commas removed correctly)
- [ ] Type: Expense

---

### Test Case 7: Rupee Symbol

**Test SMS:**
```
₹750 debited from your account
```

**Expected Result:**
- [ ] Amount: 750.00
- [ ] Type: Expense

---

### Test Case 8: INR Format

**Test SMS:**
```
INR 999 debited for Netflix subscription
```

**Expected Result:**
- [ ] Amount: 999.00
- [ ] Category: Entertainment (detected "Netflix")

---

## 🔄 Duplicate Prevention Testing

### Test Case 9: Duplicate Detection

**Actions:**
1. [ ] Send same SMS twice:
```
Your A/C debited by Rs.100 for test
```
2. [ ] Wait 5 seconds
3. [ ] Send exact same message again

**Expected Result:**
- [ ] First message creates transaction
- [ ] Second message is ignored
- [ ] Only ONE transaction in database

**Logs to Check:**
```
✅ DATABASE: Auto-transaction saved with ID: 1
⚠️ NOTIFICATION: Duplicate transaction detected, skipping
```

---

## ❌ Negative Testing

### Test Case 10: Invalid Notification (No Amount)

**Test SMS:**
```
Your OTP is 123456
```

**Expected Result:**
- [ ] No transaction created
- [ ] App doesn't crash

**Logs to Check:**
```
⏭️ NOTIFICATION: No transaction detected in message
```

---

### Test Case 11: Invalid Notification (No Keywords)

**Test SMS:**
```
Hello, how are you? Rs.500
```

**Expected Result:**
- [ ] No transaction created (no debit/credit keywords)

**Logs to Check:**
```
⏭️ NOTIFICATION: No transaction detected in message
```

---

### Test Case 12: Non-Financial App

**Actions:**
1. [ ] Receive notification from WhatsApp (non-payment message)
2. [ ] Receive notification from Instagram

**Expected Result:**
- [ ] No transaction created
- [ ] Only financial apps are processed

**Logs to Check:**
```
⏭️ NOTIFICATION: Not from financial app, skipping
```

---

## 🔄 App Lifecycle Testing

### Test Case 13: App Restart

**Actions:**
1. [ ] Enable auto-detection
2. [ ] Close app completely (swipe from recent apps)
3. [ ] Reopen app
4. [ ] Check if auto-detection is still enabled

**Expected Result:**
- [ ] Auto-detection remains enabled
- [ ] Listener restarts automatically
- [ ] Settings persist

**Logs to Check:**
```
✅ MAIN: Database initialized
✅ MAIN: Notification service initialized and listening
```

---

### Test Case 14: Background Operation

**Actions:**
1. [ ] Enable auto-detection
2. [ ] Minimize app (home button)
3. [ ] Send test SMS
4. [ ] Open app

**Expected Result:**
- [ ] Transaction was added while app was in background
- [ ] Appears when app is reopened

---

## 📊 Statistics Testing

### Test Case 15: Statistics Display

**Actions:**
1. [ ] Add 3-4 auto-detected transactions
2. [ ] Go to Profile screen
3. [ ] Check "Auto-Detected Transactions" count

**Expected Result:**
- [ ] Count shows correct number
- [ ] Updates when new transactions added
- [ ] Refreshes when profile is reloaded

---

## 🎨 UI Testing

### Test Case 16: Settings UI

**Check:**
- [ ] Toggle switch works smoothly
- [ ] Permission button opens settings
- [ ] Statistics card displays correctly
- [ ] All text is readable
- [ ] Icons display correctly
- [ ] Colors match app theme
- [ ] No UI glitches

---

### Test Case 17: Transaction Display

**Check:**
- [ ] Auto-detected transactions appear in Home screen
- [ ] Look identical to manual transactions
- [ ] Can be edited
- [ ] Can be deleted
- [ ] Show correct category icons
- [ ] Amount formatted correctly

---

## 🔧 Edge Cases

### Test Case 18: Multiple Notifications Rapidly

**Actions:**
1. [ ] Send 5 different SMS messages quickly (within 10 seconds)

**Expected Result:**
- [ ] All valid transactions are created
- [ ] No crashes
- [ ] No missed transactions
- [ ] No duplicates

---

### Test Case 19: Very Large Amount

**Test SMS:**
```
Rs.9,99,99,999 debited from your account
```

**Expected Result:**
- [ ] Amount: 99999999.00
- [ ] No overflow errors
- [ ] Displays correctly in UI

---

### Test Case 20: Very Small Amount

**Test SMS:**
```
Rs.0.50 debited for transaction fee
```

**Expected Result:**
- [ ] Amount: 0.50
- [ ] Transaction created correctly

---

## 🚀 Performance Testing

### Test Case 21: Database Performance

**Actions:**
1. [ ] Add 100+ transactions (mix of manual and auto)
2. [ ] Send new test SMS
3. [ ] Check response time

**Expected Result:**
- [ ] Transaction added within 1 second
- [ ] No lag in UI
- [ ] Duplicate check is fast

---

### Test Case 22: Memory Usage

**Check:**
- [ ] Monitor memory usage in Android Studio
- [ ] Should not increase significantly over time
- [ ] No memory leaks

---

## 🔐 Security Testing

### Test Case 23: Permission Denial

**Actions:**
1. [ ] Deny notification permission
2. [ ] Try to enable auto-detection

**Expected Result:**
- [ ] App handles gracefully
- [ ] Shows appropriate message
- [ ] No crash

---

### Test Case 24: Permission Revocation

**Actions:**
1. [ ] Enable auto-detection
2. [ ] Go to Android settings
3. [ ] Revoke notification permission
4. [ ] Send test SMS

**Expected Result:**
- [ ] No transaction created
- [ ] App doesn't crash
- [ ] User can re-enable permission

---

## 📱 Real-World Testing

### Test Case 25: Actual Payment Apps

**Test with Real Transactions:**
- [ ] PhonePe transaction
- [ ] Google Pay transaction
- [ ] Paytm transaction
- [ ] Bank SMS
- [ ] Amazon order notification

**Expected Result:**
- [ ] All real transactions are detected
- [ ] Categories are correct
- [ ] Amounts are accurate

---

## 📋 Final Checklist

### Before Play Store Submission:

**Functionality:**
- [ ] All test cases passed
- [ ] No crashes or errors
- [ ] Performance is acceptable
- [ ] UI looks good on different screen sizes

**Documentation:**
- [ ] README updated
- [ ] Privacy policy updated
- [ ] App description updated
- [ ] Screenshots taken

**Code Quality:**
- [ ] No lint errors (`flutter analyze`)
- [ ] No warnings in logs
- [ ] Code is commented
- [ ] Debug logs can be disabled for production

**Build:**
- [ ] Version number updated (1.1.0+2)
- [ ] Release APK builds successfully
- [ ] APK size is reasonable
- [ ] Signing configured

**Testing:**
- [ ] Tested on multiple devices
- [ ] Tested on different Android versions
- [ ] Tested with different banks/apps
- [ ] Beta testing completed

---

## 🐛 Bug Tracking

### Issues Found:

| # | Issue | Severity | Status | Notes |
|---|-------|----------|--------|-------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

---

## ✅ Test Summary

**Date:** _____________  
**Tester:** _____________  
**Device:** _____________  
**Android Version:** _____________

**Results:**
- Total Tests: 25
- Passed: ___
- Failed: ___
- Skipped: ___

**Overall Status:** [ ] PASS / [ ] FAIL

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________

---

## 🎉 Sign-Off

**Ready for Production:** [ ] YES / [ ] NO

**Approved By:** _____________  
**Date:** _____________

---

**Happy Testing! 🧪**

Remember: Thorough testing ensures a great user experience! 🚀
