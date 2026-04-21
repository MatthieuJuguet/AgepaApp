import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../theme.dart';
import '../../providers/app_state.dart';
import '../../services/data_parser.dart';
import '../../services/pdf_generator.dart';
import '../../services/gmail_service.dart';

class GeneratorPage extends ConsumerStatefulWidget {
  const GeneratorPage({super.key});

  @override
  ConsumerState<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends ConsumerState<GeneratorPage> {
  int _currentStep = 0;
  final TextEditingController _amountController = TextEditingController();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = ref.read(appStateProvider).montant.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          _buildStepProgress(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
              child: _buildStepContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    final steps = ['Configuration', 'Membres', 'Distribution', 'Validation'];
    
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRESSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepItem(i, steps[i]),
            if (i < steps.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
                width: 2,
                height: 24,
                color: i < _currentStep ? AppTheme.success : Colors.black.withValues(alpha: 0.05),
              ),
          ]
        ],
      ),
    );
  }

  Widget _buildStepItem(int index, String label) {
    bool isCompleted = index < _currentStep;
    bool isActive = index == _currentStep;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : (isCompleted ? AppTheme.success : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted ? Colors.transparent : Colors.black.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted 
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Étape ${_currentStep + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(_getStepTitle(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
            if (state.isProcessing)
              const CircularProgressIndicator()
          ],
        ),
        const SizedBox(height: 48),
        Expanded(child: SingleChildScrollView(child: _getStepWidget(state))),
        const SizedBox(height: 32),
        if (!state.isProcessing)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Précédent', style: TextStyle(color: AppTheme.textPrimary)),
                ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _canContinue(state) ? () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _execute(state);
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 3 ? AppTheme.success : AppTheme.primary,
                ),
                child: Text(_currentStep < 3 ? 'Continuer' : 'Lancer le traitement'),
              ),
            ],
          ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Configuration de l\'amicale';
      case 1: return 'Import des médecins';
      case 2: return 'Mode de distribution';
      case 3: return 'Confirmation finale';
      default: return '';
    }
  }

  Widget _getStepWidget(AppState state) {
    switch (_currentStep) {
      case 0: return _buildStep1(state);
      case 1: return _buildStep2(state);
      case 2: return _buildStep3(state);
      case 3: return _buildStep4(state);
      default: return const SizedBox();
    }
  }

  bool _canContinue(AppState state) {
    if (_currentStep == 1) return state.contacts.isNotEmpty;
    if (_currentStep == 2) {
       if (state.distributionMode == DistributionMode.localOnly && state.outputDirPath == null) return false;
       return true;
    }
    return true;
  }

  Widget _buildStep1(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Année de l\'exercice'),
        DropdownButtonFormField<int>(
          initialValue: state.annee,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: List.generate(10, (index) => DateTime.now().year - 2 + index)
              .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: (val) {
            if (val != null) ref.read(appStateProvider.notifier).setAnnee(val);
          },
        ),
        const SizedBox(height: 32),
        _buildFieldLabel('Montant de la cotisation (€)'),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            hintText: 'Ex: 30',
          ),
          onChanged: (val) {
            final num = int.tryParse(val);
            if (num != null) ref.read(appStateProvider.notifier).setMontant(num);
          },
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildStep2(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Veuillez fournir la liste des contacts au format .csv, .xls ou .xlsx.', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 32),
        DropTarget(
          onDragEntered: (details) => setState(() => _isDragging = true),
          onDragExited: (details) => setState(() => _isDragging = false),
          onDragDone: (details) async {
            if (details.files.isNotEmpty) {
              final path = details.files.first.path;
              // Vérifier l'extension
              final ext = path.split('.').last.toLowerCase();
              if (['csv', 'xls', 'xlsx'].contains(ext)) {
                final contacts = await DataParser.parseFile(path);
                ref.read(appStateProvider.notifier).setContacts(contacts, path);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Format de fichier non supporté. Utilisez .csv, .xls ou .xlsx'), backgroundColor: AppTheme.error),
                );
              }
            }
          },
          child: InkWell(
            onTap: () async {
              FilePickerResult? result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv', 'xls', 'xlsx'],
              );
              if (result != null && result.files.single.path != null) {
                final path = result.files.single.path!;
                final contacts = await DataParser.parseFile(path);
                ref.read(appStateProvider.notifier).setContacts(contacts, path);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(64),
              decoration: BoxDecoration(
                color: _isDragging ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDragging ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.2),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isDragging ? Icons.download_rounded : Icons.upload_file_rounded,
                    size: 64,
                    color: state.contacts.isNotEmpty ? AppTheme.success : AppTheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.contacts.isNotEmpty 
                      ? 'Fichier prêt : ${state.inputFilePath!.split('\\').last}'
                      : (_isDragging ? 'Relâchez pour importer' : 'Glisser ou cliquer pour importer'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  if (state.contacts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${state.contacts.length} médecins trouvés', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                    )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(AppState state) {
    return Column(
      children: [
        _buildModeOption(
          mode: DistributionMode.gmailDrafts,
          current: state.distributionMode,
          title: 'Créer des brouillons Gmail',
          subtitle: 'Prépare les e-mails avec pièce jointe dans Gmail pour relecture.',
          icon: Icons.mark_as_unread_outlined,
        ),
        const SizedBox(height: 16),
        _buildModeOption(
          mode: DistributionMode.gmailSend,
          current: state.distributionMode,
          title: 'Envoi direct Gmail',
          subtitle: 'Expédie instantanément les attestations par e-mail.',
          icon: Icons.send_rounded,
        ),
        const SizedBox(height: 16),
        _buildModeOption(
          mode: DistributionMode.localOnly,
          current: state.distributionMode,
          title: 'Sauvegarde locale uniquement',
          subtitle: 'Enregistre les PDF sur votre ordinateur sans envoyer d\'e-mails.',
          icon: Icons.folder_copy_outlined,
        ),
        if (state.distributionMode == DistributionMode.localOnly) ...[
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                  child: Text(state.outputDirPath ?? 'Aucun dossier de destination sélectionné', style: TextStyle(color: state.outputDirPath == null ? AppTheme.textSecondary : AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  String? path = await FilePicker.getDirectoryPath();
                  if (path != null) ref.read(appStateProvider.notifier).setOutputDir(path);
                },
                child: const Text('Choisir'),
              )
            ],
          )
        ]
      ],
    );
  }

  Widget _buildModeOption({required DistributionMode mode, required DistributionMode current, required String title, required String subtitle, required IconData icon}) {
    bool selected = mode == current;
    return InkWell(
      onTap: () => ref.read(appStateProvider.notifier).setDistributionMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primary : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: selected ? AppTheme.primary : AppTheme.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  bool _isCancelled = false;

  Widget _buildStep4(AppState state) {
    if (state.isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 32),
            Text(state.statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: 400,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: state.progress, minHeight: 8),
              ),
            ),
            const SizedBox(height: 8),
            Text('${(state.progress * 100).toInt()}%', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: () {
                _isCancelled = true;
                ref.read(appStateProvider.notifier).stopProcessing();
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Annuler l\'opération'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RÉCAPITULATIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildInfoChip(Icons.calendar_today, 'Année', state.annee.toString()),
        _buildInfoChip(Icons.euro, 'Montant', '${state.montant} € par personne'),
        _buildInfoChip(Icons.people_outline, 'Destinataires', '${state.contacts.length} médecins identifiés'),
        _buildInfoChip(Icons.alt_route, 'Mode choisi', state.distributionMode.toString().split('.').last),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primary),
              SizedBox(width: 16),
              Expanded(child: Text('L\'opération peut prendre quelques minutes selon le nombre d\'attestations à générer et les quotas de votre compte Gmail.')),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Text('$label :', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _execute(AppState state) async {
    final notifier = ref.read(appStateProvider.notifier);
    notifier.setProcessingStatus(true);
    _isCancelled = false;
    
    try {
      final isGmail = state.distributionMode != DistributionMode.localOnly;
      if (isGmail) {
        notifier.setProcessingProgress(0.05, 'Vérification de la connexion Gmail...');
        
        // On ajoute un timeout pour ne pas rester bloqué si l'utilisateur ne répond pas
        bool authed = await GmailService.ensureAuthenticated().timeout(
          const Duration(minutes: 5),
          onTimeout: () => throw Exception("L'authentification a pris trop de temps. Opération annulée."),
        );
        
        if (!authed) throw Exception("Connexion Gmail manquante ou annulée.");
      }

      if (_isCancelled) return;

      String? outputDir = state.outputDirPath;
      if (outputDir == null) {
        final docs = Platform.environment['USERPROFILE'] ?? Directory.current.path;
        outputDir = '$docs\\Documents\\AGEPA_${state.annee}';
        final dir = Directory(outputDir);
        if (!await dir.exists()) await dir.create(recursive: true);
      }

      List<String> errors = [];
      int successCount = 0;

      for (int i = 0; i < state.contacts.length; i++) {
        if (_isCancelled) {
          notifier.setProcessingProgress(0, 'Annulation en cours...');
          break;
        }

        final contact = state.contacts[i];
        try {
        double progress = 0.1 + (i / state.contacts.length) * 0.9;
        notifier.setProcessingProgress(progress, 'Traitement : Dr. ${contact.nom}');

        final safeNom = contact.nom.replaceAll(' ', '_').replaceAll("'", '_');
        final safePrenom = contact.prenom.replaceAll(' ', '_');
        final pdfPath = '$outputDir\\AGEPA_${state.annee}_Cotisation_${safeNom}_$safePrenom.pdf';

        final pdfFile = await PdfGenerator.generateAttestation(
          path: pdfPath,
          nom: contact.nom.toUpperCase(),
          prenom: contact.prenom,
          annee: state.annee.toString(),
          montant: state.montant.toString(),
        );

          if (isGmail) {
            final bodyText =
                "Bonjour Docteur ${contact.nom.toUpperCase()},\n\nVeuillez trouver en pièce jointe votre attestation de cotisation à l'AGEPA pour l'année ${state.annee}.\n\nNous vous remercions de votre confiance.\n\nBien cordialement,\n\nDocteur F Juguet\nTrésorier";

            if (contact.email.isEmpty || !contact.email.contains('@')) {
              throw Exception("Email invalide ou manquant");
            }

            await GmailService.sendOrDraft(
              recipient: contact.email,
              subject:
                  "Attestation AGEPA ${state.annee} - Dr ${contact.prenom} ${contact.nom.toUpperCase()}",
              body: bodyText,
              attachment: pdfFile,
              isDraft: state.distributionMode == DistributionMode.gmailDrafts,
            );

            // Petit délai pour éviter d'être bloqué par les quotas Gmail sur de gros volumes
            await Future.delayed(const Duration(milliseconds: 800));
          }
          successCount++;
        } catch (e) {
          errors.add("Dr. ${contact.nom}: $e");
        }
      }

      if (_isCancelled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opération annulée par l\'utilisateur.')),
          );
        }
      } else {
        if (errors.isEmpty) {
          notifier.setProcessingProgress(
            1.0,
            'Succès ! Toutes les attestations ($successCount) sont prêtes.',
          );
        } else {
          notifier.setProcessingProgress(
            1.0,
            'Terminé avec ${errors.length} erreur(s) sur ${state.contacts.length}.',
          );
        }

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _currentStep = 0);

        if (mounted) {
          if (errors.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opération terminée avec succès.'),
                backgroundColor: AppTheme.success,
              ),
            );
          } else {
            // Afficher une boîte de dialogue avec les erreurs
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('${errors.length} erreur(s) rencontrée(s)'),
                content: SizedBox(
                  width: 400,
                  height: 300,
                  child: ListView.builder(
                    itemCount: errors.length,
                    itemBuilder: (c, idx) => ListTile(
                      leading: const Icon(Icons.error_outline, color: AppTheme.error),
                      title: Text(errors[idx], style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Compris'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      notifier.setProcessingStatus(false);
    }
  }
}
