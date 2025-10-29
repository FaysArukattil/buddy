# 🧪 Testing Auto Transaction Detection with Simulated Notifications

## 🎯 How to Test Without Real Transactions

Since we can't easily trigger real bank notifications, here are methods to test the feature:

---

## Method 1: Using ADB to Send Test Notifications (Recommended)

### Prerequisites:
- Android device connected via USB with USB debugging enabled
- ADB installed (comes with Android Studio)

### Step 1: Find Your Device
```bash
adb devices
```

### Step 2: Send Test Notification via ADB

**Test Debit Transaction:**
```bash
adb shell "am broadcast -a com.test.notification --es title 'Bank Alert' --es message 'Your A/C debited by Rs.500 for shopping'"
```

**Test Credit Transaction:**
```bash
adb shell "am broadcast -a com.test.notification --es title 'Bank Alert' --es message 'Your A/C credited with Rs.2000 via UPI'"
```

**Test with Category (Food):**
```bash
adb shell "am broadcast -a com.test.notification --es title 'PhonePe' --es message 'Rs.450 paid to Swiggy'"
```

---

## Method 2: Create a Test App to Send Notifications

I'll create a simple test helper for you:

### Create Test Notification Button in Your App

Add this to your Profile screen temporarily for testing:

```dart
// Add this button in profile_screen.dart for testing
ElevatedButton(
  onPressed: () async {
    // Simulate notification
    await _simulateNotification();
  },
  child: Text('Test Notification'),
)

// Add this method
Future<void> _simulateNotification() async {
  // This simulates what the notification service receives
  final testEvent = {
    'packageName': 'com.google.android.apps.messaging',
    'title': 'Bank Alert',
    'content': 'Your A/C debited by Rs.500 for Amazon purchase',
  };
  
  // You can call the parsing logic directly for testing
  print('Test notification: $testEvent');
}
```

---

## Method 3: Send Yourself Real SMS Messages

This is the most realistic test:

### Step 1: Send Test SMS from Another Phone

Send these messages to your test device:

**Test 1: Simple Debit**
```
Your A/C 1234 debited by Rs.500 for shopping
```

**Test 2: Credit Transaction**
```
Your A/C 5678 credited with Rs.2000 via UPI from John
```

**Test 3: Food Category**
```
Payment of Rs.450 to Swiggy successful
```

**Test 4: Shopping Category**
```
Rs.1250 debited for Amazon purchase
```

**Test 5: Transport Category**
```
Rs.300 paid to Uber for ride
```

**Test 6: With Commas**
```
Your account debited by Rs.1,25,500 for property purchase
```

---

## Method 4: Use Notification Testing Apps

### Option A: Notification Maker App
1. Install "Notification Maker" from Play Store
2. Create custom notifications with:
   - Package: `com.google.android.apps.messaging`
   - Title: `Bank Alert`
   - Content: `Your A/C debited by Rs.500 for shopping`

### Option B: MacroDroid or Tasker
1. Install MacroDroid (free) or Tasker
2. Create a macro to send test notifications
3. Trigger manually for testing

---

## 🎯 Quick Test Script

I'll create a simple Dart test file you can run:

