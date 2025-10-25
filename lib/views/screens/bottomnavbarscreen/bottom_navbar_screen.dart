import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/home_screen.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/statistics_screen.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/profile_screen.dart';

class BottomNavbarScreen extends StatefulWidget {
  const BottomNavbarScreen({super.key});

  @override
  State<BottomNavbarScreen> createState() => _BottomNavbarScreenState();
}

class _BottomNavbarScreenState extends State<BottomNavbarScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  double _page = 0;
  bool _dragging = false;
  double _dragIndicatorPage = 0;
  double _dragStartPage = 0;
  double _dragAccumX = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(() {
      final p = _pageController.page ?? _currentIndex.toDouble();
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: const [
              HomeScreen(),
              StatisticsScreen(),
              ProfileScreen(),
            ],
          ),

          // Glassmorphic bottom bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.24), width: 1),
                        boxShadow: const [
                          BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, -4)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.maxWidth;
                          const itemCount = 3;
                          final itemWidth = totalWidth / itemCount;
                          final indicatorWidth = itemWidth - 8;

                          final animatedLeft = (_dragging
                                  ? (_dragIndicatorPage.clamp(0, itemCount - 1) * itemWidth)
                                  : (_page.clamp(0, itemCount - 1) * itemWidth))
                              + 4;

                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) {
                              _dragAccumX = 0;
                              setState(() {
                                _dragging = true;
                                _dragStartPage = _page;
                                _dragIndicatorPage = _page;
                              });
                            },
                            onPanUpdate: (details) {
                              _dragAccumX += details.delta.dx;
                              final deltaPages = _dragAccumX / itemWidth;
                              final double newPage = (_dragStartPage + deltaPages)
                                  .clamp(0.0, (itemCount - 1).toDouble());
                              setState(() {
                                _dragIndicatorPage = newPage;
                              });
                              if (_pageController.hasClients && _pageController.position.haveDimensions) {
                                final w = _pageController.position.viewportDimension;
                                _pageController.position.jumpTo(newPage * w);
                              }
                            },
                            onPanEnd: (details) {
                              final target = _dragIndicatorPage.round();
                              setState(() {
                                _dragging = false;
                              });
                              _goTo(target);
                            },
                            child: SizedBox(
                              height: 48,
                              child: Stack(
                                children: [
                                  // Animated pill indicator behind icons
                                  Positioned(
                                    left: animatedLeft,
                                    top: 4,
                                    width: indicatorWidth,
                                    height: 40,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      curve: Curves.easeOut,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withValues(alpha: 0.38),
                                            AppColors.secondary.withValues(alpha: 0.30),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: AppColors.secondary.withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Icons row (equal width slots, strictly centered)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: itemWidth,
                                        child: Center(
                                          child: _NavIcon(
                                            icon: Icons.home_rounded,
                                            outline: Icons.home_outlined,
                                            selected: (_page.round() == 0),
                                            onTap: () => _goTo(0),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: Center(
                                          child: _NavIcon(
                                            icon: Icons.bar_chart_rounded,
                                            outline: Icons.bar_chart_rounded,
                                            selected: (_page.round() == 1),
                                            onTap: () => _goTo(1),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: Center(
                                          child: _NavIcon(
                                            icon: Icons.person_rounded,
                                            outline: Icons.person_outline_rounded,
                                            selected: (_page.round() == 2),
                                            onTap: () => _goTo(2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goTo(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData outline;
  final bool selected;
  final VoidCallback onTap;
  const _NavIcon({
    required this.icon,
    required this.outline,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            selected ? icon : outline,
            key: ValueKey<bool>(selected),
            size: selected ? 24 : 22,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

