import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showNotificationsAction;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showNotificationsAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final appBarActions = [
      ...?actions,
      if (showNotificationsAction)
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: appBarActions),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _goToSection(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt_rounded),
            label: 'Reportar',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Mis reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _goToSection(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.go('/home');
      case 1:
        return context.go('/report-incident');
      case 2:
        return context.go('/my-reports');
      case 3:
        return context.go('/profile');
    }
  }
}
