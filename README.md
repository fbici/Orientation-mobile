# Orientia mobile

Application Flutter connectée au backend Orientia : profil académique, OCR, catalogues sourcés, recommandations, simulations, comparaisons, bourses, assistant et exports.

## Lancement

```powershell
flutter pub get
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

`10.0.2.2` désigne l'hôte depuis l'émulateur Android. Sur téléphone, utiliser l'adresse privée de la machine backend sur le même réseau. HTTPS est exigé pour les adresses distantes et les builds release. Aucun backend de production n'est configuré par défaut.

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://votre-api.example/api/v1
```

Remplacer cette adresse par votre API ; configurer la signature de distribution dans l'environnement de livraison. Le mobile n'embarque aucune clé serveur. Inscription et récupération exigent messagerie et tenant public configurés côté backend.

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

## Test Android apres le nouveau deploiement Render

L'ancien service a ete supprime. Aucune nouvelle URL de production n'est connue ni embarquee dans l'aide Android.

Une fois le nouveau service publie, copier son URL HTTPS reelle (sans `/api/v1`) dans une variable PowerShell, puis connecter le telephone et autoriser le debogage USB :

```powershell
$env:ORIENTIA_API_URL = Read-Host 'URL HTTPS reelle du nouveau backend Render'
dart run tool/android_phone_command.dart --api-url $env:ORIENTIA_API_URL
```

L'aide affiche la commande `flutter run` exacte pour le telephone physique detecte ; elle ne lance aucune installation. `API_BASE_URL` et `APP_ENV=development` sont transmis avec `--dart-define`. Le profil backend prod expose les routes a la racine `/`.

Le package courant reste `com.orientia.orientia`. Verifier la signature et le package d'une installation existante sans modifier l'identite ni desinstaller automatiquement l'application.

Rapport precedent (historique, ancienne URL retiree) : [synchronisation Android](ORIENTIA_GITHUB_SYNC_ANDROID_TEST.md). Nouveau rapport : [preparation du redeploiement](ORIENTIA_AUDIT_FINAL_REDEPLOIEMENT_RENDER.md).
