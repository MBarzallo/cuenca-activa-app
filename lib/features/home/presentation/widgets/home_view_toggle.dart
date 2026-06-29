import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum HomeViewMode { map, list }

class HomeViewToggle extends StatelessWidget {
  final HomeViewMode value;
  final ValueChanged<HomeViewMode> onChanged;

  const HomeViewToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Mapa',
            icon: Icons.map_outlined,
            selected: value == HomeViewMode.map,
            onTap: () => onChanged(HomeViewMode.map),
          ),
          _ToggleButton(
            label: 'Incidencias',
            icon: Icons.view_agenda_outlined,
            selected: value == HomeViewMode.list,
            onTap: () => onChanged(HomeViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
