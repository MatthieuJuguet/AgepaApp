import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class GithubRelease {
  final String version;
  final String body;
  final String downloadUrl;

  GithubRelease({
    required this.version,
    required this.body,
    required this.downloadUrl,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    String tagName = json['tag_name'] ?? '';
    // Nettoyer la version si elle commence par un 'v'
    if (tagName.toLowerCase().startsWith('v')) {
      tagName = tagName.substring(1);
    }
    
    // Rechercher l'asset .exe (l'installateur)
    String url = '';
    if (json['assets'] != null && json['assets'].isNotEmpty) {
      for (var asset in json['assets']) {
        if (asset['name'].toString().toLowerCase().endsWith('.exe')) {
          url = asset['browser_download_url'];
          break;
        }
      }
    }
    
    return GithubRelease(
      version: tagName,
      body: json['body'] ?? 'Pas de notes de version.',
      downloadUrl: url,
    );
  }
}

class UpdateService {
  // TODO: Remplacer MANUELLEMENT par votre futur compte GitHub et nom de dépôt
  static const String repoOwner = "MonCompte";
  static const String repoName = "AgepaApp";

  static const String apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest";

  /// Vérifie si une MAJ est disponible. Retourne GithubRelease s'il y en a une, sinon null.
  static Future<GithubRelease?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; 

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final release = GithubRelease.fromJson(data);
        
        // S'il n'y a pas de fichier exécutable trouvé dans la release
        if (release.downloadUrl.isEmpty) {
          return null; 
        }

        // Si la version distante est supérieure à la version locale
        if (_isNewerVersion(release.version, currentVersion)) {
          return release;
        }
      }
    } catch (e) {
      // Ignorer l'erreur discrètement en prod (par ex pas d'internet)
      print("Erreur de vérification de mise à jour: $e");
    }
    return null;
  }

  /// Comparaison Sémantique simple (ex: 1.0.1 > 1.0.0)
  static bool _isNewerVersion(String remote, String local) {
    List<int> remoteParts = remote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    List<int> localParts = local.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
        int r = i < remoteParts.length ? remoteParts[i] : 0;
        int l = i < localParts.length ? localParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
    }
    return false; // Equal versions
  }

  /// Télécharge le fichier exécutable et déclenche l'installation silencieuse
  static Future<void> downloadAndInstall(String downloadUrl, Function(double) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // On sauvegarde l'installeur dans le temp cache de l'utilisateur
      final filePath = "${tempDir.path}\\AgepaApp_Update.exe";

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      final contentLength = response.contentLength;
      int bytesDownloaded = 0;
      final file = File(filePath);
      final sink = file.openWrite();

      await response.stream.map((chunk) {
        bytesDownloaded += chunk.length;
        if (contentLength != null && contentLength > 0) {
          onProgress(bytesDownloaded / contentLength);
        }
        return chunk;
      }).pipe(sink);

      await sink.close();

      // On lance le programme téléchargé en mode vraiment silencieux
      await Process.start(filePath, ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/FORCECLOSEAPPLICATIONS']);
      
      // On force la fermeture de notre application Dart pour libérer l'ancien .exe et permettre le remplacement InnoSetup
      exit(0);

    } catch (e) {
      print("Erreur lors du téléchargement ou de l'installation: $e");
      rethrow;
    }
  }
}
