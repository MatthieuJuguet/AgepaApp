import os
import sys
import subprocess
import time
import threading
import shutil
import datetime
import pathlib
import uuid
import pandas as pd
import win32com.client
import customtkinter as ctk
from tkinter import filedialog, messagebox

# Configuration globale UI
ctk.set_appearance_mode("light")
ctk.set_default_color_theme("blue")

MONTHS = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]

def get_base_dir():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    else:
        return os.path.dirname(os.path.abspath(__file__))

BASE_DIR = get_base_dir()
TEMPLATE_FILE = os.path.join(BASE_DIR, "trame_a4_moderne.html")
EDGE_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

def clean_name(val):
    if pd.isna(val) or str(val).strip() == "":
        return None
    return str(val).strip()

class AGEPA_App(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("AGEPA App - Attestations")
        self.geometry("600x700")
        self.resizable(False, False)
        
        self.file_path = None
        self.df = None

        # --- Section : Titre ---
        self.title_label = ctk.CTkLabel(self, text="AGEPA - Outil d'Automatisation", font=ctk.CTkFont(family="Inter", size=26, weight="bold"), text_color="#111827")
        self.title_label.pack(pady=(25, 0))
        self.subtitle_label = ctk.CTkLabel(self, text="Génération et envois officiels des attestations", font=ctk.CTkFont(family="Inter", size=14), text_color="#6B7280")
        self.subtitle_label.pack(pady=(0, 25))

        # --- ÉTAPE 1 : Paramètres (Année & Montant) ---
        self.frame_params = ctk.CTkFrame(self, fg_color="#F3F4F6", corner_radius=10)
        self.frame_params.pack(padx=30, pady=10, fill="x")

        lbl_params = ctk.CTkLabel(self.frame_params, text="1. Paramètres de l'attestation", font=ctk.CTkFont(weight="bold", size=14), text_color="#374151")
        lbl_params.pack(anchor="w", padx=20, pady=(15, 5))

        # Conteneur horizontal pour année et montant
        self.params_inner = ctk.CTkFrame(self.frame_params, fg_color="transparent")
        self.params_inner.pack(padx=20, pady=(0, 15), fill="x")

        # Année
        ctk.CTkLabel(self.params_inner, text="Année :", text_color="#4B5563").pack(side="left", padx=(0, 5))
        current_year = datetime.datetime.now().year
        years = [str(y) for y in range(current_year - 2, current_year + 10)]
        self.year_var = ctk.StringVar(value=str(current_year))
        self.combo_year = ctk.CTkComboBox(self.params_inner, values=years, variable=self.year_var, width=80)
        self.combo_year.pack(side="left", padx=(0, 20))

        # Montant
        ctk.CTkLabel(self.params_inner, text="Montant (en €) :", text_color="#4B5563").pack(side="left", padx=(0, 5))
        self.amount_var = ctk.StringVar(value="30")
        self.entry_amount = ctk.CTkEntry(self.params_inner, textvariable=self.amount_var, width=60)
        self.entry_amount.pack(side="left")

        # --- ÉTAPE 2 : Fichier ---
        self.frame_file = ctk.CTkFrame(self, fg_color="#F3F4F6", corner_radius=10)
        self.frame_file.pack(padx=30, pady=10, fill="x")

        self.file_label = ctk.CTkLabel(self.frame_file, text="2. Charger la liste des médecins (Excel ou CSV)", font=ctk.CTkFont(weight="bold", size=14), text_color="#374151")
        self.file_label.pack(anchor="w", padx=20, pady=(15, 5))

        self.file_status = ctk.CTkLabel(self.frame_file, text="Aucun fichier sélectionné", font=ctk.CTkFont(slant="italic"), text_color="#9CA3AF")
        self.file_status.pack(side="left", padx=20, pady=(0, 15))

        self.btn_browse = ctk.CTkButton(self.frame_file, text="Parcourir...", command=self.browse_file, width=100, fg_color="#4B5563", hover_color="#374151")
        self.btn_browse.pack(side="right", padx=20, pady=(0, 15))

        # --- ÉTAPE 3 : Paramètres Outlook ---
        self.frame_options = ctk.CTkFrame(self, fg_color="#F3F4F6", corner_radius=10)
        self.frame_options.pack(padx=30, pady=10, fill="x")
        
        lbl_opt = ctk.CTkLabel(self.frame_options, text="3. Distribution Outlook", font=ctk.CTkFont(weight="bold", size=14), text_color="#374151")
        lbl_opt.pack(anchor="w", padx=20, pady=(15, 5))

        self.radio_var = ctk.IntVar(value=0) # 0 = Brouillons, 1 = Direct
        self.radio_draft = ctk.CTkRadioButton(self.frame_options, text="Brouillons : Crée les mails dans Outlook (Recommandé, sécurisé)", variable=self.radio_var, value=0, text_color="#4B5563")
        self.radio_draft.pack(anchor="w", padx=20, pady=5)
        
        self.radio_direct = ctk.CTkRadioButton(self.frame_options, text="Envoi immédiat : Expédie directement les emails personnalisés", variable=self.radio_var, value=1, text_color="#4B5563")
        self.radio_direct.pack(anchor="w", padx=20, pady=(5, 15))

        # --- ÉTAPE 3 : Action ---
        self.btn_main = ctk.CTkButton(self, text="🚀 Lancer l'Automatisation Globale", command=lambda: self.start_thread(self.process_all), font=ctk.CTkFont(size=16, weight="bold"), height=50, fg_color="#2563EB", hover_color="#1D4ED8", state="disabled")
        self.btn_main.pack(padx=30, pady=(20, 10), fill="x")

        # --- Progression Dynamique ---
        self.progress = ctk.CTkProgressBar(self, progress_color="#10B981")
        self.progress.pack(padx=30, pady=(10, 5), fill="x")
        self.progress.set(0)

        self.status_label = ctk.CTkLabel(self, text="En attente de fichier...", font=ctk.CTkFont(), text_color="#6B7280")
        self.status_label.pack(pady=0)

        # --- Bouton Ouvrir Dossier (Caché au début ou discret) ---
        self.btn_open_pdf = ctk.CTkButton(self, text="📂 Accéder aux PDF générés", command=self.open_pdf_folder, fg_color="transparent", text_color="#2563EB", hover_color="#DBEAFE", font=ctk.CTkFont(size=12, weight="bold"))
        self.btn_open_pdf.pack(pady=5)

        # --- Options Avancées ---
        self.adv_btn = ctk.CTkButton(self, text="Opération isolée : Générer PDF uniquement", font=ctk.CTkFont(size=11, underline=True), fg_color="transparent", text_color="#9CA3AF", hover_color="#E5E7EB", command=lambda: self.start_thread(self.process_generation))
        self.adv_btn.pack(side="bottom", pady=10)

    def get_output_dirs(self):
        annee = self.year_var.get()
        return (
            os.path.join(BASE_DIR, f"Attestations_{annee}_HTML"),
            os.path.join(BASE_DIR, f"Attestations_{annee}_PDF")
        )

    def update_status(self, text, color="#374151", bold=False):
        self.status_label.configure(text=text, text_color=color, font=ctk.CTkFont(weight="bold" if bold else "normal"))

    def toggle_buttons(self, state):
        status = "normal" if state else "disabled"
        self.btn_main.configure(state=status)
        self.btn_browse.configure(state="normal" if state else "disabled") # correction typo config
        self.adv_btn.configure(state=status)
        self.combo_year.configure(state=status)
        self.entry_amount.configure(state=status)

    def browse_file(self):
        file_path = filedialog.askopenfilename(
            title="Sélectionner le fichier Contacts",
            filetypes=[("Fichiers Excel/CSV", "*.xls *.xlsx *.csv"), ("Tous les fichiers", "*.*")]
        )
        if file_path:
            self.file_path = file_path
            self.load_data(file_path)

    def load_data(self, file_path):
        try:
            if file_path.lower().endswith('.csv'):
                df = pd.read_csv(file_path, sep=None, engine='python')
            elif file_path.lower().endswith(('.xls', '.xlsx')):
                df = pd.read_excel(file_path)
            else:
                self.file_status.configure(text="❌ Format incorrect.", text_color="#EF4444")
                return

            if len(df.columns) < 3:
                self.file_status.configure(text="❌ Il manque des colonnes (Nom, Prénom, Mail).", text_color="#EF4444")
                return
            
            df = df.iloc[:, :3]
            df.columns = ['nom', 'prenom', 'mail']
            self.df = df.dropna(subset=['nom', 'prenom'], how='all')
            
            nb = len(self.df)
            self.file_status.configure(text=f"✅ {nb} médecins identifiés avec succès.", text_color="#10B981", font=ctk.CTkFont(weight="bold"))
            self.btn_main.configure(state="normal")
            self.update_status("Prêt à démarrer.", color="#10B981")
        except Exception as e:
            self.file_status.configure(text="❌ Erreur de lecture du fichier.", text_color="#EF4444")
            self.df = None

    def convert_html_to_pdf(self, html_path, pdf_path):
        html_uri = pathlib.Path(os.path.abspath(html_path)).as_uri()
        
        # Identifiant unique garanti pour éviter toute collision de profil
        unique_id = str(uuid.uuid4())[:8]
        temp_user_data = os.path.join(os.environ.get("TEMP", BASE_DIR), f"AGEPA_Edge_{unique_id}")
        
        cmd = [
            EDGE_PATH, 
            "--headless", 
            "--disable-gpu", 
            f"--print-to-pdf={pdf_path}", 
            "--no-margins", 
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-extensions",
            "--disable-background-networking",
            "--disable-background-timer-throttling",
            "--disable-sync",
            "--disable-translate",
            f"--user-data-dir={temp_user_data}",
            html_uri
        ]
        
        if os.path.exists(pdf_path):
            try: os.remove(pdf_path)
            except: pass

        for attempt in range(3):
            try:
                subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=25, creationflags=subprocess.CREATE_NO_WINDOW)
                
                # Attente progressive pour laisser l'OS indexer le fichier
                for _ in range(6): 
                    time.sleep(0.5)
                    if os.path.exists(pdf_path):
                        size = os.path.getsize(pdf_path)
                        # Vos PDF font environ 65 ko. L'erreur Edge fait environ 20-30 ko.
                        if size > 40000:
                            try: shutil.rmtree(temp_user_data)
                            except: pass
                            return True
                
                # Si on est ici, le fichier existe peut-être mais est trop petit
                if os.path.exists(pdf_path) and os.path.getsize(pdf_path) > 5000:
                    try: shutil.rmtree(temp_user_data)
                    except: pass
                    return True
            except Exception:
                pass
            time.sleep(1)
        
        try: shutil.rmtree(temp_user_data)
        except: pass
        return False

    def open_pdf_folder(self):
        _, pdf_dir = self.get_output_dirs()
        if not os.path.exists(pdf_dir):
            os.makedirs(pdf_dir)
        os.startfile(pdf_dir)

    def start_thread(self, target_function):
        if self.df is None:
            return
        self.toggle_buttons(False)
        self.progress.set(0)
        threading.Thread(target=target_function, daemon=True).start()

    def process_generation(self, multiplier=1.0, offset=0.0):
        html_dir, pdf_dir = self.get_output_dirs()
        try:
            if not os.path.exists(TEMPLATE_FILE):
                self.update_status("Erreur : Gabarit HTML introuvable.", color="#EF4444", bold=True)
                return False

            for d in [html_dir, pdf_dir]:
                if not os.path.exists(d): os.makedirs(d)

            with open(TEMPLATE_FILE, 'r', encoding='utf-8') as f:
                template_content = f.read()

            annee = self.year_var.get()
            montant = self.amount_var.get()
            now = datetime.datetime.now()
            date_jour = f"{now.day} {MONTHS[now.month-1]} {now.year}"

            total = len(self.df)
            count = 0
            
            for idx, row in self.df.iterrows():
                nom_brut = clean_name(row['nom'])
                prenom_brut = clean_name(row['prenom'])

                if not nom_brut or not prenom_brut:
                    continue

                nom = nom_brut.upper()
                prenom = prenom_brut.capitalize()
                
                step_prefix = "[Génération]" if multiplier == 1.0 else "[Génération 1/2]"
                self.update_status(f"🛠️ {step_prefix} Dessin du PDF pour Dr. {nom}...")
                
                new_content = template_content.replace("[[NOM_DESTINATAIRE]]", f"{prenom} {nom}")
                new_content = new_content.replace("[[ANNEE]]", annee)
                new_content = new_content.replace("[[MONTANT]]", montant)
                new_content = new_content.replace("[[DATE_GENERATION]]", date_jour)

                safe_nom = nom.replace(" ", "_").replace("'", "_")
                safe_prenom = prenom.replace(" ", "_")
                base_filename = f"AGEPA_{annee}_Cotisation_{safe_nom}_{safe_prenom}"
                
                html_path = os.path.join(html_dir, base_filename + ".html")
                pdf_path = os.path.join(pdf_dir, base_filename + ".pdf")

                with open(html_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                
                # Petite pause pour laisser le temps au système de fichiers de se stabiliser
                time.sleep(0.3)
                
                if self.convert_html_to_pdf(html_path, pdf_path):
                    count += 1
                else:
                    self.update_status(f"⚠️ Échec conversion pour Dr. {nom}...", color="#D97706")
                    time.sleep(1)

                self.progress.set(offset + (count / total) * multiplier)
                
            if multiplier == 1.0:
                self.update_status(f"✅ Terminé : {count} PDF générés.", color="#10B981", bold=True)
                self.toggle_buttons(True)
            return True
        except Exception as e:
            self.update_status("❌ Erreur pendant la génération.", color="#EF4444", bold=True)
            self.toggle_buttons(True)
            return False
        finally:
            if os.path.exists(html_dir):
                try:
                    shutil.rmtree(html_dir)
                except:
                    pass

    def process_emails(self, multiplier=1.0, offset=0.0):
        _, pdf_dir = self.get_output_dirs()
        annee = self.year_var.get()

        direct_send = self.radio_var.get() == 1
        total = len(self.df)
        count = 0
        abs_pdf_dir = os.path.abspath(pdf_dir)

        try:
            conn_text = "[Envoi]" if multiplier == 1.0 else "[Envoi 2/2]"
            self.update_status(f"{conn_text} Connexion sécurisée à Outlook...")
            import pythoncom
            pythoncom.CoInitialize()
            outlook = win32com.client.Dispatch("Outlook.Application")
        except Exception as err:
            try:
                outlook = win32com.client.GetActiveObject("Outlook.Application")
            except:
                self.update_status("❌ Veuillez ouvrir Outlook Classique d'abord.", color="#EF4444", bold=True)
                self.toggle_buttons(True)
                return False

        for idx, row in self.df.iterrows():
            nom_brut = clean_name(row['nom'])
            prenom_brut = clean_name(row['prenom'])
            email = clean_name(row['mail'])

            if not nom_brut or not prenom_brut or not email:
                continue

            nom = nom_brut.upper()
            prenom = prenom_brut.capitalize()
            self.update_status(f"📨 [Envoi 2/2] Transmission Outlook pour Dr. {nom}...")
            
            safe_nom = nom.replace(" ", "_").replace("'", "_")
            safe_prenom = prenom.replace(" ", "_")
            pdf_filename = f"AGEPA_{annee}_Cotisation_{safe_nom}_{safe_prenom}.pdf"
            pdf_path = os.path.join(abs_pdf_dir, pdf_filename)

            for _ in range(3):
                if os.path.exists(pdf_path): break
                time.sleep(1)

            if not os.path.exists(pdf_path):
                continue

            try:
                mail = outlook.CreateItem(0)
                mail.To = email
                mail.Subject = f"Attestation de cotisation AGEPA {annee} - Docteur {prenom} {nom}"
                mail.Body = (f"Bonjour Docteur {nom},\n\n"
                             f"Veuillez trouver en pièce jointe votre attestation de cotisation à l'AGEPA pour l'année {annee}.\n\n"
                             "Nous vous remercions de votre confiance et restons à votre entière disposition.\n\n"
                             "Bien cordialement,\nLe Bureau de l'AGEPA")
                mail.Attachments.Add(pdf_path)
                
                if direct_send:
                    mail.Send()
                else:
                    mail.Save()
                
                count += 1
                self.progress.set(offset + (count / total) * multiplier) 
            except Exception:
                pass

        action_str = "envoyées 🎉" if direct_send else "placées en Brouillons 🎉"
        self.update_status(f"Mission accomplie : {count} attestations {action_str}", color="#10B981", bold=True)
        self.toggle_buttons(True)
        return True

    def process_all(self):
        success_gen = self.process_generation(multiplier=0.5, offset=0.0)
        if success_gen:
            self.update_status("Synchronisation Windows...", color="#6B7280")
            time.sleep(2)
            self.process_emails(multiplier=0.5, offset=0.5)
        
        self.toggle_buttons(True)

if __name__ == "__main__":
    app = AGEPA_App()
    app.mainloop()
