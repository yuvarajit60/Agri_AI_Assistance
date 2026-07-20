import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Visualizes the `confidence_score` carried by every recommendation in
/// the platform's Standard Output Contract (docs/architecture/ARCHITECTURE.md
/// §9) so the farmer always sees how trustworthy a figure is, not just the
/// figure itself.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.score, this.compact = false});

  /// 0.0 - 1.0
  final double score;
  final bool compact;

  Color get _color {
    if (score >= 0.75) return AppColors.confidenceHigh;
    if (score >= 0.5) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }

  String get _label {
    if (score >= 0.75) return 'High confidence';
    if (score >= 0.5) return 'Medium confidence';
    return 'Low confidence';
  }

  @override
  Widget build(BuildContext context) {
    final pct = '${(score * 100).round()}%';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? pct : '$_label · $pct',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
