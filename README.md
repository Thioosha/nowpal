# NowPal : Battre la procrastination, une session à la fois

NowPal est une application mobile Android développée avec Flutter, pensée pour les étudiants qui procrastinent les sessions d'étude et ont du mal à rester concentrés. Elle s'attaque à un problème concret : **la facilité avec laquelle on repousse une session de travail** pour aller sur les réseaux sociaux ou dans n'importe quelle autre distraction.

Son principe central est le **mode strict** — une fois une session lancée, un overlay système bloque toute navigation hors de l'application, et un service d'accessibilité empêche même l'accès aux Paramètres Android pour désactiver les permissions. Pas de négociation, pas de raccourci.

Le reste (minuteur Pomodoro, planification de sessions, liste de tâches, suivi de l'humeur, statistiques) vient en support de cette idée centrale : créer un environnement où la seule option viable, c'est de respecter ses engagements et travailler.

---

## Comment fonctionne le mode strict ?

Quand une session stricte est active :
- Un **overlay système** bloque l'accès à toute autre application
- L'**Accessibility Service** détecte si tu tentes d'ouvrir les Paramètres Android (pour désactiver les permissions) et t'en expulse automatiquement
- Le bouton retour est désactivé
- Pour les sessions planifiées, une **alarme système** réveille l'appareil et ouvre directement l'écran de focus verrouillé — même si l'app est fermée

Le mode strict ne peut être quitté qu'en allant jusqu'au bout de la session de focus, ou pendant la pause.

---

## Fonctionnalités

### 🏠 Tableau de bord (Accueil)
- Accueil personnalisé selon l'heure de la journée
- Suivi de l'humeur quotidienne avec historique et streak
- Aperçu des tâches en cours (top 3 tâches en attente)
- Aperçu de la prochaine session planifiée
- Statistiques du jour : minutes de focus et sessions complétées

### 🎯 Focus
- Minuteur Pomodoro configurable (durée de focus et de pause personnalisables)
- **Mode strict** : overlay système bloquant toute navigation hors de l'application pendant une session de focus — inclut la détection via Accessibility Service pour empêcher l'accès aux Paramètres Android
- Animation Lottie interactive (ours qui étudie pendant le focus, ours au repos pendant la pause)
- Sons d'ambiance en boucle : pluie, feu de cheminée, océan, piano
- Décompte sonore (3 dernières secondes) à la fin de chaque phase
- Mini liste de tâches accessible pendant une session (bottom sheet, glisser-déposer, ajout rapide)
- Enregistrement du temps réel de focus (temps effectif, pas le temps planifié)

### 📅 Sessions planifiées
- Planification de sessions avec date, heure, durée et mode strict
- Notification de rappel 5 minutes avant le début
- Notification de démarrage à l'heure exacte (avec navigation directe vers la session)
- **Lancement automatique en mode strict** : l'alarme réveille l'appareil et ouvre directement l'écran de focus verrouillé, même si l'application est fermée
- Modification et suppression de sessions (avec annulation des notifications associées)
- Sections "À venir" et "Manquées" avec fenêtre de grâce de 2 minutes
- Nettoyage automatique des sessions manquées après 48 heures

### ✅ Liste de tâches
- Ajout, complétion et suppression de tâches
- Réorganisation par glisser-déposer (long press)
- Marquage d'une tâche comme "tâche en cours" (affichée pendant les sessions de focus)
- Sections séparées : En attente / Terminées

### 📊 Statistiques
- Nombre total de sessions complétées
- Total des minutes de focus
- Graphique en barres des 7 derniers jours (fl_chart)
- Calendrier d'humeur mensuel avec navigation

---

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Gestion d'état | Provider (`ChangeNotifier`) |
| Persistance | SharedPreferences (JSON) |
| Notifications | flutter_local_notifications + timezone |
| Alarmes système | android_alarm_manager_plus |
| Overlay système | flutter_overlay_window |
| Intents Android | android_intent_plus |
| Animations | Lottie (lottie package) |
| Audio | audioplayers |
| Graphiques | fl_chart |
| Bridge natif | MethodChannel (Kotlin ↔ Dart) |

---

## Architecture

L'application suit une architecture **Provider + écrans indexés** :

- `MultiProvider` expose `TodoProvider` et `PlannedSessionProvider` à l'ensemble de l'arbre de widgets
- `IndexedStack` dans `MainShell` maintient l'état de chaque onglet en mémoire
- Un `GlobalKey<NavigatorState>` permet la navigation depuis des contextes hors widget tree (callbacks de notifications, alarmes)
- Le bridge natif Kotlin (`MainActivity.kt` + `AppBlockerAccessibilityService.kt`) communique avec Flutter via `MethodChannel` pour : la lecture des extras d'intent au démarrage, la vérification du statut de l'Accessibility Service, et la détection de navigation vers les Paramètres Android

### Mode strict — fonctionnement détaillé
1. Au démarrage d'une session stricte, un flag `strict_session_active` est écrit dans `SharedPreferences`
2. `flutter_overlay_window` affiche un overlay bloquant si l'utilisateur quitte l'application
3. `AppBlockerAccessibilityService` lit ce flag en temps réel et redirige l'utilisateur vers l'écran d'accueil si une navigation vers `com.android.settings` est détectée
4. Pour les sessions planifiées en mode strict, `android_alarm_manager_plus` déclenche un callback qui lance un `AndroidIntent` pour rouvrir l'application, même depuis un état froid

---

## Installation

### Prérequis
- Flutter SDK 3.x
- Android SDK (minSdk 21, targetSdk 34)
- Appareil ou émulateur Android

### Étapes

```bash
git clone <url-du-repo>
cd nowpal
flutter pub get
flutter run
```

### Assets requis
Placer les fichiers suivants dans les dossiers correspondants :

```
assets/
  lottie/
    bear_studying.json
    bear_resting.json
  audio/
    rain.mp3
    fireplace.mp3
    ocean.mp3
    piano.mp3
    countdown.mp3
fonts/
  Nunito-Regular.ttf
  Nunito-SemiBold.ttf
  Nunito-Bold.ttf
```

### Permissions Android requises
L'application demande les permissions suivantes au runtime ou via le manifeste :
- `SYSTEM_ALERT_WINDOW` — overlay système (mode strict)
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` — alarmes précises pour les sessions planifiées
- `POST_NOTIFICATIONS` — notifications de rappel et de démarrage
- `BIND_ACCESSIBILITY_SERVICE` — détection de navigation vers les Paramètres (mode strict)
- `FOREGROUND_SERVICE` — service overlay en arrière-plan
- `RECEIVE_BOOT_COMPLETED` — rescheduling des alarmes après redémarrage

---

## Structure du projet

```
lib/
├── main.dart                          # Point d'entrée, init alarmes/notifications, navigation clé globale
├── screens/
│   ├── main_shell.dart                # Shell principal avec IndexedStack et navbar
│   ├── home_screen.dart               # Tableau de bord
│   ├── focus_screen.dart              # Hub Focus + planification
│   ├── active_session_screen.dart     # Écran de session active (minuteur, Lottie, audio)
│   ├── todo_screen.dart               # Liste de tâches
│   └── stats_screen.dart              # Statistiques
├── providers/
│   ├── todo_provider.dart             # Gestion des tâches (CRUD + réordonnancement)
│   └── planned_session_provider.dart  # Gestion des sessions planifiées
├── models/
│   ├── todo.dart
│   └── planned_session.dart
├── services/
│   ├── notification_service.dart      # Scheduling des notifications locales
│   ├── alarm_service.dart             # Scheduling des alarmes système (mode strict)
│   └── launch_service.dart            # Bridge MethodChannel (Kotlin ↔ Dart)
└── widgets/
    ├── overlay_widget.dart            # UI de l'overlay mode strict
    └── navbar_clipper.dart            # Clipper custom pour la navbar

android/app/src/main/kotlin/com/example/nowpal/
├── MainActivity.kt                    # MethodChannel + gestion des intents
└── AppBlockerAccessibilityService.kt  # Détection navigation Settings en mode strict
```

---

*Développé dans le cadre du cours Flutter — Département GIT, École Polytechnique de Thiès (EPT)*
