import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/utils/images.dart';
import 'package:buddy/utils/format_utils.dart';
import 'package:buddy/repositories/transaction_repository.dart';
import 'package:buddy/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  void refreshData() {
    _loadProfile();
  }

  final _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  String _email = '';
  String? _imagePath;
  bool _editing = false;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _moneyLottieDy = 0;
  int _lottieTapEpoch = 0;
  double _moneyLottieScale = 1.0;
  late final AnimationController _headerController;
  late final Animation<double> _headerBob;
  bool _autoDetectionEnabled = true;
  int _autoTransactionCount = 0;

  // Widget _buildNotificationDebugSection() {
  //   return FutureBuilder<Map<String, dynamic>>(
  //     future: NotificationService.getDebugInfo(),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       final info = snapshot.data!;
  //       final isGranted = info['permission_granted'] as bool;
  //       final isListening = info['is_listening'] as bool;
  //       final isEnabled = info['auto_detection_enabled'] as bool;
  //       final appCount = info['monitored_apps_count'] as int;

  //       return Container(
  //         margin: const EdgeInsets.symmetric(horizontal: 20),
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [
  //               Colors.deepPurple.withValues(alpha: 0.1),
  //               Colors.blue.withValues(alpha: 0.05),
  //             ],
  //           ),
  //           borderRadius: BorderRadius.circular(14),
  //           border: Border.all(
  //             color: Colors.deepPurple.withValues(alpha: 0.3),
  //             width: 2,
  //           ),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 const Icon(
  //                   Icons.bug_report_rounded,
  //                   color: Colors.deepPurple,
  //                   size: 20,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 const Text(
  //                   '🔍 Debug Info',
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.deepPurple,
  //                   ),
  //                 ),
  //                 const Spacer(),
  //                 IconButton(
  //                   icon: const Icon(Icons.refresh, size: 20),
  //                   onPressed: () => setState(() {}),
  //                   padding: EdgeInsets.zero,
  //                   constraints: const BoxConstraints(),
  //                 ),
  //               ],
  //             ),
  //             const Divider(height: 20),

  //             // Status indicators
  //             _buildDebugRow(
  //               'Permission',
  //               isGranted ? 'Granted ✅' : 'NOT Granted ❌',
  //               isGranted ? Colors.green : Colors.red,
  //             ),
  //             _buildDebugRow(
  //               'Listener',
  //               isListening ? 'Active ✅' : 'Inactive ⚠️',
  //               isListening ? Colors.green : Colors.orange,
  //             ),
  //             _buildDebugRow(
  //               'Auto-Detection',
  //               isEnabled ? 'Enabled ✅' : 'Disabled ❌',
  //               isEnabled ? Colors.green : Colors.grey,
  //             ),
  //             _buildDebugRow('Monitoring', '$appCount apps', Colors.blue),

  //             const SizedBox(height: 12),
  //             const Divider(height: 20),

  //             // Test buttons
  //             Column(
  //               children: [
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: ElevatedButton.icon(
  //                     onPressed: () => _runParserTests(),
  //                     icon: const Icon(Icons.science, size: 18),
  //                     label: const Text('🧪 Test Parser'),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.deepPurple,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(vertical: 12),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: OutlinedButton.icon(
  //                     onPressed: () => _showDetailedDebugInfo(info),
  //                     icon: const Icon(Icons.info_outline, size: 18),
  //                     label: const Text('View Monitored Apps'),
  //                     style: OutlinedButton.styleFrom(
  //                       foregroundColor: Colors.deepPurple,
  //                       side: const BorderSide(color: Colors.deepPurple),
  //                       padding: const EdgeInsets.symmetric(vertical: 12),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             const SizedBox(height: 12),

  //             // Instructions based on status
  //             if (!isGranted) ...[
  //               Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.orange.withValues(alpha: 0.1),
  //                   borderRadius: BorderRadius.circular(10),
  //                   border: Border.all(
  //                     color: Colors.orange.withValues(alpha: 0.3),
  //                   ),
  //                 ),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Icon(
  //                           Icons.warning_rounded,
  //                           color: Colors.orange.shade700,
  //                           size: 18,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Text(
  //                           'Action Required',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.orange.shade900,
  //                             fontSize: 13,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 8),
  //                     Text(
  //                       '1. Tap "Notification Permission" above\n'
  //                       '2. Find your app in the list\n'
  //                       '3. Enable the toggle\n'
  //                       '4. Return here and tap refresh button',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Colors.grey.shade700,
  //                         height: 1.4,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],

  //             if (isGranted && !isListening) ...[
  //               Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.orange.withValues(alpha: 0.1),
  //                   borderRadius: BorderRadius.circular(10),
  //                   border: Border.all(
  //                     color: Colors.orange.withValues(alpha: 0.3),
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.info_outline,
  //                       color: Colors.orange.shade700,
  //                       size: 18,
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: Text(
  //                         'Listener not active. Close and restart the app.',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey.shade700,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],

  //             if (isGranted && isListening) ...[
  //               Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.green.withValues(alpha: 0.1),
  //                   borderRadius: BorderRadius.circular(10),
  //                   border: Border.all(
  //                     color: Colors.green.withValues(alpha: 0.3),
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.check_circle_outline,
  //                       color: Colors.green.shade700,
  //                       size: 18,
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: Text(
  //                         '✅ Everything working! Send test SMS: "Rs 100 debited from account"',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey.shade700,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildDebugRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _runParserTests() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running tests...\nCheck console'),
          ],
        ),
      ),
    );

    final testMessages = [
      'Rs 500 debited from your account for Swiggy',
      'Credited Rs 1000 to your account',
      'Paid Rs 250 via PhonePe',
      'INR 1500.50 credited to A/c XX1234',
      'Debited Rs.299 for Netflix',
    ];

    debugPrint('\n========== PARSER TESTS ==========');
    // for (final msg in testMessages) {
    //   await NotificationService.testNotificationParsing(msg);
    // }
    debugPrint('========== TESTS COMPLETE ==========\n');

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Tests done! Check console/logcat'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDetailedDebugInfo(Map<String, dynamic> info) {
    final apps = info['monitored_apps'] as List;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monitored Apps'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Listening to ${apps.length} apps:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${index + 1}. ${apps[index]}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _headerBob = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );
    _headerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final savedName = prefs.getString('name');
    final imgPath = prefs.getString('profile_image_path');

    // Load current month totals from database (like Current Balance)
    final repo = TransactionRepository();
    final rows = await repo.getAll();
    final now = DateTime.now();
    double income = 0, expense = 0;
    for (final r in rows) {
      final dt = DateTime.tryParse(r['date'] as String) ?? now;
      // Only count transactions from current month
      if (dt.year == now.year && dt.month == now.month) {
        final amt = (r['amount'] as num).toDouble();
        final type = (r['type'] as String).toLowerCase().trim();
        if (type == 'income') {
          income += amt;
        } else if (type == 'expense') {
          expense += amt;
        }
      }
    }

    String displayName = savedName ?? '';
    if (displayName.isEmpty && email.isNotEmpty) {
      displayName = email.contains('@') ? email.split('@').first : email;
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }

    // Load auto-detection settings
    final autoEnabled = await NotificationService.isAutoDetectionEnabled();
    final autoTransactions = await repo.getAutoDetectedTransactions();

    setState(() {
      _email = email;
      _nameController.text = displayName;
      _imagePath = imgPath;
      _totalIncome = income;
      _totalExpense = expense;
      _autoDetectionEnabled = autoEnabled;
      _autoTransactionCount = autoTransactions.length;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      if (!mounted) return;
      setState(() => _imagePath = picked.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', picked.path);
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text.trim());
    if (_imagePath != null) {
      await prefs.setString('profile_image_path', _imagePath!);
    }

    if (!mounted) return;

    setState(() => _editing = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatCurrency(double v) =>
      FormatUtils.formatCurrency(v, compact: true);

  Future<void> _clearThisMonthTransactions() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear This Month\'s Transactions?'),
        content: const Text(
          'This will permanently delete all transactions from this month. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = TransactionRepository();
      final rows = await repo.getAll();
      final now = DateTime.now();

      // Delete all transactions from current month
      for (final r in rows) {
        final dateStr = r['date'] as String?;
        if (dateStr == null) continue;
        final dt = DateTime.tryParse(dateStr);
        if (dt != null && dt.year == now.year && dt.month == now.month) {
          await repo.delete(r['id'] as int);
        }
      }

      if (!mounted) return;

      // Refresh data
      await _loadProfile();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This month\'s transactions cleared'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to clear transactions'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete ALL transactions and profile data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Clear all transactions
      final repo = TransactionRepository();
      final rows = await repo.getAll();
      for (final r in rows) {
        await repo.delete(r['id'] as int);
      }

      // Clear profile data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('name');
      await prefs.remove('profile_image_path');

      if (!mounted) return;

      // Reset state
      setState(() {
        _nameController.text = '';
        _imagePath = null;
        _totalIncome = 0;
        _totalExpense = 0;
      });

      await _loadProfile();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data cleared'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to clear data'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _todayLabel() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalIncome - _totalExpense;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(AppImages.curvedBackground, fit: BoxFit.cover),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header Card - Compact
                    AnimatedBuilder(
                      animation: _headerBob,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _headerBob.value),
                          child: child,
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.85),
                                      AppColors.primary.withValues(alpha: 0.75),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 16,
                                                spreadRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 44,
                                            backgroundColor: Colors.white,
                                            child: CircleAvatar(
                                              radius: 41,
                                              backgroundColor: Colors.grey[100],
                                              backgroundImage:
                                                  _imagePath != null
                                                  ? FileImage(File(_imagePath!))
                                                  : null,
                                              child: _imagePath == null
                                                  ? Icon(
                                                      Icons.person_rounded,
                                                      size: 42,
                                                      color: AppColors.primary
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _showImageSourceSheet(context),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.secondary,
                                                    AppColors.secondary
                                                        .withValues(alpha: 0.8),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.secondary
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: _editing
                                          ? Container(
                                              key: const ValueKey('editing'),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: TextField(
                                                controller: _nameController,
                                                focusNode: _nameFocus,
                                                textAlign: TextAlign.center,
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      hintText:
                                                          'Enter your name',
                                                      hintStyle: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                textInputAction:
                                                    TextInputAction.done,
                                                onSubmitted: (_) =>
                                                    _saveProfile(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              key: const ValueKey('display'),
                                              _nameController.text.isEmpty
                                                  ? 'Tap edit to add name'
                                                  : _nameController.text,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),

                                    const SizedBox(height: 6),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.email_rounded,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              _email,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_editing) {
                                    FocusScope.of(context).unfocus();
                                    _saveProfile();
                                  } else {
                                    setState(() => _editing = true);
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        if (mounted) _nameFocus.requestFocus();
                                      },
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _editing
                                        ? Icons.check_rounded
                                        : Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Balance card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Current Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatCurrency(balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _modernTotalCard(
                            label: 'Income',
                            value: _formatCurrency(_totalIncome),
                            color: AppColors.income,
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _modernTotalCard(
                            label: 'Expense',
                            value: _formatCurrency(_totalExpense),
                            color: AppColors.expense,
                            icon: Icons.trending_down_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Compact Lottie
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _lottieTapEpoch += 1;
                          _moneyLottieDy = (_moneyLottieDy + 15).clamp(0, 120);
                          _moneyLottieScale = (_moneyLottieScale + 0.08).clamp(
                            1.0,
                            1.4,
                          );
                        });
                        final epoch = _lottieTapEpoch;
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (!mounted) return;
                          if (epoch == _lottieTapEpoch) {
                            setState(() {
                              _moneyLottieDy = 0;
                              _moneyLottieScale = 1.0;
                            });
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(
                          0,
                          -_moneyLottieDy,
                          0,
                        ),
                        child: AnimatedScale(
                          scale: _moneyLottieScale,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          child: SizedBox(
                            height: 100,
                            child: Lottie.asset(
                              'assets/lottie/jsonlottie/Moneylottie.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: true,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _todayLabel(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const SizedBox(height: 30),

                    // Data Management Section
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernTotalCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose Image Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _pickSourceButton(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _pickSourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pickSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
