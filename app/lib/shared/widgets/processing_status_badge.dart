import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ProcessingStatusBadge extends StatefulWidget {
  const ProcessingStatusBadge({
    required this.label,
    this.icon = Icons.auto_awesome_outlined,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  State<ProcessingStatusBadge> createState() => _ProcessingStatusBadgeState();
}

class _ProcessingStatusBadgeState extends State<ProcessingStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: AppColors.graphite);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD3B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: Tween<double>(begin: 0, end: 1).animate(_controller),
            child: Icon(widget.icon, size: 16, color: AppColors.signalOrange),
          ),
          const SizedBox(width: 8),
          Text(widget.label, style: textStyle),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final phase = _controller.value * 3;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    final active = phase >= index;
                    return Opacity(
                      opacity: active ? 1 : 0.28,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.signalOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
