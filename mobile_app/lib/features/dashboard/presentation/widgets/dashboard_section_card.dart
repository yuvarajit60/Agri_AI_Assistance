import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                  if (trailing != null) trailing!
                  else if (onTap != null)
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
