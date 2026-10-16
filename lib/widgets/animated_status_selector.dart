import 'package:flutter/material.dart';
import '../models/daily_log.dart';
import '../theme/app_theme.dart';

class AnimatedStatusSelector extends StatelessWidget {
  final DayStatus selectedStatus;
  final ValueChanged<DayStatus> onStatusChanged;

  const AnimatedStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: DayStatus.values.map((status) {
            final isSelected = status == selectedStatus;
            final color = status.color;

            return GestureDetector(
              onTap: () => onStatusChanged(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: cardWidth,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : AppColors.divider,
                    width: isSelected ? 2.2 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status.icon,
                          color: isSelected ? Colors.white : color,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.arabicLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : AppColors.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
