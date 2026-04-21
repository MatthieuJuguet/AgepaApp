import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/app_state.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue sur l\'outil AGEPA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez vos attestations de cotisation en quelques clics.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                _buildQuickAction(
                  context,
                  title: 'Générer des attestations',
                  subtitle: 'Lancez le processus complet de génération et d\'envoi.',
                  icon: Icons.description_outlined,
                  color: AppTheme.primary,
                  onTap: () => ref.read(appStateProvider.notifier).setTab(AppTab.generator),
                ),
                const SizedBox(width: 24),
                _buildQuickAction(
                  context,
                  title: 'Configurer les comptes',
                  subtitle: 'Gérez vos accès Gmail et informations de l\'amicale.',
                  icon: Icons.settings_outlined,
                  color: AppTheme.textSecondary,
                  onTap: () => ref.read(appStateProvider.notifier).setTab(AppTab.settings),
                ),
              ],
            ),
            const SizedBox(height: 48),
            const Text(
              'État du système',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusCard(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.currentUser;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIndicator(user != null),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connexion Gmail', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(user != null ? 'Connecté en tant que ${user.email}' : 'Déconnecté - Authentification requise pour l\'envoi'),
                ],
              ),
            ],
          ),
          if (state.contacts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              children: [
                _buildIndicator(true),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Données chargées', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${state.contacts.length} médecins identifiés dans ${state.inputFilePath?.split('\\').last}'),
                  ],
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildIndicator(bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppTheme.success : AppTheme.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (active ? AppTheme.success : AppTheme.error).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
    );
  }
}
