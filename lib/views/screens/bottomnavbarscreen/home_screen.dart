import 'package:buddy/utils/images.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/profile_screen.dart';
import 'package:buddy/views/screens/transaction_detail_screen.dart';
import 'package:buddy/views/screens/filtered_transactions_screen.dart';
import 'package:buddy/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String _displayName = '';
  double _totalBalance = 0;
  double _income = 0;
  double _expenses = 0;
  late final AnimationController _controller;
  late final Animation<double> _bobAnimation;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _txSectionKey = GlobalKey();
  final bool _showRecentBadge = false;
  final List<Map<String, dynamic>> _transactions = [];
  late final TransactionRepository _repo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _repo = TransactionRepository();
    _refreshFromDb();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bobAnimation = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  Future<void> _refreshFromDb() async {
    setState(() => _isLoading = true);
    final rows = await _repo.getAll();
    rows.sort(
      (a, b) => (DateTime.parse(
        b['date'] as String,
      )).compareTo(DateTime.parse(a['date'] as String)),
    );

    // Calculate current month totals only
    final now = DateTime.now();
    double income = 0, expense = 0;
    for (final r in rows) {
      final dt = DateTime.tryParse(r['date'] as String) ?? now;
      if (dt.year == now.year && dt.month == now.month) {
        final amt = (r['amount'] as num).toDouble();
        final type = (r['type'] as String).toLowerCase();
        if (type == 'income') {
          income += amt;
        } else {
          expense += amt;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _transactions
        ..clear()
        ..addAll(
          rows.take(10).map((r) {
            final dt = DateTime.tryParse(r['date'] as String) ?? DateTime.now();
            return {
              'type': r['type'],
              'title': (r['note'] as String?)?.isNotEmpty == true
                  ? r['note']
                  : r['category'],
              'subtitle': r['category'],
              'amount': (r['amount'] as num).toDouble(),
              'time': _formatTime(dt),
              'date': dt,
              'category': r['category'],
              'note': r['note'],
              'avatarText': (r['category'] as String?)?.substring(0, 1) ?? '?',
              'icon': r['icon'],
              'id': r['id'],
            };
          }),
        );
      _income = income;
      _expenses = expense;
      _totalBalance = income - expense;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('name')?.trim() ?? '';
    final display = savedName.isNotEmpty ? savedName : 'Guest';
    setState(() {
      _displayName = display;
      _totalBalance = 0;
      _income = 0;
      _expenses = 0;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  bool get wantKeepAlive => true;

  IconData _iconForNote(String? note) {
    final n = (note ?? '').toLowerCase();
    if (n.contains('coffee') ||
        n.contains('cafe') ||
        n.contains('drink') ||
        n.contains('food') ||
        n.contains('snack')) {
      return Icons.fastfood_rounded;
    }
    if (n.contains('fuel') || n.contains('petrol') || n.contains('gas')) {
      return Icons.local_gas_station_rounded;
    }
    if (n.contains('uber') || n.contains('taxi') || n.contains('cab')) {
      return Icons.local_taxi_rounded;
    }
    if (n.contains('rent') || n.contains('home')) {
      return Icons.home_rounded;
    }
    if (n.contains('phone') || n.contains('mobile')) {
      return Icons.phone_android_rounded;
    }
    if (n.contains('netflix') ||
        n.contains('hotstar') ||
        n.contains('youtube') ||
        n.contains('movie')) {
      return Icons.movie_rounded;
    }
    if (n.contains('gym') || n.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    if (n.contains('gift')) {
      return Icons.card_giftcard_rounded;
    }
    if (n.contains('refund')) {
      return Icons.reply_rounded;
    }
    if (n.contains('salary') ||
        n.contains('upwork') ||
        n.contains('payment') ||
        n.contains('pay')) {
      return Icons.payments_rounded;
    }
    if (n.contains('travel') || n.contains('flight') || n.contains('trip')) {
      return Icons.flight_rounded;
    }
    if (n.contains('shop') || n.contains('shopping') || n.contains('grocer')) {
      return Icons.shopping_bag_rounded;
    }
    if (n.contains('pet')) {
      return Icons.pets_rounded;
    }
    if (n.contains('medical') ||
        n.contains('doctor') ||
        n.contains('hospital')) {
      return Icons.medical_services_rounded;
    }
    if (n.contains('school') ||
        n.contains('tuition') ||
        n.contains('education')) {
      return Icons.school_rounded;
    }
    if (n.contains('game') || n.contains('esports')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background curved image
          Positioned(
            child: Image.asset(AppImages.curvedBackground, fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _displayName.isNotEmpty ? _displayName : 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Balance card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AnimatedBuilder(
                      animation: _bobAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bobAnimation.value),
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Total Balance',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCurrency(_totalBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FilteredTransactionsScreen(
                                                type: 'Income',
                                              ),
                                        ),
                                      );
                                      if (mounted) await _refreshFromDb();
                                    },
                                    child: _statTile(
                                      label: 'Income',
                                      value: _income,
                                      color: AppColors.income,
                                      icon: Icons.arrow_downward_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FilteredTransactionsScreen(
                                                type: 'Expense',
                                              ),
                                        ),
                                      );
                                      if (mounted) await _refreshFromDb();
                                    },
                                    child: _statTile(
                                      label: 'Expenses',
                                      value: _expenses,
                                      color: AppColors.expense,
                                      icon: Icons.arrow_upward_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transactions header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transactions History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            if (_showRecentBadge)
                              Container(
                                key: _txSectionKey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Recent',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const Text(
                              'See all',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      key: _txSectionKey,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white70, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : _transactions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap + to add your first transaction',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              itemCount: _transactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tx = _transactions[index];
                                final isIncome = tx['type'] == 'income';
                                final amountColor = isIncome
                                    ? AppColors.income
                                    : AppColors.expense;
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      final page =
                                          await _buildTransactionDetailPage(tx);
                                      // ignore: use_build_context_synchronously
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => page),
                                      );
                                      if (mounted) await _refreshFromDb();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                colors: isIncome
                                                    ? [
                                                        AppColors.income
                                                            .withOpacity(0.15),
                                                        Colors.white,
                                                      ]
                                                    : [
                                                        AppColors.expense
                                                            .withOpacity(0.15),
                                                        Colors.white,
                                                      ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              _iconForNote(
                                                tx['note'] as String?,
                                              ),
                                              size: 20,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: amountColor
                                                            .withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                        border: Border.all(
                                                          color: amountColor
                                                              .withOpacity(
                                                                0.35,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        isIncome
                                                            ? 'Income'
                                                            : 'Expense',
                                                        style: TextStyle(
                                                          color: amountColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        tx['title'] as String,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  tx['subtitle'] as String,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.category_rounded,
                                                      size: 12,
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        (tx['category']
                                                                as String?) ??
                                                            '-',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textLight,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                (isIncome ? '+' : '-') +
                                                    _formatCurrency(
                                                      tx['amount'] as double,
                                                    ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: amountColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    _formatTxDate(
                                                      tx['date'] as DateTime,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    tx['time'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    // Simple USD-like formatting without intl dependency
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatTxDate(DateTime d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute $ampm';
  }

  Future<Widget> _buildTransactionDetailPage(Map<String, dynamic> tx) async {
    return TransactionDetailScreen(data: tx);
  }

  Widget _statTile({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white70, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
