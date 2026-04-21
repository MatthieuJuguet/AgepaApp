import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  static Future<File> generateAttestation({
    required String path,
    required String nom,
    required String prenom,
    required String annee,
    required String montant,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final months = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"];
    final dateGen = "${now.day} ${months[now.month - 1]} ${now.year}";

    final primaryBlue = PdfColor.fromHex('#0284c7');
    final darkNavy = PdfColor.fromHex('#0f172a');
    final slateGray = PdfColor.fromHex('#475569');
    final lightSlate = PdfColor.fromHex('#94a3b8');
    final lightBg = PdfColor.fromHex('#f8fafc');

    const logoSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect x="25" y="15" width="45" height="60" rx="6" stroke="#0284c7" stroke-width="5" fill="none" />
  <path d="M40 35H60" stroke="#0284c7" stroke-width="5" stroke-linecap="round" />
  <path d="M40 50H50" stroke="#0284c7" stroke-width="5" stroke-linecap="round" />
  <circle cx="70" cy="70" r="18" fill="#0284c7" />
  <path d="M64 70H76M70 64V76" stroke="white" stroke-width="3" stroke-linecap="round" />
</svg>
''';

    const signatureSvg = '''
<svg viewBox="0 0 200 60" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 40C20 20 40 10 50 25C60 40 70 50 80 30C90 10 110 5 120 20C130 35 140 45 150 25C160 5 180 15 190 35" stroke="#0284c7" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" fill="none" />
  <path d="M45 25C55 10 75 15 85 30" stroke="#0284c7" stroke-width="2" stroke-linecap="round" fill="none" />
  <path d="M130 50 L160 50" stroke="#0284c7" stroke-width="2" stroke-linecap="round" />
</svg>
''';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // On gère les marges en interne pour le bandeau
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Bandeau supérieur (Double bleu)
              pw.Container(
                height: 6,
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColor.fromInt(0xff0284c7), PdfColor.fromInt(0xff38bdf8)],
                  ),
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(20 * PdfPageFormat.mm),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // EN-TÊTE
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 50,
                          height: 50,
                          child: pw.SvgImage(svg: logoSvg),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'A G E P A',
                              style: pw.TextStyle(
                                fontSize: 34,
                                fontWeight: pw.FontWeight.bold,
                                color: darkNavy,
                                letterSpacing: 8,
                              ),
                            ),
                            pw.Text(
                              "AMICALE DES GASTRO-ENTÉROLOGUES\nPROCTOLOGUES D'AQUITAINE",
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: slateGray,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10 * PdfPageFormat.mm),
                    pw.Divider(color: PdfColor.fromHex('#f1f5f9'), thickness: 1),
                    pw.SizedBox(height: 10 * PdfPageFormat.mm),

                    // CORPS PRINCIPAL
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // SIDEBAR (Réduite à 35mm)
                          pw.Container(
                            width: 35 * PdfPageFormat.mm,
                            padding: const pw.EdgeInsets.only(right: 15),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(color: PdfColor.fromInt(0xffe2e8f0), width: 1, style: pw.BorderStyle.dashed)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildSidebarSection('Président', ['Dr Ph. Hemery'], lightSlate, darkNavy),
                                pw.SizedBox(height: 12 * PdfPageFormat.mm),
                                _buildSidebarSection('Secrétaires', ['Dr M. Eleouet', 'Dr Ndobo-Epoy'], lightSlate, darkNavy),
                                pw.SizedBox(height: 12 * PdfPageFormat.mm),
                                _buildSidebarSection('Trésoriers', ['Dr J-P Vove', 'Dr F Juguet'], lightSlate, darkNavy),
                              ],
                            ),
                          ),

                          pw.SizedBox(width: 15 * PdfPageFormat.mm),

                          // CONTENU
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Attestation de Cotisation',
                                  style: pw.TextStyle(
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkNavy,
                                  ),
                                ),
                                pw.SizedBox(height: 20),

                                // Carte Destinataire (Correction: Séparation bordure et arrondi par imbrication)
                                pw.Container(
                                  decoration: pw.BoxDecoration(
                                    color: lightBg,
                                    borderRadius: const pw.BorderRadius.only(
                                      topRight: pw.Radius.circular(8),
                                      bottomRight: pw.Radius.circular(8),
                                    ),
                                  ),
                                  child: pw.Container(
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border(
                                        left: pw.BorderSide(color: primaryBlue, width: 4),
                                      ),
                                    ),
                                    padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text(
                                          'DÉLIVRÉE À',
                                          style: pw.TextStyle(fontSize: 8, color: slateGray, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                                        ),
                                        pw.SizedBox(height: 6),
                                        pw.Text(
                                          'Docteur $prenom ${nom.toUpperCase()}',
                                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkNavy),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                pw.SizedBox(height: 12 * PdfPageFormat.mm),

                                // Paragraphe texte (Montant en gras direct, sans gélule)
                                pw.RichText(
                                  text: pw.TextSpan(
                                    style: pw.TextStyle(fontSize: 11.5, color: slateGray, lineSpacing: 2),
                                    children: [
                                      const pw.TextSpan(text: "Nous accusons bonne réception de votre règlement d'un montant de "),
                                      pw.TextSpan(
                                        text: "$montant euros",
                                        style: pw.TextStyle(color: darkNavy, fontWeight: pw.FontWeight.bold, fontSize: 12),
                                      ),
                                      const pw.TextSpan(text: ", correspondant à votre cotisation annuelle à l'"),
                                      pw.TextSpan(text: "AGEPA", style: pw.TextStyle(color: darkNavy, fontWeight: pw.FontWeight.bold)),
                                      const pw.TextSpan(text: " pour l'année "),
                                      pw.TextSpan(text: annee, style: pw.TextStyle(color: slateGray)),
                                      const pw.TextSpan(text: "."),
                                    ],
                                  ),
                                ),

                                pw.SizedBox(height: 10 * PdfPageFormat.mm),
                                pw.Text("Avec nos sincères remerciements.", style: pw.TextStyle(fontSize: 11.5, color: slateGray)),

                                pw.Spacer(),

                                // Bloc Signature
                                pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text("Docteur F Juguet", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                                      pw.Text("Trésorier de l'association", style: pw.TextStyle(fontSize: 10, color: slateGray)),
                                      pw.SizedBox(height: 10),
                                      pw.SizedBox(
                                        width: 140,
                                        height: 40,
                                        child: pw.SvgImage(svg: signatureSvg),
                                      ),
                                      pw.SizedBox(height: 15),
                                      pw.Text(
                                        "Bordeaux, le $dateGen",
                                        style: pw.TextStyle(fontSize: 11, color: slateGray),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(height: 10 * PdfPageFormat.mm),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PIED DE PAGE
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 20),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Association Loi 1901 no. 2/16758", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: slateGray)),
                              pw.Text("Créée le 3 février 1988 - Non assujettie à la TVA", style: pw.TextStyle(fontSize: 8, color: slateGray)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("159 Bd Godard, 33110 Le Bouscat", style: pw.TextStyle(fontSize: 8, color: slateGray)),
                              pw.Text("proctologues.bordeaux@gmail.com", style: pw.TextStyle(fontSize: 8, color: slateGray)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSidebarSection(String title, List<String> names, PdfColor labelColor, PdfColor textColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(fontSize: 8, color: labelColor, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5),
        ),
        pw.SizedBox(height: 4),
        ...names.map((n) => pw.Text(
          n,
          style: pw.TextStyle(fontSize: 9.5, color: textColor),
        )),
      ],
    );
  }
}
