# Walletcam

Application Flutter de portefeuille numérique multi-devises pour le projet INF151. Walletcam simule les transferts XAF, USD et EUR, avec conversion, frais de 2,5 %, taxe de 19,25 %, commission marchand de 1 %, historique, taux et rapports.

## Lancer localement

```bash
flutter pub get
flutter run
```

## Tests et build

```bash
flutter analyze
flutter test
flutter build apk --release
```

Le workflow GitHub Actions `.github/workflows/flutter.yml` installe Flutter, lance l’analyse et les tests, puis produit `app-release.apk` comme artifact à chaque push sur `main` ou pull request.

## Hypothèses pédagogiques

Les taux sont saisis manuellement et ne représentent pas le marché. Les calculs sont une simulation sans banque ni argent réel. Les frais (2,5 % + 100 XAF), la taxe (19,25 %) et la commission marchand (1 %) sont configurables dans la logique métier. Les montants sont stockés en micro-unités entières afin d’éviter les erreurs binaires de flottants pour les soldes.
