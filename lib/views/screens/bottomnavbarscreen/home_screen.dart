import 'package:buddy/utils/images.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/profile_screen.dart';
import 'package:buddy/views/screens/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _displayName = '';
  double _totalBalance = 0;
  double _income = 0;
  double _expenses = 0;
  late final AnimationController _controller;
  late final Animation<double> _bobAnimation;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _txSectionKey = GlobalKey();
  bool _showRecentBadge = false;
  final List<Map<String, dynamic>> _dummyTransactions = [
    {
      'type': 'income',
      'title': 'Upwork Escrow',
      'subtitle': 'Invoice #UP-2043',
      'amount': 850.00,
      'time': '10:00 AM',
      'date': DateTime(2022, 2, 28),
      'category': 'Salary',
      'note': 'Payment from Upwork',
      'earnings': 870.00,
      'fee': 20.00,
      'avatarText': 'Up',
    },
    {
      'type': 'expense',
      'title': 'Claire Jovalski',
      'subtitle': 'Coffee Meetup',
      'amount': 85.00,
      'time': '04:30 PM',
      'date': DateTime(2024, 2, 29),
      'category': 'Food & Drinks',
      'note': 'Coffee and snacks',
      'spending': 85.00,
      'fee': 0.99,
      'avatarText': 'CJ',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  void _goToRecent() async {
    if (_txSectionKey.currentContext == null) return;
    setState(() => _showRecentBadge = true);
    await Future.delayed(const Duration(milliseconds: 50));
    final box = _txSectionKey.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final target = _scrollController.offset + offset.dy - 100;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showRecentBadge = false);
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
    final email = prefs.getString('email') ?? '';
    // Use first portion of email (before '@').
    String firstPart = '';
    if (email.contains('@')) {
      firstPart = email.split('@').first;
    } else {
      firstPart = email;
    }
    // Capitalize first letter for nicer display
    if (firstPart.isNotEmpty) {
      firstPart = firstPart[0].toUpperCase() + firstPart.substring(1);
    }
    setState(() {
      _displayName = firstPart;
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
  Widget build(BuildContext context) {
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
                                    onTap: _goToRecent,
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
                                  child: _statTile(
                                    label: 'Expenses',
                                    value: _expenses,
                                    color: AppColors.expense,
                                    icon: Icons.arrow_upward_rounded,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
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
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white70, width: 1),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        itemCount: _dummyTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = _dummyTransactions[index];
                          final isIncome = tx['type'] == 'income';
                          final amountColor = isIncome ? AppColors.income : AppColors.expense;
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final page = await _buildTransactionDetailPage(tx);
                                // ignore: use_build_context_synchronously
                                Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white70),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: isIncome
                                              ? [AppColors.income.withOpacity(0.15), Colors.white]
                                              : [AppColors.expense.withOpacity(0.15), Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        (tx['avatarText'] as String?)?.toUpperCase() ?? '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: amountColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(color: amountColor.withOpacity(0.35)),
                                                ),
                                                child: Text(
                                                  isIncome ? 'Income' : 'Expense',
                                                  style: TextStyle(color: amountColor, fontSize: 10, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  tx['title'] as String,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tx['subtitle'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.category_rounded, size: 12, color: AppColors.textLight),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  (tx['category'] as String?) ?? '-',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          (isIncome ? '+' : '-') + _formatCurrency(tx['amount'] as double),
                                          style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              _formatTxDate(tx['date'] as DateTime),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              tx['time'] as String,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
