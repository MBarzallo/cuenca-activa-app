import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cuenca_activa_app/core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    String title = '';
    List<Widget>? actions;

    switch (navigationShell.currentIndex) {
      case 0:
        title = 'cuencaActiva';
        break;
      case 1:
        title = 'Mis reportes';
        break;
      case 2:
        title = 'Perfil';
        break;
    }

    final appBarActions = [
      ...?actions,
      IconButton(
        tooltip: 'Notificaciones',
        onPressed: () => context.push('/notifications'),
        icon: const Icon(Icons.notifications_none_rounded),
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 4,),
            Image.asset("assets/logos/icon_only.png", width: 25),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        actions: appBarActions,
      ),
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 86,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _CuencaBottomNav(navigationShell: navigationShell),
              Positioned(
                top: -12,
                left: 16,
                right: 16,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      SizedBox(
                        width: 60,
                        child: _ReportFab(
                          onPressed: () => context.push('/report-incident'),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CuencaBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _CuencaBottomNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Inicio',
              selected: currentIndex == 0,
              onTap: () => navigationShell.goBranch(
                0,
                initialLocation: currentIndex == 0,
              ),
            ),
            const SizedBox(width: 60), // Space for the Report action inside the bar
            _NavItem(
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment_rounded,
              label: 'Mis reportes',
              selected: currentIndex == 1,
              onTap: () => navigationShell.goBranch(
                1,
                initialLocation: currentIndex == 1,
              ),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Perfil',
              selected: currentIndex == 2,
              onTap: () => navigationShell.goBranch(
                2,
                initialLocation: currentIndex == 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.teal.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: selected ? AppColors.teal : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.teal : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReportFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reportar',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
