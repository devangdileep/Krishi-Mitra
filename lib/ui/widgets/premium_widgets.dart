import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.04),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final performance = UiPerformance.of(context);
    if (performance.disableAnimations) return RepaintBoundary(child: child);

    final scaledDuration =
        (520 * performance.animationScale).clamp(160, 520).round();
    final scaledDelay =
        (delay.inMilliseconds * performance.animationScale).round();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: scaledDuration + scaledDelay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayed = ((value * (scaledDuration + scaledDelay)) - scaledDelay)
                .clamp(0, scaledDuration) /
            scaledDuration;
        return RepaintBoundary(
          child: Opacity(
            opacity: delayed.toDouble(),
            child: Transform.translate(
              offset: offset * (1 - delayed.toDouble()) * 120,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class PremiumAppBar extends StatelessWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          leading ??
              const Hero(tag: 'krishi-logo', child: KrishiLogo(size: 48)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PremiumMetricCard extends StatelessWidget {
  const PremiumMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = accent ?? colors.primary;
    final dark = colors.brightness == Brightness.dark;
    final performance = UiPerformance.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress ?? 1),
        duration: Duration(
          milliseconds: performance.disableAnimations
              ? 1
              : (850 * performance.animationScale).round(),
        ),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: dark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: tone, size: 20),
                  ),
                  const Spacer(),
                  if (progress != null)
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        value: animatedProgress.clamp(0, 1),
                        strokeWidth: 4,
                        color: tone,
                        backgroundColor: tone.withValues(alpha: 0.16),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    super.key,
    required this.hint,
    this.onTap,
  });

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            Icon(Icons.tune_rounded, color: colors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class FrostedNavigationBar extends StatelessWidget {
  const FrostedNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final navigation = NavigationBar(
      height: 68,
      elevation: 0,
      backgroundColor: Colors.transparent,
      indicatorColor: colors.primaryContainer,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        HapticFeedback.selectionClick();
        onDestinationSelected(index);
      },
      destinations: destinations,
    );

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: dark ? colors.surfaceContainer : Colors.white,
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.26 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme:
                      Theme.of(context).navigationBarTheme.copyWith(
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: selected ? 24 : 22,
                        color:
                            selected ? colors.primary : colors.onSurfaceVariant,
                      );
                    }),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return TextStyle(
                        color:
                            selected ? colors.primary : colors.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 11,
                      );
                    }),
                  ),
                ),
                child: navigation,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassOrbButton extends StatefulWidget {
  const GlassOrbButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final String? tooltip;

  @override
  State<GlassOrbButton> createState() => _GlassOrbButtonState();
}

class _GlassOrbButtonState extends State<GlassOrbButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void didUpdateWidget(covariant GlassOrbButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final performance = UiPerformance.of(context);
    if (widget.active &&
        !performance.disableAnimations &&
        !performance.lowEnd) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final performance = UiPerformance.of(context);
    final button = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = widget.active ? _controller.value : 0.0;
        return Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? colors.primaryContainer : colors.primary,
            boxShadow: [
              if (performance.enableSoftShadows)
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.20 + pulse * 0.08),
                  blurRadius: 14 + pulse * 6,
                  spreadRadius: pulse * 2,
                ),
            ],
            border: Border.all(
              color:
                  dark ? colors.outline : colors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: IconButton(
            tooltip: widget.tooltip,
            onPressed: widget.onPressed,
            icon: AnimatedScale(
              scale: widget.active ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                widget.icon,
                color: dark ? colors.primary : colors.onPrimary,
                size: 28,
              ),
            ),
          ),
        );
      },
    );

    return RepaintBoundary(child: button);
  }
}

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({super.key, this.lines = 3});

  final int lines;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final performance = UiPerformance.of(context);
    if (!performance.enableSkeletonAnimation) {
      if (_controller.isAnimating) _controller.stop();
      return GlassCard(
        child: Column(
          children: List.generate(widget.lines, (index) {
            final width = 1 - index * 0.16;
            return _SkeletonLine(width: width, last: index == widget.lines - 1);
          }),
        ),
      );
    }
    if (!_controller.isAnimating) _controller.repeat();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return GlassCard(
          child: Column(
            children: List.generate(widget.lines, (index) {
              final width = 1 - index * 0.16;
              return _SkeletonLine(
                width: width,
                last: index == widget.lines - 1,
                gradient: LinearGradient(
                  begin: Alignment(-1 + _controller.value * 2, 0),
                  end: Alignment(_controller.value * 2, 0),
                  colors: [
                    colors.surfaceContainerHighest.withValues(alpha: 0.28),
                    colors.primaryContainer.withValues(alpha: 0.34),
                    colors.surfaceContainerHighest.withValues(alpha: 0.28),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.last,
    this.gradient,
  });

  final double width;
  final bool last;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 14,
      margin: EdgeInsets.only(bottom: last ? 0 : 12),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: width.clamp(0.42, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: gradient,
            color: gradient == null
                ? colors.surfaceContainerHighest.withValues(alpha: 0.34)
                : null,
          ),
        ),
      ),
    );
  }
}
