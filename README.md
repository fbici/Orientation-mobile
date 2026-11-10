# Orientia mobile

Application Flutter Android de la plateforme Orientia. Le Bénin est le premier territoire couvert ; l'architecture conserve les autres pays. Dépôt : [Orientation-mobile](https://github.com/fbici/Orientation-mobile), branche `master`. Dernière consolidation : 10 novembre 2026.

Ce README est la documentation de référence du projet. Toute modification doit actualiser ici les comportements, commandes, résultats et limites utiles. Aucun nouveau rapport de sprint, récapitulatif ou fichier de preuves n'est à créer. Les anciens documents ont été consolidés puis supprimés ; leur historique reste consultable dans Git.

## Démarrage et Android

Flutter/Dart selon `pubspec.yaml` et `pubspec.lock`, Android SDK, JDK fourni par Android Studio. Version de cette interface : **1.2.0+3**. Package : **`com.orientia.orientia`**.

```powershell
flutter pub get
flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

APK de recette : `build/app/outputs/flutter-apk/app-debug.apk`. Sur un téléphone connecté :

```powershell
adb devices -l
dart run tool/android_phone_command.dart
flutter run -d RFCT30G1ABE --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

L'identifiant d'appareil est à adapter si un autre téléphone est utilisé. L'aide détecte un Android physique et affiche la commande ; elle n'installe rien. Priorité : `--api-url` > variable de terminal `ORIENTIA_API_URL` > URL Render ci-dessus. Flutter lit `API_BASE_URL` par `--dart-define`, pas directement cette variable de terminal. Une mise à jour via `adb install -r` conserve les données si la signature est compatible. Ne jamais désinstaller automatiquement pour contourner une erreur de signature. L'utilisateur a lui-même désinstallé l'ancienne application avant la version 1.2.0.

Le build release utilise encore la signature debug existante : il n'est pas prêt pour une distribution Play Store. Configurer une signature privée hors Git avant publication commerciale. SHA-1 de la clé **debug locale** précédemment relevée : `0A:DB:07:6A:F5:CE:ED:C7:37:77:AC:77:66:61:4C:2A:EC:86:D5:69`. Ce certificat ne représente pas une future clé release ou Google Play App Signing.

## Environnements et réseau

| Environnement | Configuration |
|---|---|
| Production | `https://orientation-backend-d0ys.onrender.com`, contexte racine, **sans `/api/v1`** |
| Développement émulateur | `http://10.0.2.2:8080/api/v1` par défaut |
| Téléphone en local | Adresse privée réelle du serveur, fournie explicitement |

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Une URL explicite est prioritaire. Aucun préfixe n'est ajouté automatiquement. Le hostname Render connu refuse un chemin `/api/v1`, un endpoint, des identifiants, paramètres ou fragments. HTTPS est obligatoire en production/release, sans contournement de certificat. Connexion : 15 s ; réception/envoi : 90 s. Une instance Render en veille peut ralentir le premier appel. Les erreurs sont affichées avec reprise manuelle selon l'écran ; les POST métier ne sont pas rejoués arbitrairement.

## Interface et animations

La référence retenue le 10 novembre est la maquette utilisateur « Interface mobile Orientia en trois écrans ». Elle remplace la direction blanche/bleue précédente : fond lavande clair, rubans violets, texte bleu nuit, champs avec icônes et ombres légères, boutons violets dégradés. Les textes et contrôles restent natifs Flutter, et les formulaires sont défilables sur petit écran ou avec clavier/grandes polices.

