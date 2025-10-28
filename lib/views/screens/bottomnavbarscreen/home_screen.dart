import 'package:buddy/utils/images.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/utils/format_utils.dart';
import 'package:buddy/widgets/animated_money_text.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/profile_screen.dart';
import 'package:buddy/views/screens/transaction_detail_screen.dart';
import 'package:buddy/views/screens/filtered_transactions_screen.dart';
import 'package:buddy/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bobAnimation = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
    // Load data after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFromDb();
    });
  }

  void refreshData() {
    _refreshFromDb();
  }

  Future<void> _refreshFromDb() async {
    // Only show loading if we have no data
    if (_transactions.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final rows = await _repo.getAll();

      // Sort by date (newest first)
      rows.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] as String? ?? '');
        final dateB = DateTime.tryParse(b['date'] as String? ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      // Compute current-month totals exactly like Profile screen
      final now = DateTime.now();
      double monthIncome = 0, monthExpense = 0;

      for (final r in rows) {
        final dateStr = r['date'] as String?;
        if (dateStr == null || dateStr.isEmpty) continue;

        final dt = DateTime.tryParse(dateStr)?.toLocal() ?? now;
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        final type = ((r['type'] as String?) ?? '').toLowerCase().trim();

        if (dt.year == now.year && dt.month == now.month) {
          if (type == 'income') {
            monthIncome += amt;
          } else if (type == 'expense') {
            monthExpense += amt;
          }
        }
      }

      debugPrint('Home totals (month) -> income=$monthIncome, expense=$monthExpense, balance=${monthIncome - monthExpense}');
      debugPrint('Transactions loaded: ${rows.length}');

      // Show ALL transactions in home screen (not just today)

      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(
            rows.map((r) {
              final dt =
                  DateTime.tryParse(r['date'] as String) ?? DateTime.now();
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
                'avatarText':
                    (r['category'] as String?)?.substring(0, 1) ?? '?',
                'icon': r['icon'],
                'id': r['id'],
              };
            }),
          );
        _income = monthIncome;
        _expenses = monthExpense;
        _totalBalance = monthIncome - monthExpense; // Current month balance
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      // Handle errors gracefully
      debugPrint('Error refreshing data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            child: RefreshIndicator(
              onRefresh: _refreshFromDb,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              strokeWidth: 3.5,
              displacement: 60.0,
              edgeOffset: 0.0,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
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
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const FilteredTransactionsScreen(
                                      type: 'All',
                                    ),
                              ),
                            );
                            if (mounted) await _refreshFromDb();
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfileScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Current Balance',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AnimatedMoneyText(
                                  value: _totalBalance,
                                  showSign: false,
                                  compact:
                                      false, // Show exact amount like profile screen
                                  style: TextStyle(
                                    color: _totalBalance >= 0
                                        ? Colors.white
                                        : Colors.red.shade300,
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
                                          icon: Icons.arrow_upward_rounded,
                                          key: ValueKey(_income),
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
                                          icon: Icons.arrow_downward_rounded,
                                          key: ValueKey(_expenses),
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
                                    'All Transactions',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FilteredTransactionsScreen(
                                            type: 'All',
                                          ),
                                    ),
                                  );
                                  if (mounted) await _refreshFromDb();
                                },
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  final isIncome =
                                      (tx['type'] as String)
                                          .toLowerCase()
                                          .trim() ==
                                      'income';
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
                                            await _buildTransactionDetailPage(
                                              tx,
                                            );
                                        // ignore: use_build_context_synchronously
                                        await Navigator.push(
                                          // ignore: use_build_context_synchronously
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => page,
                                          ),
                                        );
                                        if (mounted) await _refreshFromDb();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          Colors.white,
                                                        ]
                                                      : [
                                                          AppColors.expense
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          Colors.white,
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                tx['icon'] != null
                                                    ? IconData(
                                                        tx['icon'] as int,
                                                        fontFamily:
                                                            'MaterialIcons',
                                                      )
                                                    : _iconForNote(
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
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                          border: Border.all(
                                                            color: amountColor
                                                                .withValues(
                                                                  alpha: 0.35,
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
                                                      color: AppColors
                                                          .textSecondary,
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
                                                          style:
                                                              const TextStyle(
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
                                                      FormatUtils.formatCurrency(
                                                        tx['amount'] as double,
                                                        compact: true,
                                                      ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: amountColor,
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
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
    Key? key,
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      key: key,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 2),
                AnimatedMoneyText(
                  value: value,
                  compact: false, // Show exact amount
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
