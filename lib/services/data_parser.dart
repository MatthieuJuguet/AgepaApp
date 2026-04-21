import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:excel2003/excel2003.dart';
import '../providers/app_state.dart';

class DataParser {
  static Future<List<Contact>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('Fichier introuvable');

    final ext = filePath.split('.').last.toLowerCase();
    List<Contact> contacts = [];

    if (ext == 'csv') {
      final input = await file.readAsString();
      final separator = input.contains(';') ? ';' : ',';
      final fields = Csv(fieldDelimiter: separator).decode(input);
      
      for (var row in fields.skip(1)) {
        if (row.length >= 3) {
          final nom = _normalizeNom(row[0].toString());
          final prenom = _normalizePrenom(row[1].toString());
          final email = row[2].toString().trim();
          if (nom.isNotEmpty && prenom.isNotEmpty && email.isNotEmpty) {
            contacts.add(Contact(nom: nom, prenom: prenom, email: email));
          }
        }
      }
    } else if (ext == 'xlsx') {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          if (row.length >= 3) {
            final nom = _normalizeNom(row[0]?.value?.toString() ?? '');
            final prenom = _normalizePrenom(row[1]?.value?.toString() ?? '');
            final email = row[2]?.value?.toString().trim() ?? '';
            if (nom.isNotEmpty && prenom.isNotEmpty && email.isNotEmpty) {
              contacts.add(Contact(nom: nom, prenom: prenom, email: email));
            }
          }
        }
      }
    } else if (ext == 'xls') {
      final reader = XlsReader(filePath);
      reader.open();
      
      final sheet = reader.sheet(0);
      for (int i = 1; i < sheet.lastRow; i++) {
        if (sheet.lastCol >= 3) {
          final nom = _normalizeNom(sheet.cell(i, 0)?.toString() ?? '');
          final prenom = _normalizePrenom(sheet.cell(i, 1)?.toString() ?? '');
          final email = sheet.cell(i, 2)?.toString().trim() ?? '';
          
          if (nom.isNotEmpty && prenom.isNotEmpty && email.isNotEmpty) {
            contacts.add(Contact(nom: nom, prenom: prenom, email: email));
          }
        }
      }
    } else {
      throw Exception('Format de fichier non supporté. Veuillez utiliser .csv, .xls ou .xlsx');
    }

    return contacts;
  }

  static String _normalizeNom(String text) {
    return text.trim().toUpperCase();
  }

  static String _normalizePrenom(String text) {
    String t = text.trim();
    if (t.isEmpty) return "";

    // Gérer les prénoms composés avec espaces ou tirets
    return t.split(' ').map((segment) {
      return segment.split('-').map((part) {
        if (part.isEmpty) return "";
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      }).join('-');
    }).join(' ');
  }
}
