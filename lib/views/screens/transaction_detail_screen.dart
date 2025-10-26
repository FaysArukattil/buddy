import 'package:flutter/material.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/utils/images.dart';
import 'package:flutter/animation.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const TransactionDetailScreen({super.key, required this.data});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  bool get _isIncome => (widget.data['type'] as String) == 'income';

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _bobAnimation = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));
    _bobController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _isIncome ? AppColors.income : AppColors.expense;
    final String amountPrefix = _isIncome ? '+' : '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(child: Image.asset(AppImages.curvedBackground, fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.24),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Transaction Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Animated top info card with avatar + chips + subtitle info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AnimatedBuilder(
                            animation: _bobAnimation,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _bobAnimation.value),
                              child: child,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white70, width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white,
                                    child: _avatarChild(widget.data),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: accent.withOpacity(0.35)),
                                              ),
                                              child: Text(
                                                _isIncome ? 'Income' : 'Expense',
                                                style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          (widget.data['title'] as String?) ?? 'Transaction',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.category_rounded, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                (widget.data['category'] as String?) ?? '-',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              (widget.data['time'] as String?) ?? '-',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(Icons.event_rounded, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate((widget.data['date'] as DateTime?) ?? DateTime.now()),
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Details card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white70, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Transaction details',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 10),
                                _detailRow('Status', _isIncome ? 'Income' : 'Expense',
                                    valueColor: _isIncome ? AppColors.income : AppColors.expense),
                                _detailRow('Category', (widget.data['category'] as String?) ?? '-'),
                                _detailRow('Time', (widget.data['time'] as String?) ?? '-'),
                                _detailRow('Date', _formatDate((widget.data['date'] as DateTime?) ?? DateTime.now())),
                                _detailRow('Note', (widget.data['note'] as String?)?.trim().isNotEmpty == true
                                    ? widget.data['note'] as String
                                    : '-'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Big amount centered before download
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '$amountPrefix${_formatCurrency((widget.data['amount'] as double?) ?? 0)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Animated themed Download button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AnimatedBuilder(
                            animation: _bobAnimation,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _bobAnimation.value / 2),
                              child: child,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.88),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 8,
                                  shadowColor: const Color(0x33000000),
                                ),
                                onPressed: () {},
                                child: const Text(
                                  'Download',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _avatarChild(Map<String, dynamic> data) {
    final String text = (data['avatarText'] as String? ?? '?').toUpperCase();
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatCurrency(double v) => '\$' + v.toStringAsFixed(2);
}
