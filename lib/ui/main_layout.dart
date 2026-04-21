import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/app_state.dart';
import 'pages/dashboard_page.dart';
import 'pages/generator_page.dart';
import 'pages/settings_page.dart';
import '../services/update_service.dart';
import 'widgets/update_dialog.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  void _checkForUpdates() async {
    final release = await UpdateService.checkForUpdates();
    if (release != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(release: release),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          _Sidebar(currentTab: state.currentTab),
          Expanded(
            child: _MainContent(currentTab: state.currentTab),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final AppTab currentTab;

  const _Sidebar({required this.currentTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _SidebarHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Tableau de bord',
                    isActive: currentTab == AppTab.dashboard,
                    onTap: () => ref.read(appStateProvider.notifier).setTab(AppTab.dashboard),
                  ),
                  const SizedBox(height: 8),
                  _SidebarItem(
                    icon: Icons.description_outlined,
                    label: 'Générateur d\'attestations',
                    isActive: currentTab == AppTab.generator,
                    onTap: () => ref.read(appStateProvider.notifier).setTab(AppTab.generator),
                  ),
                  const Spacer(),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Paramètres & Compte',
                    isActive: currentTab == AppTab.settings,
                    onTap: () => ref.read(appStateProvider.notifier).setTab(AppTab.settings),
                  ),
                ],
              ),
            ),
          ),
          _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          const Text(
            'AGEPA',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).currentUser;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
              backgroundImage: user?.pictureUrl != null ? NetworkImage(user!.pictureUrl!) : null,
              child: user?.pictureUrl == null 
                  ? Text(user?.name[0] ?? '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Non connecté',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user != null ? 'Gmail Connecté' : 'Accès limité',
                    style: TextStyle(fontSize: 10, color: user != null ? AppTheme.success : AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final AppTab currentTab;

  const _MainContent({required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _getPage(currentTab),
    );
  }

  Widget _getPage(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return const DashboardPage(key: ValueKey('dashboard'));
      case AppTab.generator:
        return const GeneratorPage(key: ValueKey('generator'));
      case AppTab.settings:
        return const SettingsPage(key: ValueKey('settings'));
    }
  }
}
