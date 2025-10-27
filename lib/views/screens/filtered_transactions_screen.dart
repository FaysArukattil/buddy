import 'package:flutter/material.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/utils/format_utils.dart';
import 'package:buddy/repositories/transaction_repository.dart';
import 'package:buddy/views/screens/transaction_detail_screen.dart';

class FilteredTransactionsScreen extends StatefulWidget {
  final String type; // 'income' or 'expense'
  
  const FilteredTransactionsScreen({super.key, required this.type});

  @override
  State<FilteredTransactionsScreen> createState() => _FilteredTransactionsScreenState();
}

class _FilteredTransactionsScreenState extends State<FilteredTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final TransactionRepository _repo;
  List<Map<String, Object?>> _allRows = [];
  List<Map<String, dynamic>> _displayedTransactions = [];
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  double _total = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _load();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final rows = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _allRows = rows;
      _isLoading = false;
    });
    _filterByMonth();
  }

  void _filterByMonth() {
    final filtered = _allRows.where((r) {
      final type = (r['type'] as String).toLowerCase();
      if (widget.type.toLowerCase() != type) return false;
      
      final dt = DateTime.tryParse(r['date'] as String) ?? DateTime.now();
      return dt.year == _currentMonth.year && dt.month == _currentMonth.month;
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] as String) ?? DateTime.now();
      final dateB = DateTime.tryParse(b['date'] as String) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    double total = 0;
    final displayed = filtered.map((r) {
      final dt = DateTime.tryParse(r['date'] as String) ?? DateTime.now();
      final amt = (r['amount'] as num).toDouble();
      total += amt;
      return {
        'type': r['type'],
        'title': (r['note'] as String?)?.isNotEmpty == true ? r['note'] : r['category'],
        'subtitle': r['category'],
        'amount': amt,
        'time': _formatTime(dt),
        'date': dt,
        'category': r['category'],
        'note': r['note'],
        'avatarText': (r['category'] as String?)?.substring(0, 1) ?? '?',
        'icon': r['icon'],
        'id': r['id'],
      };
    }).toList();

    setState(() {
      _displayedTransactions = displayed;
      _total = total;
    });
  }

  void _previousMonth() {
    if (_animController.isAnimating) return;
    _animController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });
      _filterByMonth();
      _animController.forward();
    });
  }

  void _nextMonth() {
    if (_animController.isAnimating) return;
    _animController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });
      _filterByMonth();
      _animController.forward();
    });
  }

  String _formatTime(DateTime d) {
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute $ampm';
  }

  String _formatCurrency(double v) => FormatUtils.formatCurrency(v, compact: true);

  String _formatTxDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _monthYearLabel() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  IconData _iconForNote(String? note) {
    final n = (note ?? '').toLowerCase();
    if (n.contains('coffee') || n.contains('cafe') || n.contains('drink') || n.contains('food') || n.contains('snack')) {
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
    if (n.contains('netflix') || n.contains('hotstar') || n.contains('youtube') || n.contains('movie')) {
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
    if (n.contains('salary') || n.contains('upwork') || n.contains('payment') || n.contains('pay')) {
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
    if (n.contains('medical') || n.contains('doctor') || n.contains('hospital')) {
      return Icons.medical_services_rounded;
    }
    if (n.contains('school') || n.contains('tuition') || n.contains('education')) {
      return Icons.school_rounded;
    }
    if (n.contains('game') || n.contains('esports')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type.toLowerCase() == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Animated Header
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                      Expanded(
                        child: Text(
                          widget.type,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _previousMonth,
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                          ),
                          Text(
                            _monthYearLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: _nextMonth,
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatCurrency(_total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Transactions list with animation
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  // Lower threshold for more responsive swiping
                  if (details.primaryVelocity! < -100) {
                    // Swipe left -> next month
                    _nextMonth();
                  } else if (details.primaryVelocity! > 100) {
                    // Swipe right -> previous month
                    _previousMonth();
                  }
                }
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _displayedTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${widget.type.toLowerCase()} transactions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'for ${_monthYearLabel()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _displayedTransactions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tx = _displayedTransactions[index];
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TransactionDetailScreen(data: tx),
                                        ),
                                      );
                                      if (mounted) await _load();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                colors: [
                                                  amountColor.withOpacity(0.15),
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
                                                      fontFamily: 'MaterialIcons',
                                                    )
                                                  : _iconForNote(tx['note'] as String?),
                                              size: 24,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tx['title'] as String,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  tx['subtitle'] as String,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 13,
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
                                                (isIncome ? '+' : '-') + _formatCurrency(tx['amount'] as double),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: amountColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTxDate(tx['date'] as DateTime),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textLight,
                                                ),
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
            ),
          ),
        ],
      ),
    );
  }
}
