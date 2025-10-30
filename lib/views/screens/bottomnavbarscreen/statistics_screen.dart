import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:async';
// ignore: depend_on_referenced_packages
import 'package:fl_chart/fl_chart.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/utils/format_utils.dart';
import 'package:buddy/repositories/transaction_repository.dart';
import 'package:buddy/services/pdf_service.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  int _selectedTab = 0;
  String _type = 'Expense';
  final List<String> _tabs = const ['Day', 'Week', 'Month', 'Year'];
  bool _isDownloading = false;
  DateTime _selectedDate = DateTime.now();

  late final TransactionRepository _repo;
  List<Map<String, Object?>> _rows = [];

  // Optimized cache system
  List<double> _cachedPoints = [];
  List<String> _cachedLabels = [];
  double _cachedTotal = 0.0;
  List<Map<String, dynamic>> _cachedTopCategories = [];
  String _cacheKey = '';
  bool _isComputing = false;
  Timer? _debounceTimer;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = TransactionRepository();
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      _load();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    debugPrint('📊 STATISTICS: Loading transactions...');
    try {
      final rows = await _repo.getAll();
      debugPrint('📊 STATISTICS: Loaded ${rows.length} transactions');
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
      _scheduleComputation();
    } catch (e) {
      debugPrint('❌ STATISTICS: Error loading transactions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Public method to refresh data (called from BottomNavbarScreen)
  Future<void> refreshData() async {
    debugPrint('🔄 STATISTICS: Manual refresh triggered');
    await _load();
  }

  // Debounced computation to avoid rapid recalculations
  void _scheduleComputation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _computeDataAsync();
    });
  }

  // Async computation to prevent UI blocking
  Future<void> _computeDataAsync() async {
    if (_isComputing) return;

    final newKey = _getCacheKey();
    if (newKey == _cacheKey) return;

    setState(() => _isComputing = true);

    // Compute in microtask to prevent blocking
    await Future.microtask(() {
      final points = _computePoints();
      final labels = _computeLabels();
      final total = points.fold<double>(0.0, (sum, val) => sum + val);
      final topCategories = _computeTopCategories();

      if (mounted) {
        setState(() {
          _cacheKey = newKey;
          _cachedPoints = points;
          _cachedLabels = labels;
          _cachedTotal = total;
          _cachedTopCategories = topCategories;
          _isComputing = false;
        });
      }
    });
  }

  String _getCacheKey() {
    return '$_selectedTab-$_type-${_selectedDate.toString()}-${_rows.length}';
  }

  List<double> _computePoints() {
    final isIncome = _type.toLowerCase() == 'income';
    final now = _selectedDate;

    switch (_selectedTab) {
      case 0: // Day: 24 hours
        final buckets = List<double>.filled(24, 0);
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase().trim();
          if ((isIncome && type != 'income') ||
              (!isIncome && type != 'expense')) {
            continue;
          }
          final dt = DateTime.tryParse(r['date'] as String);
          if (dt == null) continue;
          if (dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day) {
            buckets[dt.hour] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;

      case 1: // Week: Mon..Sun
        final buckets = List<double>.filled(7, 0);
        final startOfWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final end = start.add(const Duration(days: 7));

        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase().trim();
          if ((isIncome && type != 'income') ||
              (!isIncome && type != 'expense')) {
            continue;
          }
          final dt = DateTime.tryParse(r['date'] as String);
          if (dt == null) continue;
          if (dt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
              dt.isBefore(end)) {
            final idx = (dt.weekday - 1) % 7;
            buckets[idx] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;

      case 2: // Month: 1..N days
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final buckets = List<double>.filled(daysInMonth, 0);
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase().trim();
          if ((isIncome && type != 'income') ||
              (!isIncome && type != 'expense')) {
            continue;
          }
          final dt = DateTime.tryParse(r['date'] as String);
          if (dt == null) continue;
          if (dt.year == now.year && dt.month == now.month) {
            buckets[dt.day - 1] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;

      default: // Year: Jan..Dec
        final buckets = List<double>.filled(12, 0);
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase().trim();
          if ((isIncome && type != 'income') ||
              (!isIncome && type != 'expense')) {
            continue;
          }
          final dt = DateTime.tryParse(r['date'] as String);
          if (dt == null) continue;
          if (dt.year == now.year) {
            buckets[dt.month - 1] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;
    }
  }

  List<String> _computeLabels() {
    switch (_selectedTab) {
      case 0:
        return List.generate(24, (i) => '$i:00');
      case 1:
        return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 2:
        final now = _selectedDate;
        final days = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(days, (i) => '${i + 1}');
      default:
        return const [
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
    }
  }

  List<Map<String, dynamic>> _computeTopCategories() {
    final isIncome = _type.toLowerCase() == 'income';
    final categoryTotals = <String, double>{};
    final categoryIcons = <String, int>{};

    for (final r in _rows) {
      final type = (r['type'] as String).toLowerCase().trim();
      if ((isIncome && type != 'income') || (!isIncome && type != 'expense')) {
        continue;
      }

      final cat = r['category'] as String;
      final amt = (r['amount'] as num).toDouble();
      final icon = r['icon'] as int?;

      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;

      if (icon != null && !categoryIcons.containsKey(cat)) {
        categoryIcons[cat] = icon;
      }
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map(
          (e) => {
            'category': e.key,
            'amount': e.value,
            'icon': categoryIcons[e.key],
          },
        )
        .toList();
  }

  String _formatCurrency(double v) =>
      FormatUtils.formatCurrency(v, compact: true);

  Future<void> _downloadCurrentView() async {
    setState(() => _isDownloading = true);

    try {
      final now = _selectedDate;
      List<Map<String, dynamic>> filteredTransactions = [];
      String title = '';
      String subtitle = '';

      switch (_selectedTab) {
        case 0:
          filteredTransactions = _rows
              .where((t) {
                final date = DateTime.tryParse(t['date'] as String);
                if (date == null) return false;
                return date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
              })
              .cast<Map<String, dynamic>>()
              .toList();
          title = 'Daily Report';
          subtitle = DateFormat('MMM dd, yyyy').format(now);
          break;

        case 1:
          final startOfWeek = now.subtract(
            Duration(days: (now.weekday - 1) % 7),
          );
          final start = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final end = start.add(const Duration(days: 7));

          filteredTransactions = _rows
              .where((t) {
                final date = DateTime.tryParse(t['date'] as String);
                if (date == null) return false;
                return date.isAfter(
                      start.subtract(const Duration(milliseconds: 1)),
                    ) &&
                    date.isBefore(end);
              })
              .cast<Map<String, dynamic>>()
              .toList();
          title = 'Weekly Report';
          subtitle =
              '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
          break;

        case 2:
          filteredTransactions = _rows
              .where((t) {
                final date = DateTime.tryParse(t['date'] as String);
                if (date == null) return false;
                return date.year == now.year && date.month == now.month;
              })
              .cast<Map<String, dynamic>>()
              .toList();
          title = 'Monthly Report';
          subtitle = DateFormat('MMMM yyyy').format(now);
          break;

        case 3:
          filteredTransactions = _rows
              .where((t) {
                final date = DateTime.tryParse(t['date'] as String);
                if (date == null) return false;
                return date.year == now.year;
              })
              .cast<Map<String, dynamic>>()
              .toList();
          title = 'Yearly Report';
          subtitle = DateFormat('yyyy').format(now);
          break;
      }

      if (filteredTransactions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transactions found for this period'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final file = await PdfService.generateMultipleTransactionsPdf(
        transactions: filteredTransactions,
        title: title,
        subtitle: subtitle,
      );

      if (!mounted) return;
      _showPdfOptions(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _showDatePicker() async {
    switch (_selectedTab) {
      case 0:
        await _showDayPicker();
        break;
      case 1:
        await _showWeekPicker();
        break;
      case 2:
        await _showMonthPicker();
        break;
      case 3:
        await _showYearPicker();
        break;
    }
  }

  Future<void> _showDayPicker() async {
    DateTime tempDate = _selectedDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Select Day',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() => _selectedDate = tempDate);
                      _scheduleComputation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  tempDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWeekPicker() async {
    DateTime tempDate = _selectedDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Select Week',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() => _selectedDate = tempDate);
                      _scheduleComputation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  tempDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    DateTime tempDate = _selectedDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Select Month',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() => _selectedDate = tempDate);
                      _scheduleComputation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  tempDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showYearPicker() async {
    int selectedYear = _selectedDate.year;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Select Year',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(
                        () => _selectedDate = DateTime(selectedYear, 1, 1),
                      );
                      _scheduleComputation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: DateTime.now().year - selectedYear,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedYear = DateTime.now().year - index;
                },
                children: List.generate(DateTime.now().year - 2020 + 1, (
                  index,
                ) {
                  final year = DateTime.now().year - index;
                  return Center(
                    child: Text(
                      year.toString(),
                      style: const TextStyle(fontSize: 22),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfOptions(file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PDF Generated Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: AppColors.primary),
              title: const Text('Open PDF'),
              onTap: () {
                Navigator.pop(context);
                PdfService.openPdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.secondary),
              title: const Text('Share PDF'),
              onTap: () {
                Navigator.pop(context);
                PdfService.sharePdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.income),
              title: const Text('Print PDF'),
              onTap: () {
                Navigator.pop(context);
                PdfService.printPdf(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Show loading indicator while data is being loaded
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final points = _cachedPoints;
    final labels = _cachedLabels;
    final total = _cachedTotal;
    final topCategories = _cachedTopCategories;
    final hasData = points.any((p) => p > 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 20),
                    _buildTypeToggle(),
                    const SizedBox(height: 16),
                    _buildTotalDisplay(total),
                    const SizedBox(height: 20),
                    _buildChart(points, labels, hasData),
                    if (topCategories.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildTopCategories(topCategories, total),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.calendar_today,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: _showDatePicker,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Statistics',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: _isDownloading ? null : _downloadCurrentView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = i == _selectedTab;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = i;
                    _selectedDate = DateTime.now();
                  });
                  _scheduleComputation();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.38),
                              AppColors.secondary.withOpacity(0.30),
                            ],
                          )
                        : null,
                    border: selected
                        ? Border.all(
                            color: AppColors.secondary.withOpacity(0.35),
                            width: 1,
                          )
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.24),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _type = 'Expense');
                  _scheduleComputation();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _type == 'Expense'
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.38),
                              AppColors.secondary.withOpacity(0.30),
                            ],
                          )
                        : null,
                    border: _type == 'Expense'
                        ? Border.all(
                            color: AppColors.secondary.withOpacity(0.35),
                            width: 1,
                          )
                        : null,
                    boxShadow: _type == 'Expense'
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        color: _type == 'Expense'
                            ? AppColors.expense
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expense',
                        style: TextStyle(
                          color: _type == 'Expense'
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: _type == 'Expense'
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _type = 'Income');
                  _scheduleComputation();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _type == 'Income'
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.38),
                              AppColors.secondary.withOpacity(0.30),
                            ],
                          )
                        : null,
                    border: _type == 'Income'
                        ? Border.all(
                            color: AppColors.secondary.withOpacity(0.35),
                            width: 1,
                          )
                        : null,
                    boxShadow: _type == 'Income'
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: _type == 'Income'
                            ? AppColors.income
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Income',
                        style: TextStyle(
                          color: _type == 'Income'
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: _type == 'Income'
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDisplay(double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _type == 'Income' ? AppColors.income : AppColors.expense,
              (_type == 'Income' ? AppColors.income : AppColors.expense)
                  .withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_type == 'Income' ? AppColors.income : AppColors.expense)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total $_type',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tabs[_selectedTab],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Text(
                FormatUtils.formatCurrencyFull(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<double> points, List<String> labels, bool hasData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: RepaintBoundary(
                child: hasData
                    ? LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppColors.textLight.withOpacity(0.15),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const SizedBox();
                                  return Text(
                                    FormatUtils.formatCurrency(
                                      value,
                                      compact: true,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: _selectedTab == 0
                                    ? 4
                                    : (_selectedTab == 2 ? 5 : 1),
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= labels.length) {
                                    return const SizedBox();
                                  }

                                  bool shouldShow = false;
                                  if (_selectedTab == 0) {
                                    shouldShow = idx % 4 == 0;
                                  } else if (_selectedTab == 1) {
                                    shouldShow = true;
                                  } else if (_selectedTab == 2) {
                                    shouldShow =
                                        idx % 5 == 0 ||
                                        idx == labels.length - 1;
                                  } else {
                                    shouldShow = idx % 2 == 0;
                                  }

                                  if (!shouldShow) return const SizedBox();

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[idx],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (points.length - 1).toDouble(),
                          minY: 0,
                          maxY: hasData && points.isNotEmpty
                              ? points.reduce((a, b) => a > b ? a : b) * 1.2
                              : 10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                points.length,
                                (i) => FlSpot(i.toDouble(), points[i]),
                              ),
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) {
                                  if (spot.y == 0) return false;
                                  final index = spot.x.toInt();
                                  final totalPoints = points.length;

                                  if (_selectedTab == 0) {
                                    return index % 4 == 0;
                                  } else if (_selectedTab == 1) {
                                    return true;
                                  } else if (_selectedTab == 2) {
                                    return index % 5 == 0 ||
                                        index == totalPoints - 1;
                                  } else {
                                    return index % 2 == 0;
                                  }
                                },
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3.5,
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                    strokeColor: AppColors.primary,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.3),
                                    AppColors.secondary.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  AppColors.secondary,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              getTooltipItems:
                                  (List<LineBarSpot> touchedBarSpots) {
                                    return touchedBarSpots.map((barSpot) {
                                      return LineTooltipItem(
                                        FormatUtils.formatCurrency(
                                          barSpot.y,
                                          compact: true,
                                        ),
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      );
                                    }).toList();
                                  },
                            ),
                            handleBuiltInTouches: true,
                          ),
                        ),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.show_chart_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No data for this period',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategories(
    List<Map<String, dynamic>> topCategories,
    double total,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top ${_type == 'Expense' ? 'Spending' : 'Earning'} Categories',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...topCategories.map((cat) {
            final percentage = total > 0
                ? (cat['amount'] as double) / total * 100
                : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (_type == 'Income'
                                  ? AppColors.income
                                  : AppColors.expense)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cat['icon'] != null
                          ? IconData(
                              cat['icon'] as int,
                              fontFamily: 'MaterialIcons',
                            )
                          : Icons.category_rounded,
                      color: _type == 'Income'
                          ? AppColors.income
                          : AppColors.expense,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['category'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              _type == 'Income'
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(cat['amount'] as double),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _type == 'Income'
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
