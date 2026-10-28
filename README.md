# Walletcam

**Walletcam** est une application de trésorerie et de gestion de caisse conçue pour les commerçants et petites entreprises au Cameroun.

## Fonctionnalités principales

- **Tableau de bord** : solde de caisse, entrées / sorties du jour
- **Module Trésorerie** : gestion des ardoises (crédits clients)
  - Création d’une ardoise (client + montant + date d’échéance)
  - Suivi des dettes restantes
  - Marquage comme payé
  - Relances locales (notifications) à la date d’échéance
- **Design Glassmorphism** : interface moderne, frosted glass, sombre et élégante
- **100 % Offline-First** : fonctionne sans internet. Les données restent sur l’appareil.
- **Notifications locales** : rappels de dettes même sans connexion

## Lancer l’application

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

L’APK est automatiquement généré par GitHub Actions à chaque push sur `main`.

## Architecture

- Stockage local via `shared_preferences` (prêt pour migration Isar)
- Notifications via `flutter_local_notifications` + timezone `Africa/Douala`
- UI Glassmorphism pure Flutter (BackdropFilter)

## Licence

Propriétaire — Walletcam © 2026
