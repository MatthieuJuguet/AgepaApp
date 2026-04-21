import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/app_state.dart';
import '../../services/gmail_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres & Compte',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez vos accès et les informations de l\'association.',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 48),
            const Text(
              'COMPTE GOOGLE / GMAIL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAccountCard(context, ref, user, state.isAuthenticating),
            const SizedBox(height: 48),
            const Text(
              'INFORMATIONS DE L\'ASSOCIATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
    bool isAuthenticating,
  ) {
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
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: user?.pictureUrl != null
                    ? NetworkImage(user!.pictureUrl!)
                    : null,
                child: user?.pictureUrl == null
                    ? const Icon(
                        Icons.person_outline,
                        size: 30,
                        color: AppTheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Non connecté',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ??
                          'Connectez-vous pour envoyer des e-mails via Gmail',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (user != null)
                TextButton.icon(
                  onPressed: () async {
                    await GmailService.signOut();
                    ref.read(appStateProvider.notifier).setUser(null);
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(color: AppTheme.error),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: isAuthenticating
                      ? null
                      : () async {
                          ref
                              .read(appStateProvider.notifier)
                              .setAuthenticating(true);
                          final profile = await GmailService.authenticate();
                          ref.read(appStateProvider.notifier).setUser(profile);
                          ref
                              .read(appStateProvider.notifier)
                              .setAuthenticating(false);
                        },
                  icon: isAuthenticating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    isAuthenticating
                        ? 'Connexion...'
                        : 'Se connecter avec Google',
                  ),
                ),
            ],
          ),
          if (user == null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'L\'envoi automatique et la mise en brouillon nécessitent une connexion Gmail active.',
                      style: TextStyle(fontSize: 13, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Nom de l\'Association', 'AGEPA'),
          const Divider(height: 32),
          _buildInfoRow('Siège Social', '159 Bd Godard, 33110 Le Bouscat'),
          const Divider(height: 32),
          _buildInfoRow('Président', 'Docteur Ph. Hemery'),
          const Divider(height: 32),
          _buildInfoRow('Secrétaires', 'Dr M. Eleouet, Dr Ndobo-Epoy'),
          const Divider(height: 32),
          _buildInfoRow('Trésoriers', 'Dr J-P Vove, Dr F Juguet'),
          const Divider(height: 32),
          _buildInfoRow('Version de l\'App', '2.0.0 (Professional Build)'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