### Create: `test/notification_parser_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Parser Tests', () {
    test('Parse debit transaction', () {
      final text = 'Your A/C debited by Rs.500 for shopping';
      
      // Test regex patterns
      final debitRegex = RegExp(
        r'\b(debited|spent|purchase|paid|withdrawn|debit|payment|sent|transferred)\b',
        caseSensitive: false,
      );
      
      final amountRegex = RegExp(
        r'(?:Rs\.?|INR|₹)\s?([0-9,]+\.?[0-9]*)|([0-9,]+\.?[0-9]*)\s?(?:Rs\.?|INR|₹)',
        caseSensitive: false,
      );
      
      expect(debitRegex.hasMatch(text), true);
      
      final amountMatch = amountRegex.firstMatch(text);
      expect(amountMatch, isNotNull);
      
      final amount = amountMatch!.group(1) ?? amountMatch.group(2);
      expect(amount, '500');
    });
    
    test('Parse credit transaction', () {
      final text = 'Your A/C credited with Rs.2000 via UPI';
      
      final creditRegex = RegExp(
        r'\b(credited|received|deposit|income|credit|refund|cashback)\b',
        caseSensitive: false,
      );
      
      expect(creditRegex.hasMatch(text), true);
    });
    
    test('Parse amount with commas', () {
      final text = 'Rs.1,25,500 debited';
      
      final amountRegex = RegExp(
        r'(?:Rs\.?|INR|₹)\s?([0-9,]+\.?[0-9]*)|([0-9,]+\.?[0-9]*)\s?(?:Rs\.?|INR|₹)',
        caseSensitive: false,
      );
      
      final amountMatch = amountRegex.firstMatch(text);
      final amountStr = amountMatch!.group(1) ?? amountMatch.group(2);
      final amount = double.parse(amountStr!.replaceAll(',', ''));
      
      expect(amount, 125500.0);
    });
  });
}
```

### Run Tests:
```bash
flutter test test/notification_parser_test.dart
```

---

## 🔍 Debugging Steps

### 1. Check Logs
Run your app and watch the console:

```bash
flutter run
```

Look for these log messages:
- `✅ MAIN: Database initialized`
- `✅ MAIN: Notification service initialized`
- `🎧 NOTIFICATION: Starting notification listener...`
- `📬 NOTIFICATION: Received from...`

### 2. Verify Permission
```bash
adb shell dumpsys notification_listener
```

Look for your app package name in the enabled listeners.

### 3. Check Database
After sending test notifications, check if transactions were added:

```bash
adb shell
run-as com.example.buddy
cd databases
sqlite3 user.db
SELECT * FROM transactions WHERE auto_detected = 1;
.exit
```

---

## 📱 Step-by-Step Testing Guide

### Phase 1: Setup
1. ✅ Build and install app: `flutter run`
2. ✅ Open app and go to Profile
3. ✅ Tap "Notification Permission"
4. ✅ Enable "Buddy" in Android settings
5. ✅ Return to app
6. ✅ Toggle "Auto-Detect Transactions" ON

### Phase 2: Test with SMS
1. Send test SMS from another phone
2. Wait 2-3 seconds
3. Check Home screen for new transaction
4. Verify amount, type, and category

### Phase 3: Test Categories
Send these SMS messages one by one:

| SMS Text | Expected Category |
|----------|-------------------|
| `Rs.450 paid to Swiggy` | Food |
| `Rs.1250 debited for Amazon` | Shopping |
| `Rs.300 paid to Uber` | Transport |
| `Rs.999 debited for Netflix` | Entertainment |
| `Rs.500 for medical store` | Health |

### Phase 4: Test Duplicates
1. Send same SMS twice
2. Only ONE transaction should be created
3. Check logs for "Duplicate transaction detected"

### Phase 5: Test Invalid Notifications
1. Send: `Your OTP is 123456`
2. No transaction should be created
3. Check logs for "No transaction detected"

---

## 🐛 Common Issues and Solutions

### Issue 1: No Transactions Detected
**Check:**
- [ ] Permission granted?
- [ ] Auto-detection toggle ON?
- [ ] SMS contains amount and debit/credit keyword?
- [ ] Check logs for error messages

### Issue 2: Wrong Category
**Solution:**
- Categories are keyword-based
- Modify `_detectCategory()` in `notification_service.dart`
- Add more keywords for your needs

### Issue 3: Duplicate Transactions
**Check:**
- [ ] Hash generation working?
- [ ] Database has `notification_hash` column?
- [ ] Check logs for duplicate detection

---

## 🎯 Expected Log Output

### Successful Transaction Detection:
```
📬 NOTIFICATION: Received from com.google.android.apps.messaging
   Title: Bank Alert
   Content: Your A/C debited by Rs.500 for shopping
🤖 DATABASE: Auto-inserting transaction: expense ₹500.0
✅ DATABASE: Auto-transaction saved with ID: 1
✅ NOTIFICATION: Auto-transaction added successfully!
   Type: expense
   Amount: ₹500.0
   Category: Shopping
```

### Duplicate Detection:
```
📬 NOTIFICATION: Received from com.google.android.apps.messaging
⚠️ NOTIFICATION: Duplicate transaction detected, skipping
```

### Invalid Notification:
```
📬 NOTIFICATION: Received from com.whatsapp
⏭️ NOTIFICATION: Not from financial app, skipping
```

---

## 🚀 Quick Test Commands

### Test 1: Simple Debit
```bash
# Send SMS or use this ADB command
adb shell am start -a android.intent.action.SENDTO -d sms:YOUR_NUMBER --es sms_body "Your A/C debited by Rs.500 for shopping"
```

### Test 2: Check Logs
```bash
flutter logs | findstr NOTIFICATION
```

### Test 3: Check Database
```bash
adb shell run-as com.example.buddy sqlite3 databases/user.db "SELECT * FROM transactions WHERE auto_detected = 1;"
```

---

## 📊 Test Results Template

| Test Case | SMS Text | Expected Result | Actual Result | Pass/Fail |
|-----------|----------|-----------------|---------------|-----------|
| Debit | `Rs.500 debited` | expense, 500 | | |
| Credit | `Rs.2000 credited` | income, 2000 | | |
| Food | `Rs.450 to Swiggy` | Food category | | |
| Shopping | `Rs.1250 Amazon` | Shopping category | | |
| Duplicate | Same SMS twice | Only 1 transaction | | |
| Invalid | `OTP 123456` | No transaction | | |

---

## 🎉 Success Criteria

Your implementation is working if:
- ✅ Transactions appear in Home screen automatically
- ✅ Amounts are parsed correctly
- ✅ Categories are assigned properly
- ✅ Duplicates are prevented
- ✅ Invalid notifications are ignored
- ✅ No app crashes
- ✅ Logs show proper flow

---

## 💡 Pro Tips

1. **Test with Real Banks:** Once basic testing works, try with real bank SMS
2. **Monitor Battery:** Check battery usage after 24 hours
3. **Test Edge Cases:** Very large amounts, decimal amounts, etc.
4. **User Feedback:** Ask beta testers to report issues
5. **Iterate:** Add more keywords based on actual usage

---

**Happy Testing! 🧪**

Your auto-detection feature is ready to be tested thoroughly!
