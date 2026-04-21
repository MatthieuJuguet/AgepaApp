import os
import pandas as pd
import subprocess
import time

# --- CONFIGURATION ---
HTML_DIR = r"d:\Persos\AGEPA\Attestations_2026_HTML" # Dossier temporaire pour les HTML
PDF_DIR = r"d:\Persos\AGEPA\Attestations_2026_PDF"   # Dossier final pour les PDF
TEMPLATE_FILE = r"d:\Persos\AGEPA\trame_a4_moderne.html"
EXCEL_FILE = r"d:\Persos\AGEPA\contacts.xls"

# Chemin vers l'exécutable Edge pour la conversion
EDGE_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

def clean_name(val):
    if pd.isna(val) or str(val).strip() == "":
        return None
    return str(val).strip()

def convert_html_to_pdf(html_path, pdf_path):
    """Utilise Microsoft Edge en mode sans tête pour imprimer en PDF."""
    try:
        # Commande Chrome/Edge pour convertir HTML en PDF
        cmd = [
            EDGE_PATH,
            "--headless",
            "--disable-gpu",
            f"--print-to-pdf={pdf_path}",
            "--no-margins", # Crucial pour respecter le design CSS
            html_path
        ]
        subprocess.run(cmd, check=True, capture_output=True)
        return True
    except Exception as e:
        print(f"Erreur lors de la conversion PDF : {e}")
        return False

def generate_attestations():
    # Création des dossiers
    for d in [HTML_DIR, PDF_DIR]:
        if not os.path.exists(d):
            os.makedirs(d)

    # Lecture de la trame
    with open(TEMPLATE_FILE, 'r', encoding='utf-8') as f:
        template_content = f.read()

    # Lecture du fichier Excel
    df = pd.read_excel(EXCEL_FILE)
    df.columns = ['nom', 'prenom', 'mail']
    df = df.dropna(subset=['nom', 'prenom'], how='all')

    count = 0
    print("Début de la génération (HTML + PDF)...\n")
    
    for _, row in df.iterrows():
        nom_brut = clean_name(row['nom'])
        prenom_brut = clean_name(row['prenom'])

        if not nom_brut or not prenom_brut:
            continue

        # Mise en forme
        nom = nom_brut.upper()
        prenom = prenom_brut.capitalize()
        nom_complet = f"{prenom} {nom}"
        
        # Injection
        new_content = template_content.replace("[[NOM_DESTINATAIRE]]", nom_complet)

        # Naming
        safe_nom = nom.replace(" ", "_").replace("'", "_")
        safe_prenom = prenom.replace(" ", "_")
        base_filename = f"AGEPA_2026_Cotisation_{safe_nom}_{safe_prenom}"
        
        html_path = os.path.join(HTML_DIR, base_filename + ".html")
        pdf_path = os.path.join(PDF_DIR, base_filename + ".pdf")

        # 1. Sauvegarde du HTML temporaire
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        # 2. Conversion en PDF
        success = convert_html_to_pdf(html_path, pdf_path)
        
        if success:
            count += 1
            print(f"[{count}] PDF Généré : {base_filename}.pdf")
        else:
            print(f"[!] Échec pour {base_filename}")

    print(f"\nTerminé ! {count} PDF créés dans {PDF_DIR}")
    print(f"Note : Les versions HTML sont conservées dans {HTML_DIR}")

if __name__ == "__main__":
    generate_attestations()
