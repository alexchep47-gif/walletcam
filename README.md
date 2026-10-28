# Walletcam

**Walletcam** est une application de trésorerie et de gestion de caisse conçue pour les commerçants et petites entreprises au Cameroun.

## 🌐 Version Web (GitHub Pages)

**Accès direct :** [https://alexchep47-gif.github.io/walletcam/](https://alexchep47-gif.github.io/walletcam/)

> Après le premier push, activez GitHub Pages dans **Settings → Pages → Source : GitHub Actions** si ce n’est pas déjà fait.

## Fonctionnalités

- **Tableau de bord** : solde de caisse, montant à recouvrer, ardoises actives
- **Module Trésorerie** : gestion complète des ardoises (crédits clients)
  - Création (client + téléphone + montant + échéance)
  - Suivi des dettes restantes et retards
  - Marquage comme payé
  - Relances locales (notifications Android) à la date d’échéance
- **Encaissements / Décaissements** avec historique
- **Design Glassmorphism** : interface sombre moderne avec effet de verre dépoli
- **100 % Offline-First** : fonctionne sans internet (données stockées localement)
- **Version Web** déployée automatiquement sur GitHub Pages

## Lancer en local

```bash
flutter pub get
flutter run                 # Android / iOS / Desktop
flutter run -d chrome      # Version web locale
```

## Build

```bash
# APK Android
flutter build apk --release

# Web (pour GitHub Pages)
flutter build web --release --base-href /walletcam/
```

## Architecture technique

| Couche | Technologie |
|--------|-------------|
| UI | Flutter + Glassmorphism (BackdropFilter) |
| Stockage | SharedPreferences (prêt pour Isar) |
| Notifications | flutter_local_notifications (Android uniquement) |
| Fuseau | Africa/Douala (WAT) |
| CI/CD | GitHub Actions (APK + Pages) |

## Licence

Propriétaire — Walletcam © 2026
