import 'package:flutter/material.dart';
import '../models/watch_now_video.dart';
import '../theme/watch_now_theme.dart';

class CategoryChips extends StatelessWidget {
  final List<WatchNowCategoryItem> categories;
  final WatchNowCategory selected;
  final ValueChanged<WatchNowCategoryItem> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = item.type == selected;
          return _Chip(
            label: item.label,
            selected: isSelected,
            onTap: () => onSelected(item),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? WatchNowColors.chipSelectedBg
              : WatchNowColors.chipUnselectedBg,
          borderRadius: BorderRadius.circular(WatchNowRadius.chip),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : WatchNowColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
