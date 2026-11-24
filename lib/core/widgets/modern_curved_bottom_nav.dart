import 'package:material_ui/material_ui.dart';

/// Somaflow Sage Green & Warm Parchment Navigation Tokens
class SomaflowNavTheme {
  // Active elevated pill & icon
  static const Color activeIndicator = Color(0xFF51644F); // Deep Forest Sage
  static const Color activeIcon = Colors.white;
  static const Color activeBorder = Color(0xFFFCFAF7);

  // Bar container surface & border
  static const Color barBackground = Color(0xF8FCFAF7); // Frosted Oatmeal
  static const Color barBorder = Color(0xFFD6DDD4); // Soft Herbal Ring
  static const Color barShadow = Color(0xFF384736); // Subtle Sage Ambient Shadow

  // Inactive icons
  static const Color inactiveIcon = Color(0xFF7C8D7A); // Muted Herbal Sage
}

class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const employeeBottomNavItems = [
  BottomNavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  BottomNavItem(
    icon: Icons.timer_outlined,
    activeIcon: Icons.timer_rounded,
    label: 'Attendance',
  ),
  BottomNavItem(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    label: 'Requests',
  ),
  BottomNavItem(
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label: 'Calendar',
  ),
  BottomNavItem(
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
    label: 'Payslip',
  ),
];

class ModernCurvedBottomNavBar extends StatefulWidget {
  const ModernCurvedBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  }) : assert(items.length > 0),
       assert(currentIndex >= 0 && currentIndex < items.length);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  @override
  State<ModernCurvedBottomNavBar> createState() =>
      _ModernCurvedBottomNavBarState();
}

class _ModernCurvedBottomNavBarState extends State<ModernCurvedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _selectedPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _selectedPosition = AlwaysStoppedAnimation<double>(
      widget.currentIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(ModernCurvedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;

    final currentPosition = _selectedPosition.value;
    _selectedPosition = Tween<double>(
      begin: currentPosition,
      end: widget.currentIndex.toDouble(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const indicatorSize = 56.0;
          const barHeight = 58.0;
          final itemWidth = constraints.maxWidth / widget.items.length;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final indicatorCenter =
                  itemWidth * (_selectedPosition.value + 0.5);

              return SizedBox(
                height: 78,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- Curved Notched Background Bar ---
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 18,
                      child: SizedBox(
                        height: barHeight,
                        child: CustomPaint(
                          painter: _NotchedNavBarPainter(
                            indicatorCenter: indicatorCenter,
                          ),
                        ),
                      ),
                    ),

                    // --- Unselected Navigation Icons ---
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 18,
                      bottom: 0,
                      child: Row(
                        children: List.generate(widget.items.length, (index) {
                          return Expanded(
                            child: _BottomNavItem(
                              item: widget.items[index],
                              isSelected: widget.currentIndex == index,
                              onTap: () => widget.onTap(index),
                            ),
                          );
                        }),
                      ),
                    ),

                    // --- Elevated Active Indicator with Notch Fit ---
                    Positioned(
                      left: indicatorCenter - indicatorSize / 2,
                      top: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: indicatorSize,
                          height: indicatorSize,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6B8268), // Sage Primary
                                Color(0xFF51644F), // Deep Forest Sage
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SomaflowNavTheme.activeBorder,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SomaflowNavTheme.barShadow.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.items[widget.currentIndex].activeIcon,
                            color: SomaflowNavTheme.activeIcon,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotchedNavBarPainter extends CustomPainter {
  const _NotchedNavBarPainter({required this.indicatorCenter});

  final double indicatorCenter;

  @override
  void paint(Canvas canvas, Size size) {
    const cornerRadius = 28.0;
    const notchRadius = 34.0;
    const notchCenterY = -8.0;

    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(cornerRadius),
        ),
      );
    final notch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(indicatorCenter, notchCenterY),
          radius: notchRadius,
        ),
      );
    final shape = Path.combine(PathOperation.difference, bar, notch);

    // Soft organic sage shadow
    canvas.drawShadow(
      shape,
      SomaflowNavTheme.barShadow.withValues(alpha: 0.45),
      8,
      true,
    );

    // Frosted parchment fill
    canvas.drawPath(
      shape,
      Paint()
        ..color = SomaflowNavTheme.barBackground
        ..style = PaintingStyle.fill,
    );

    // Subtle herbal outline stroke
    canvas.drawPath(
      shape,
      Paint()
        ..color = SomaflowNavTheme.barBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_NotchedNavBarPainter oldDelegate) =>
      oldDelegate.indicatorCenter != indicatorCenter;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: isSelected ? 0 : 1,
              child: Icon(
                item.icon,
                size: 21,
                color: SomaflowNavTheme.inactiveIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}