- Démarrage animé : apparition et mise à l'échelle du vrai logo, avant l'accès aux pages.
- Première ouverture : présentation illustrée, titre « Votre passerelle vers l’enseignement supérieur », description, indicateurs et action **Commencer** ; **Passer** mène à la même étape suivante. Une préférence non sensible `orientia_intro_seen_v1` évite de répéter cette présentation. **Découvrir Orientia** permet de la revoir depuis la connexion.
- Connexion : e-mail, mot de passe avec œil, mémorisation facultative, récupération, Google, inscription. Entrées progressives, pression du bouton et chargement réel ; les animations d'entrée respectent la réduction des animations système.
- Inscription : **Nom et Prénom distincts**, e-mail, téléphone facultatif, mot de passe et confirmation avec visibilités indépendantes. Les noms sont envoyés séparément (`lastName`, `firstName`). Mot de passe : 12 caractères minimum et 72 octets UTF-8 maximum ; la jauge est indicative, calculée à partir de la saisie. Une demande acceptée n'ouvre pas une session et ne prouve pas la livraison d'un e-mail.
- Le logo existant est conservé dans `assets/images/orientia.png`. Sa variante `orientia_transparent.png` retire le fond carré pour l'interface. Aucun chapeau étudiant ne remplace la marque.
- L'illustration `welcome_reference.png` a été recréée à partir de la maquette avec l'outil intégré imagegen : même étudiante, sweat lavande, tablette, campus, cartes Formations/Bourses/Recommandations ; pas de chapeau ni de cadre téléphone. Cette illustration n'est pas une photographie d'un établissement réel. Le fichier source original du logo reste intact.

Provenance des assets : imagegen, mode édition à partir des fichiers fournis par le propriétaire. Logo : suppression du seul fond clair et des marges en conservant symbole, couleurs et nom. Illustration : extraction/recréation de la scène inférieure de la première maquette, fond lavande, conservation de la composition, retrait des chapeaux. Le « G » est l'asset officiel Google utilisé aussi dans le backoffice. Les rubans et boutons sont dessinés en Flutter. La génération d'illustration ne garantit pas une identité pixel à pixel avec la maquette ; le contrôle visuel sur appareil reste distinct des tests de composants.

## Architecture et fonctionnalités conservées

`lib/app.dart` contrôle l'introduction et la session ; `core/network` porte Dio, authentification et stockage sécurisé ; `core/models` représente les contrats ; les repositories portent les appels métier ; les écrans sont dans `features/`.

| Parcours | Contrats / comportement |
|---|---|
| Authentification | POST `/auth/login`, `/auth/refresh`, `/auth/logout` ; GET `/auth/me` |
| Compte et récupération | Inscription, vérification par jeton, renvoi conditionnel, demande de récupération, réinitialisation, modification du compte/mot de passe |
| Profil académique | GET/PUT `/candidates/me/academic-profile`, version et confirmation serveur ; données absentes conservées inconnues |
| Relevés et OCR | Upload multipart, suivi des analyses versionnées, correction des matières/notes, enregistrement puis confirmation idempotente ; aucune note OCR incertaine inventée |
| Catalogue | Pays/villes, universités, campus/facultés, formations, bourses et sources ; pagination, filtres et états vides/erreurs distincts |
| Recommandations | Calcul et explications côté Spring, historique ; aucun score d'admission arbitraire côté téléphone |
| Décision | Simulations, comparaison de formations, bourses, historique et exports selon les droits serveur |
| Assistant documentaire | Sessions/messages, réponse structurée et liens vers sources/fiches ; ne transforme pas un résultat de recherche en décision d'éligibilité |
| Fichiers | Exports PDF/CSV et partage ; nettoyage des fichiers privés temporaires aux transitions de session |

Les écrans de collecte académique existants restent séparés de la présentation de l'application. Le rôle et les permissions sont contrôlés côté serveur. Les trois états d'éligibilité, les critères manquants et les informations absentes ne sont pas remplacés par un succès fictif.

## Sécurité de session

Les jetons sont conservés dans `flutter_secure_storage` avec préférences chiffrées Android. **Se souvenir de moi** conserve l'enveloppe sécurisée ; décoché, les jetons restent uniquement en mémoire, y compris après renouvellement. Aucun mot de passe n'est mémorisé.

