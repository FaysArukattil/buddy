import 'package:flutter/material.dart';
import 'dart:ui';
// ignore: depend_on_referenced_packages
import 'package:fl_chart/fl_chart.dart';
import 'package:buddy/utils/colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 0;
  String _type = 'Expense';

  final List<String> _tabs = const ['Day', 'Week', 'Month', 'Year'];

  final Map<int, List<double>> _dataPoints = {
    0: [300, 500, 400, 700, 600, 800, 650],
    1: [200, 450, 350, 600, 500, 700, 550],
    2: [200, 350, 250, 600, 400, 700, 550, 620],
    3: [300, 400, 350, 550, 500, 650, 600, 700, 650, 750, 720, 800],
  };

  final Map<int, List<String>> _labels = {
    0: ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM', '12AM'],
    1: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    2: ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'],
    3: [
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
    ],
  };

  @override
  Widget build(BuildContext context) {
    final points = _dataPoints[_selectedTab]!;
    final labels = _labels[_selectedTab]!;

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
                              child: LineChart(
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
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget:
                                            (double value, TitleMeta meta) {
                                              final index = value.toInt();
                                              if (index < 0 ||
                                                  index >= labels.length) {
                                                return const Text('');
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  labels[index],
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11,
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
                                  maxY:
                                      points.reduce((a, b) => a > b ? a : b) *
                                      1.2,
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
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 5,
                                                color: Colors.white,
                                                strokeWidth: 3,
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
                                                '\$${barSpot.y.toStringAsFixed(0)}',
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Top Spending header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Top Spending',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.filter_list_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Spending list
                    _spendTile(
                      context,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade100,
                              Colors.green.shade50,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_cafe_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                      title: 'Starbucks',
                      subtitle: 'Jan 12, 2022',
                      amount: -150,
                      highlight: false,
                    ),
                    _spendTile(
                      context,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primary.withValues(alpha: 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      title: 'Transfer',
                      subtitle: 'Yesterday',
                      amount: 85,
                      highlight: true,
                    ),
                    _spendTile(
                      context,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade100, Colors.red.shade50],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                      title: 'Youtube',
                      subtitle: 'Jan 16, 2022',
                      amount: -11.99,
                      highlight: false,
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spendTile(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String subtitle,
    required double amount,
    bool highlight = false,
  }) {
    final amtStr =
        '${amount < 0 ? '- ' : '+ '}\$${amount.abs().toStringAsFixed(2)}';
    final amtColor = amount < 0 ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight ? AppColors.secondary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: highlight
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: highlight ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: amtColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                amtStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amtColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
