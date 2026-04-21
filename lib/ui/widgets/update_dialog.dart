import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final GithubRelease release;

  const UpdateDialog({super.key, required this.release});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _errorMsg;

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMsg = null;
    });

    try {
      await UpdateService.downloadAndInstall(
        widget.release.downloadUrl,
        (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMsg = "Erreur lors du téléchargement. Veuillez réessayer plus tard.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update_alt, color: Colors.blue),
          const SizedBox(width: 10),
          Text('Mise à jour disponible (v${widget.release.version})'),
        ],
      ),
      content: SizedBox(
        width: 600, // Largeur confortable pour le bureau
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nouveautés de cette version :",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Markdown(
                  data: widget.release.body,
                  selectable: true,
                ),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 5),
              Center(child: Text("${(_progress * 100).toStringAsFixed(1)} %")),
            ]
          ],
        ),
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
          ),
        if (!_isDownloading)
          ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download),
            label: const Text('Télécharger et Installer'),
          ),
        if (_isDownloading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Téléchargement en cours...', style: TextStyle(fontStyle: FontStyle.italic)),
          )
      ],
    );
  }
}
