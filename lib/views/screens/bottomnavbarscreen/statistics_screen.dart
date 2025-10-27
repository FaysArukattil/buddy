import 'package:flutter/material.dart';
import 'dart:ui';
// ignore: depend_on_referenced_packages
import 'package:fl_chart/fl_chart.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/utils/format_utils.dart';
import 'package:buddy/repositories/transaction_repository.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 0;
  String _type = 'Expense';
  final List<String> _tabs = const ['Day', 'Week', 'Month', 'Year'];

  late final TransactionRepository _repo;
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repo.getAll();
    if (!mounted) return;
    setState(() => _rows = rows);
  }

  List<double> _computePoints() {
    final isIncome = _type.toLowerCase() == 'income';
    final now = DateTime.now();
    switch (_selectedTab) {
      case 0: // Day: 24 hours
        final buckets = List<double>.filled(24, 0);
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase();
          if ((isIncome && type != 'income') || (!isIncome && type != 'expense')) continue;
          final dt = DateTime.tryParse(r['date'] as String) ?? now;
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            buckets[dt.hour] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;
      case 1: // Week: Mon..Sun
        final buckets = List<double>.filled(7, 0);
        final startOfWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase();
          if ((isIncome && type != 'income') || (!isIncome && type != 'expense')) continue;
          final dt = DateTime.tryParse(r['date'] as String) ?? now;
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final end = start.add(const Duration(days: 7));
          if (dt.isAfter(start.subtract(const Duration(milliseconds: 1))) && dt.isBefore(end)) {
            final idx = (dt.weekday - 1) % 7;
            buckets[idx] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;
      case 2: // Month: 1..N days
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final buckets = List<double>.filled(daysInMonth, 0);
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase();
          if ((isIncome && type != 'income') || (!isIncome && type != 'expense')) continue;
          final dt = DateTime.tryParse(r['date'] as String) ?? now;
          if (dt.year == now.year && dt.month == now.month) {
            buckets[dt.day - 1] += (r['amount'] as num).toDouble();
          }
        }
        return buckets;
      default: // Year: Jan..Dec
        final buckets = List<double>.filled(12, 0);
        for (final r in _rows) {
          final type = (r['type'] as String).toLowerCase();
          if ((isIncome && type != 'income') || (!isIncome && type != 'expense')) continue;
          final dt = DateTime.tryParse(r['date'] as String) ?? now;
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
        return List.generate(24, (i) => '${i}:00');
      case 1:
        return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 2:
        final now = DateTime.now();
        final days = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(days, (i) => '${i + 1}');
      default:
        return const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    }
  }

  double _computeTotal() {
    return _computePoints().fold(0.0, (sum, val) => sum + val);
  }

  List<Map<String, dynamic>> _computeTopCategories() {
    final isIncome = _type.toLowerCase() == 'income';
    final categoryTotals = <String, double>{};
    
    for (final r in _rows) {
      final type = (r['type'] as String).toLowerCase();
      if ((isIncome && type != 'income') || (!isIncome && type != 'expense')) continue;
      
      final cat = r['category'] as String;
      final amt = (r['amount'] as num).toDouble();
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
    }
    
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((e) => {
      'category': e.key,
      'amount': e.value,
    }).toList();
  }

  String _formatCurrency(double v) => FormatUtils.formatCurrency(v, compact: true);

  @override
  Widget build(BuildContext context) {
    final points = _computePoints();
    final labels = _computeLabels();
    final total = _computeTotal();
    final topCategories = _computeTopCategories();
    final hasData = points.any((p) => p > 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.ios_share,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
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
                                onTap: () => setState(() => _selectedTab = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary.withValues(
                                                alpha: 0.8,
                                              ),
                                            ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    _tabs[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Type dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _type,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary,
                                ),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 8,
                                menuMaxHeight: 200,
                                items: [
                                  DropdownMenuItem(
                                    value: 'Expense',
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.expense.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.trending_down_rounded,
                                            color: AppColors.expense,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('Expense'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Income',
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.income.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.trending_up_rounded,
                                            color: AppColors.income,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('Income'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _type = v ?? _type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Total display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _type == 'Income' ? AppColors.income : AppColors.expense,
                              (_type == 'Income' ? AppColors.income : AppColors.expense).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (_type == 'Income' ? AppColors.income : AppColors.expense).withOpacity(0.3),
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
                                  'Total ${_type}',
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
                    ),

                    const SizedBox(height: 20),

                    // Chart with fl_chart
                    Padding(
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
                                  Colors.white.withValues(alpha: 0.9),
                                  Colors.white.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                40,
                                16,
                                16,
                              ),
                              child: hasData ? LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: AppColors.textLight.withValues(
                                          alpha: 0.15,
                                        ),
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
                                            FormatUtils.formatCurrency(value, compact: true),
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
                                        interval: _selectedTab == 0 ? 4 : (_selectedTab == 2 ? 5 : 1),
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= labels.length) {
                                            return const SizedBox();
                                          }
                                          
                                          // Show fewer labels to avoid crowding
                                          bool shouldShow = false;
                                          if (_selectedTab == 0) {
                                            // Day: Show every 4 hours
                                            shouldShow = idx % 4 == 0;
                                          } else if (_selectedTab == 1) {
                                            // Week: Show all days
                                            shouldShow = true;
                                          } else if (_selectedTab == 2) {
                                            // Month: Show every 5 days
                                            shouldShow = idx % 5 == 0 || idx == labels.length - 1;
                                          } else {
                                            // Year: Show every 2 months
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
                                  maxY: hasData
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
                                          // Only show dots for non-zero values and reduce frequency significantly
                                          if (spot.y == 0) return false;
                                          final index = spot.x.toInt();
                                          final totalPoints = points.length;
                                          
                                          // Day: Show every 4 hours (6 dots max)
                                          if (_selectedTab == 0) {
                                            return index % 4 == 0;
                                          }
                                          // Week: Show all days (7 dots)
                                          else if (_selectedTab == 1) {
                                            return true;
                                          }
                                          // Month: Show every 5 days (6-7 dots)
                                          else if (_selectedTab == 2) {
                                            return index % 5 == 0 || index == totalPoints - 1;
                                          }
                                          // Year: Show every 2 months (6 dots)
                                          else {
                                            return index % 2 == 0;
                                          }
                                        },
                                        getDotPainter:
                                            (spot, percent, barData, index) {
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
                                            AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            AppColors.secondary.withValues(
                                              alpha: 0.05,
                                            ),
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
                                      tooltipBorderRadius:
                                          BorderRadius.circular(12),
                                      tooltipPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      getTooltipItems:
                                          (List<LineBarSpot> touchedBarSpots) {
                                            return touchedBarSpots.map((
                                              barSpot,
                                            ) {
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
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
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

                    if (topCategories.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      // Top Categories
                      Padding(
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
                              final percentage = total > 0 ? (cat['amount'] as double) / total * 100 : 0;
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
                                        color: (_type == 'Income' ? AppColors.income : AppColors.expense).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.category_rounded,
                                        color: _type == 'Income' ? AppColors.income : AppColors.expense,
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
                                                _type == 'Income' ? AppColors.income : AppColors.expense,
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
                                            color: _type == 'Income' ? AppColors.income : AppColors.expense,
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
                            }).toList(),
                          ],
                        ),
                      ),
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
}
