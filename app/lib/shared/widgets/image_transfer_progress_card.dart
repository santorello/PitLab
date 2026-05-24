import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../media/media_upload_state.dart';

class ImageTransferProgressCard extends StatelessWidget {
  const ImageTransferProgressCard({
    required this.label,
    this.progress,
    this.completedCount,
    this.totalCount,
    this.icon = Icons.photo_library_outlined,
    this.stageLabel,
    this.detailsLabel,
    this.batchState,
    super.key,
  });

  final String label;
  final double? progress;
  final int? completedCount;
  final int? totalCount;
  final IconData icon;
  final String? stageLabel;
  final String? detailsLabel;
  final MediaUploadBatchState? batchState;

  @override
  Widget build(BuildContext context) {
    final resolvedProgress = batchState?.progress ?? progress ?? 0;
    final resolvedCompletedCount =
        batchState?.completedCount ?? completedCount ?? 0;
    final resolvedTotalCount = batchState?.totalCount ?? totalCount ?? 1;
    final resolvedStageLabel = batchState?.stageLabel ?? stageLabel;
    final resolvedDetailsLabel =
        batchState?.detailsLabel ??
        detailsLabel ??
        '$resolvedCompletedCount di $resolvedTotalCount immagini pronte';
    final normalized = resolvedProgress.clamp(0, 1).toDouble();
    final percent = (normalized * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD3B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.signalOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (resolvedStageLabel != null && resolvedStageLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.7, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.signalOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resolvedStageLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.steel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: normalized),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFFFE5D4),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.signalOrange,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolvedDetailsLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.steel,
            ),
          ),
        ],
      ),
    );
  }
}
