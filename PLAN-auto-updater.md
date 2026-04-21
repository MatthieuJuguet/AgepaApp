# PLAN: Auto-Updater via Git Releases

## 🎯 Overview
Création d'un système de mise à jour automatique pour l'application Flutter Windows. L'application sera capable de consulter les dernières versions (Releases) publiées sur votre dépôt Git, de comparer avec sa version locale, et de proposer/d'installer les mises à jour sans intervention manuelle de votre part pour la distribution.

**Project Type:** MOBILE (Flutter Desktop)
**Agents:** `mobile-developer`

---

## 🛑 User Review Required (Socratic Gate)

> [!IMPORTANT]
> Avant de générer le code de cette fonctionnalité, répondez aux questions suivantes pour m'assurer que le système sera parfaitement adapté à votre environnement et à vos utilisateurs.

### [P0] **Plateforme d'Hébergement & Accès**
**Question:** Sur quelle plateforme (GitHub, GitLab, Gitea) hébergez-vous le code ? Les Releases qui contiendront l'exécutable seront-elles publiques ou le dépôt est-il privé ?
**Why This Matters:**
- L'API pour récupérer les infos de la dernière release change selon la plateforme.
- Si le dépôt est privé, l'application aura besoin d'un Token d'accès sécurisé pour pouvoir télécharger le setup.
**Options:**
| Option | Pros | Cons |
|--------|------|------|
| GitHub (Public) | API très facile à appeler, aucun jeton nécessaire. | Les exécutables sont accessibles publiquement sur internet. |
| GitLab (Privé) | Code et binaires sécurisés. | Risque de fuite si le "Personal Access Token" est codé en dur dans l'app, il faut utiliser un Deploy Token limité. |
**If Not Specified:** Implémentation basée sur l'API publique de GitHub Releases sans authentification.

### [P0] **Mécanisme d'Installation (Windows)**
**Question:** Puisque vous avez un fichier `installer_config.iss` (Inno Setup), souhaitez-vous que l'application télécharge directement ce Setup (`.exe`) et le lance automatiquement (ce qui remplacera l'ancienne version de l'app) ?
**Why This Matters:**
- Sur Windows, un programme ne peut pas écraser son propre binaire (`.exe`) pendant qu'il l'exécute.
- Lancer un Setup Inno généré résout ce problème car Inno Setup a des directives (`CloseApplications`) pour couper l'app, l'écraser, et la relancer.
**Options:**
| Option | Pros | Cons |
|--------|------|------|
| Setup InnoSetup (`.exe`) | Exploite l'outil existant. Gère les raccourcis, icônes, clean-up. | L'utilisateur risque de voir brièvement la barre de progression/fenêtre d'installation de Windows. |
| Librarie tierce (`auto_updater`) | Totalement transparent via WinSparkle. | Très technique à packager et configurer sur Flutter Desktop. |
**If Not Specified:** Téléchargement en arrière plan de l'installateur Inno Setup et appel du processus avec le flag silencieux (`/verysilent`).

### [P1] **Expérience Utilisateur (UX)**
**Question:** Quand une mise à jour est trouvée, voulez-vous l'imposer (mise à jour obligatoire empêchant d'utiliser l'ancienne version) ou la suggérer simplement via une popup "Notes de mise à jour" au lancement de l'application ?
**Why This Matters:**
- L'approche définit si on bloque la navigation tant que ce n'est pas fait.
**If Not Specified:** Affichage d'une boîte de dialogue modale non-bloquante au lancement, résumant les notes de version (Release notes du push Git) avec un bouton "Télécharger et installer".

---

## 🛠️ Proposed Changes (Draft)

*Ce plan sera affiné une fois la Gate Socratique validée.*

### 1. Composant de Téléchargement & Service
#### [NEW] `lib/services/updater_service.dart`
- Appel API HTTP pour lister la dernière release et identifier l'asset `AgepaAppSetup.exe`.
- Utilisation de `package:path_provider` pour sauvegarder l'exécutable dans le dossier temporaire du système (`%TEMP%`).

### 2. Interface UI
#### [NEW] `lib/ui/widgets/update_dialog.dart`
- Boîte de dialogue affichant une barre de progression de téléchargement.
- Affiche le message de release ("What's new : ...").

### 3. Exécution Système
#### [MODIFY] `lib/main.dart`
- Initialisation du check de version. Comparaison avec la propriété `version` du `pubspec.yaml` que l'on lit via le package `package_info_plus`.

#### [MODIFY] `installer_config.iss`
- Ajout des instructions de terminaison (fermeture de l'app si elle est ouverte au moment où le `.exe` se lance).

---

## ✅ Phase X : Verification Plan

### Manual Verification
1. Modifier virtuellement la version de l'app pour "0.0.1".
2. Fausser l'API pour qu'elle renvoie une "Release 1.0.0".
3. Confirmer l'affichage modal.
4. Simuler le téléchargement du binaire.
5. Vérifier que la commande `Process.run()` pour lancer le `Setup.exe` s'effectue avec succès.
