import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String name;
  final String email;
  final String? pictureUrl;

  UserProfile({required this.name, required this.email, this.pictureUrl});
}

class Contact {
  final String nom;
  final String prenom;
  final String email;

  Contact({required this.nom, required this.prenom, required this.email});

  @override
  String toString() => '$prenom $nom ($email)';
}

enum DistributionMode {
  localOnly,
  gmailDrafts,
  gmailSend,
}

enum AppTab {
  dashboard,
  generator,
  settings,
}

class AppState {
  final AppTab currentTab;
  final int annee;
  final int montant;
  final List<Contact> contacts;
  final String? inputFilePath;
  final String? outputDirPath;
  final DistributionMode distributionMode;
  final bool isAuthenticating;
  final UserProfile? currentUser;
  final bool isProcessing;
  final double progress;
  final String statusMessage;

  AppState({
    this.currentTab = AppTab.dashboard,
    this.annee = 2026,
    this.montant = 30,
    this.contacts = const [],
    this.inputFilePath,
    this.outputDirPath,
    this.distributionMode = DistributionMode.gmailDrafts,
    this.isAuthenticating = false,
    this.currentUser,
    this.isProcessing = false,
    this.progress = 0.0,
    this.statusMessage = '',
  });

  AppState copyWith({
    AppTab? currentTab,
    int? annee,
    int? montant,
    List<Contact>? contacts,
    String? inputFilePath,
    String? outputDirPath,
    DistributionMode? distributionMode,
    bool? isAuthenticating,
    UserProfile? currentUser,
    bool? isProcessing,
    double? progress,
    String? statusMessage,
    bool clearUser = false,
  }) {
    return AppState(
      currentTab: currentTab ?? this.currentTab,
      annee: annee ?? this.annee,
      montant: montant ?? this.montant,
      contacts: contacts ?? this.contacts,
      inputFilePath: inputFilePath ?? this.inputFilePath,
      outputDirPath: outputDirPath ?? this.outputDirPath,
      distributionMode: distributionMode ?? this.distributionMode,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() => AppState(annee: DateTime.now().year);

  void setTab(AppTab tab) => state = state.copyWith(currentTab: tab);
  
  void setAnnee(int annee) => state = state.copyWith(annee: annee);
  
  void setMontant(int montant) => state = state.copyWith(montant: montant);
  
  void setContacts(List<Contact> contacts, String filePath) {
    state = state.copyWith(contacts: contacts, inputFilePath: filePath);
  }
  
  void setOutputDir(String path) => state = state.copyWith(outputDirPath: path);
  
  void setDistributionMode(DistributionMode mode) => state = state.copyWith(distributionMode: mode);
  
  void setAuthenticating(bool isAuthenticating) {
    state = state.copyWith(isAuthenticating: isAuthenticating);
  }

  void setUser(UserProfile? user) {
    if (user == null) {
      state = state.copyWith(clearUser: true);
    } else {
      state = state.copyWith(currentUser: user);
    }
  }
  
  void setProcessingProgress(double progress, String message) {
    state = state.copyWith(progress: progress, statusMessage: message);
  }
  
  void setProcessingStatus(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }

  void stopProcessing() {
    state = state.copyWith(
      isProcessing: false,
      progress: 0.0,
      statusMessage: 'Opération annulée.',
    );
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(() {
  return AppStateNotifier();
});