Un transport d'authentification distinct renouvelle une seule fois sur 401, mutualise les requêtes concurrentes et reconstruit le multipart. Les epochs de session, l'annulation et les écritures sérialisées empêchent une réponse tardive de reconnecter un compte déconnecté. La restauration vérifie `/auth/me` ; hors réseau, l'accès aux données privées reste verrouillé. La déconnexion efface les clés locales même si la révocation distante échoue, et signale ce cas. Aucun token n'est journalisé ou placé dans une URL.

## Google et contacts

Client **Android** fourni : `1048361062873-9p9jrn2umec435bddqen2epn6fur93d8.apps.googleusercontent.com`. Il ne remplace pas un client OAuth Web. Le flux Google serveur/mobile n'est pas encore opérationnel : le bouton affiche cette indisponibilité, sans faux endpoint ni compte créé. Un client Web distinct, la validation OIDC serveur et les tests de liaison/permissions sont nécessaires avant activation.

Contact public : **lestudioviral@gmail.com**. Alertes administratives côté serveur : **adminorientia@gmail.com**. Aucune clé SendGrid, aucun secret JWT ou identifiant PostgreSQL ne doit entrer dans Flutter.

## Vérifications et limites

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

La campagne courante a obtenu **41 tests réussis** après refonte, dont introduction, grandes polices, session non persistée et protections de renouvellement. Analyse Flutter sans anomalie ; APK debug production compilé. Version 1.2.0 installée sur Samsung SM-A326B, écrans présentation/connexion/inscription observés et navigation publique exercée, sans saisie de compte, envoi de formulaire ou effacement des données. Un ajustement final du bouton retour conserve la hauteur utile du formulaire. Les captures temporaires de recette ne sont pas ajoutées au dépôt.

Les tests utilisent des transports simulés et des données synthétiques. `test_live/backend_journey_test.dart` n'est lancé qu'avec la fixture `F33_LIVE_FIXTURE`, via le harnais backend isolé `MobileFlutterJourneyIT`. Les commandes `python tool/run_backend_journey.py` et `--full` nécessitent les configurations temporaires F1/F2 et un PostgreSQL **privé** déjà démarré. Ne jamais viser Render avec ce harnais. L'ancien résultat de ce parcours ne compte pas comme nouvelle exécution.

Aucun compte candidat de test autorisé n'est disponible en production. Les parcours authentifiés de production, la délivrabilité SendGrid, le lecteur d'écran et les garanties Keystore sur appareil ne sont pas présentés comme validés par les tests simulés. Les contrôles publics précédents ont établi la santé du service, pas l'exécution de chaque fonctionnalité métier.

## Historique consolidé

| Lot | Travaux réalisés et portée |
|---|---|
| F3.3 | Intégration des parcours candidats F1–F3.2, contrats API, secure storage, navigation et tests ; 32 tests mobiles historiques |
| Synchronisation GitHub | Revue des fichiers et secrets, intégration sans force-push ; conservation des fonctionnalités et des migrations backend |
| Nouveau Render | URL de production explicite, local conservé, contrôle du préfixe, script de téléphone ; pas de secret embarqué |
| Stabilisation mobile | Contrats et états de chargement/erreur/vide, 35 tests avant le travail de présentation ; aucune recette authentifiée de production revendiquée |
| Présentation initiale 1.1.0 | Splash, illustration et formulaires blancs ; version installée et observée sur Samsung, ensuite désinstallée par le propriétaire |
| Référence utilisateur 1.2.0 | Remplacement par la maquette violette fournie, logo sans carré, identité séparée, animations et mémorisation facultative ; documentation unifiée dans ce README |

Les rapports supprimés couvraient F3.3, préservation/preuves, synchronisation, audit Render et validation mobile. Leurs détails historiques restent dans les commits, pas dans de nouveaux rapports concurrents.
