# Orientia mobile

Application Flutter connectée au backend Orientia : profil académique, OCR, catalogues sourcés, recommandations, simulations, comparaisons, bourses, assistant et exports.

## Production Render

Backend public : **https://orientation-backend-d0ys.onrender.com**, sans `/api/v1`.

```powershell
flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

`APP_ENV=production` choisit aussi cette URL par defaut. Une valeur compilee `API_BASE_URL` explicite reste prioritaire. Aucun secret serveur n'est embarque. L'APK debug sert a la recette ; la configuration release actuelle utilise encore la signature debug et ne constitue pas une signature de distribution.

## Developpement local

```powershell
flutter pub get
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Le lancement sans parametre conserve cet environnement local. `10.0.2.2` designe l'hote depuis l'emulateur Android ; sur telephone local, utiliser l'adresse privee du serveur. HTTPS est impose pour la production et les builds release. Aucun prefixe API n'est ajoute automatiquement.

## Vérification

```powershell
flutter analyze
flutter test --reporter expanded
flutter build apk --debug
```

`test/` utilise des transports simulés et des fixtures synthétiques. `test_live/backend_journey_test.dart` est lancé explicitement par le harnais backend `MobileFlutterJourneyIT`, qui prépare PostgreSQL privé et Spring. Il exige `F33_LIVE_FIXTURE`, ne doit jamais viser la base principale et ne remplace pas une recette sur appareil.

Sur l'environnement local F1/F2 déjà préparé, démarrer exclusivement PostgreSQL privé (`127.0.0.1:59745`, base `orientia_f1`), puis :

```powershell
python tool/run_backend_journey.py
python tool/run_backend_journey.py --full
```

Le lanceur exige les fichiers temporaires de connexion F1 et OCR F2 existants, conserve le mot de passe dans l'environnement du processus et utilise des schémas F3.3 distincts. Il ne démarre ni n'arrête PostgreSQL et n'efface aucun schéma.

Résultats, contrats et limites : [rapport F3.3](SPRINT_F3_3_FLUTTER_INTEGRATION.md).

## Telephone Android

Connecter le telephone, activer le debogage USB et accepter la cle RSA :

```powershell
dart run tool/android_phone_command.dart
```

L'aide utilise le backend Render public ci-dessus et affiche la commande exacte pour l'appareil physique detecte ; elle n'installe rien. Une variable PowerShell `ORIENTIA_API_URL` peut remplacer cette URL ; `--api-url` est prioritaire. Cette variable de terminal n'est pas lue directement par Flutter : l'aide la transmet via `--dart-define=API_BASE_URL=...`.

Le package reste `com.orientia.orientia`. Ne pas modifier la signature ni desinstaller automatiquement une version existante pour forcer une installation.

Rapport courant : [connexion et validation mobile production](ORIENTIA_MOBILE_PRODUCTION_RENDER.md). Les rapports des anciens sprints et du redeploiement restent des documents historiques.
