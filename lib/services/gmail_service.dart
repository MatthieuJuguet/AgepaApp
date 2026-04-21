import 'dart:convert';
import 'dart:io';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import 'secrets.dart';

class GmailService {
  // REMPLACEZ ces valeurs par vos propres identifiants Google Cloud Console
  // NE JAMAIS committer de vrais secrets sur GitHub !
  static const _clientId = GMAIL_CLIENT_ID;
  static const _clientSecret = GMAIL_CLIENT_SECRET;

  static final _scopes = [
    GmailApi.gmailModifyScope,
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  static AuthClient? _authClient;
  static GmailApi? _gmailApi;

  static Future<UserProfile?> authenticate() async {
    try {
      final clientId = ClientId(_clientId, _clientSecret);

      _authClient = await clientViaUserConsent(clientId, _scopes, (url) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      });

      if (_authClient != null) {
        _gmailApi = GmailApi(_authClient!);
        return await getUserProfile();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<UserProfile?> getUserProfile() async {
    if (_authClient == null) return null;
    try {
      final oauth2 = Oauth2Api(_authClient!);
      final info = await oauth2.userinfo.get();
      return UserProfile(
        name: info.name ?? info.givenName ?? 'Utilisateur',
        email: info.email ?? 'Non définie',
        pictureUrl: info.picture,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    _authClient?.close();
    _authClient = null;
    _gmailApi = null;
  }

  static Future<bool> ensureAuthenticated() async {
    if (_gmailApi == null) {
      final profile = await authenticate();
      return profile != null;
    }
    return true;
  }

  static Future<void> sendOrDraft({
    required String recipient,
    required String subject,
    required String body,
    required File attachment,
    required bool isDraft,
  }) async {
    if (!await ensureAuthenticated()) throw Exception("Non authentifié");

    final rawMessage = await _createMimeMessage(
      recipient,
      subject,
      body,
      attachment,
    );

    final msg = Message()..raw = rawMessage;

    if (isDraft) {
      final draft = Draft()..message = msg;
      await _gmailApi!.users.drafts.create(draft, 'me');
    } else {
      await _gmailApi!.users.messages.send(msg, 'me');
    }
  }

  static Future<String> _createMimeMessage(
    String to,
    String subject,
    String bodyText,
    File pdfFile,
  ) async {
    final pdfBytes = await pdfFile.readAsBytes();
    final pdfBase64 = base64Encode(pdfBytes);
    final filename = pdfFile.path.split(Platform.pathSeparator).last;

    final boundary = '----=_Part_${DateTime.now().millisecondsSinceEpoch}';
    final mime = StringBuffer();

    mime.writeln('To: $to');
    mime.writeln('Subject: =?utf-8?B?${base64Encode(utf8.encode(subject))}?=');
    mime.writeln('MIME-Version: 1.0');
    mime.writeln('Content-Type: multipart/mixed; boundary="$boundary"');
    mime.writeln();

    mime.writeln('--$boundary');
    mime.writeln('Content-Type: text/plain; charset=UTF-8');
    mime.writeln('Content-Transfer-Encoding: base64');
    mime.writeln();
    mime.writeln(base64Encode(utf8.encode(bodyText)));
    mime.writeln();

    mime.writeln('--$boundary');
    mime.writeln('Content-Type: application/pdf; name="$filename"');
    mime.writeln('Content-Disposition: attachment; filename="$filename"');
    mime.writeln('Content-Transfer-Encoding: base64');
    mime.writeln();

    for (int i = 0; i < pdfBase64.length; i += 76) {
      mime.writeln(
        pdfBase64.substring(
          i,
          i + 76 > pdfBase64.length ? pdfBase64.length : i + 76,
        ),
      );
    }

    mime.writeln();
    mime.writeln('--$boundary--');

    return base64UrlEncode(utf8.encode(mime.toString()));
  }
}
