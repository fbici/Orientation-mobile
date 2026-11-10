# Orientia mobile

Application Flutter Android de la plateforme Orientia. Le Bénin est le premier territoire couvert ; l'architecture conserve les autres pays. Dépôt : [Orientation-mobile](https://github.com/fbici/Orientation-mobile), branche `master`. Dernière consolidation : 10 novembre 2026.

Ce README est la documentation de référence du projet. Toute modification doit actualiser ici les comportements, commandes, résultats et limites utiles. Aucun nouveau rapport de sprint, récapitulatif ou fichier de preuves n'est à créer. Les anciens documents ont été consolidés puis supprimés ; leur historique reste consultable dans Git.

## Démarrage et Android

Flutter/Dart selon `pubspec.yaml` et `pubspec.lock`, Android SDK, JDK fourni par Android Studio. Version de cette interface : **1.3.1+5**. Package : **`com.orientia.orientia`**. Recette avec Flutter 3.38.4 / Dart 3.10.3 ; aucun remplacement du projet ou de son SDK.

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
- Première ouverture : trois présentations illustrées — découverte, choix du parcours, bourses. Rotation toutes les 7 secondes, balayage manuel et points cliquables, commande de pause/reprise. La rotation s'arrête hors premier plan ou si la réduction des animations/navigation accessible est activée ; la navigation manuelle reste disponible. **Commencer** et **Passer** mènent à la même étape suivante. Une préférence non sensible `orientia_intro_seen_v1` évite de répéter cette présentation. **Découvrir Orientia** permet de la revoir depuis la connexion.
- Connexion : e-mail, mot de passe avec œil, mémorisation facultative, récupération, Google, inscription. Entrées progressives, pression du bouton et chargement réel ; les animations d'entrée respectent la réduction des animations système.
- Inscription : **Nom et Prénom distincts**, e-mail, téléphone facultatif, mot de passe et confirmation avec visibilités indépendantes. Les noms sont envoyés séparément (`lastName`, `firstName`). Mot de passe : 12 caractères minimum et 72 octets UTF-8 maximum ; la jauge est indicative, calculée à partir de la saisie. Une demande acceptée n'ouvre pas une session et ne prouve pas la livraison d'un e-mail.
- Récupération : même présentation lavande et marque que les formulaires. Demande par e-mail, saisie du lien reçu ou de son jeton sécurisé de 43 caractères, nouveau mot de passe confirmé, vérification d'adresse. Les succès ne prétendent pas qu'un e-mail a été livré ; les liens expirés/utilisés sont expliqués. Aucun lien collé n'est ouvert sur le réseau. Le retour à la connexion reste explicite après reset ; aucun App Link Android automatique ni endpoint distinct de renvoi de vérification n'est ajouté.
- Les pages métier utilisent désormais la palette violette commune pour navigation, actions, cartes et chargements. L'accueil affiche le logo ; les parcours et droits sont conservés. Cette harmonisation ne vaut pas une recette visuelle exhaustive de tous les écrans authentifiés.
- Le logo existant est conservé dans `assets/images/orientia.png`. Sa variante `orientia_transparent.png` retire le fond carré pour l'interface. Aucun chapeau étudiant ne remplace la marque.
- L'illustration `welcome_reference.png` a été recréée à partir de la maquette avec l'outil intégré imagegen : même étudiante, sweat lavande, tablette, campus, cartes Formations/Bourses/Recommandations ; pas de chapeau ni de cadre téléphone. Cette illustration n'est pas une photographie d'un établissement réel. Le fichier source original du logo reste intact.

Provenance des assets : imagegen, mode édition à partir des fichiers fournis par le propriétaire. Logo : suppression du seul fond clair et des marges en conservant symbole, couleurs et nom. Illustration : extraction/recréation de la scène inférieure de la première maquette, fond lavande, conservation de la composition, retrait des chapeaux. Le « G » est l'asset officiel Google utilisé aussi dans le backoffice. Les rubans et boutons sont dessinés en Flutter. La génération d'illustration ne garantit pas une identité pixel à pixel avec la maquette ; le contrôle visuel sur appareil reste distinct des tests de composants.

Les variantes `welcome_orientation.png` et `welcome_scholarships.png` ont été générées avec imagegen à partir du style de la première scène : étudiant construisant son parcours et étudiante préparant son dossier. Elles ne représentent ni établissement réel, ni promesse d'obtention d'une bourse.

## Téléphones internationaux

L'inscription et la modification du profil partagent `InternationalPhoneField` : tous les pays fournis par la bibliothèque, recherche, drapeau et indicatif ; Bénin favori et sélection initiale, sans restriction aux numéros béninois. Le numéro reste facultatif. Les métadonnées de `phone_form_field` 10.0.18 / `phone_numbers_parser` 9.0.29 valident le numéro national du pays choisi ; l'API reçoit la forme internationale E.164 (`+` suivi des chiffres). Les versions sont verrouillées pour la reproductibilité et doivent être maintenues selon les évolutions des plans nationaux.

Le backend revalide et normalise avec Google libphonenumber 9.0.43. Il refuse les numéros nationaux ambigus sans indicatif et les extensions ; les anciens numéros stockés ne sont pas réécrits en masse. Au Bénin, le préfixe national `01` et dix chiffres sont requis depuis le 30 novembre 2024 : exemple de format `+229 01 XX XX XX XX`. [ARCEP Bénin](https://web.arcep.bj/passage-des-numero-a-10-chiffre/), [métadonnées Google](https://github.com/google/libphonenumber/releases), [standard E.164](https://www.itu.int/ITU-T/recommendations/rec.aspx?lang=en&rec=16273). Une validation de format ne prouve pas la propriété ou l'existence d'une ligne ; aucun SMS de vérification n'est annoncé.

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

Client **Android** fourni : `1048361062873-9p9jrn2umec435bddqen2epn6fur93d8.apps.googleusercontent.com`. Il identifie le package et son certificat SHA-1 dans Google Cloud. Le bouton n'est plus un dialogue « en développement » : `google_sign_in` ouvre l'authentification Android, puis le jeton d'identité est envoyé par POST `/auth/google`. Une session n'est ouverte qu'après acceptation des vrais jetons Orientia par le backend. L'annulation et les erreurs ne connectent pas l'utilisateur. Les jetons bénéficient de la même politique de mémorisation et de renouvellement que la connexion par mot de passe.

Le client **Application Web** a été fourni : `1048361062873-j7dmfajmue27jhbs1ms7jmbpnpa5pcp3.apps.googleusercontent.com`. Il est maintenant utilisé comme audience publique par défaut lorsque `APP_ENV=production`, dans `core/constants/google_oauth.dart`. `--dart-define=GOOGLE_WEB_CLIENT_ID=...` reste prioritaire ; en développement, aucune audience n'est imposée sans cette option. Le client Android package/certificat est conservé dans Google Cloud. [Documentation officielle du plugin Android](https://pub.dev/packages/google_sign_in_android), [vérification côté serveur Google](https://developers.google.com/identity/sign-in/android/backend-auth). Aucun secret client OAuth ni fichier téléchargé `client_secret_*.json` n'entre dans Flutter ou Git.

Le profil backend `prod` utilise cette même audience publique et active désormais Google par défaut après son déploiement. `GOOGLE_WEB_CLIENT_ID` et `GOOGLE_ENABLED` restent des surcharges Render ; une ancienne valeur `GOOGLE_ENABLED=false` le désactive. Les autres profils restent désactivés par défaut. Aucun client secret ni URI de callback Web n'est requis pour ce flux natif ID-token. Les comptes existants avec le même e-mail ne sont pas liés automatiquement : utiliser leur mot de passe. Une nouvelle identité Google vérifiée crée uniquement un compte candidat. La migration V84 et le nouveau code doivent réellement être déployés avant la recette ; un APK compilé ne met pas à jour Render.

Les commandes du début fonctionnent désormais avec l'audience de production intégrée. Pour utiliser explicitement une autre audience publique, la placer dans `$env:GOOGLE_WEB_CLIENT_ID`, puis :

```powershell
flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com --dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com --dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID
dart run tool/android_phone_command.dart
```

Le script reprend par défaut l'audience de production et l'ajoute à la commande affichée. La variable de terminal `GOOGLE_WEB_CLIENT_ID` ou `--google-web-client-id` la remplace. Les tests de compilation couvrent les profils local/production et la surcharge explicite. La connexion Google réelle en production n'est pas déclarée validée ; le client Android doit correspondre au package/SHA-1 de l'APK et les deux clients doivent appartenir au même projet Google Cloud.

## Diagnostic de l'inscription et du déploiement

L'inscription n'est acceptée que sur HTTP **202** avec un objet JSON contenant un message non vide. Un HTML 200 de proxy ou un accusé incomplet ne produit aucun succès. Pendant l'envoi, les champs et actions de visibilité sont désactivés, avec une seule requête ; aucun retry automatique n'est ajouté.

Un 503 contenant exactement le motif serveur `Email delivery unavailable; no delivery is confirmed` est présenté comme une indisponibilité de messagerie, sans exposer de détail fournisseur ni l'existence du compte. Un autre 503 reste une panne générale. Un délai de connexion/envoi/réception dépassé indique une demande non confirmée et invite à vérifier le résultat avant de réessayer ; il ne garantit pas qu'aucun traitement serveur n'a eu lieu.

Le journal communiqué le 10 novembre montre un build Docker réussi puis un déploiement expiré sans port détecté. La configuration du port dans le dépôt est déjà `PORT` / `0.0.0.0`. Le contrôle public a obtenu `/actuator/health` UP, mais OPTIONS `/auth/google` annonçait seulement GET/HEAD/OPTIONS. Ces constats ne certifient pas que le dernier backend est actif et ne permettent pas d'attribuer l'échec d'inscription à SendGrid. Il faut confirmer le déploiement Live et consulter les WARN à l'heure de la tentative, en contrôlant `SENDGRID_ENABLED`, la présence de la clé, l'expéditeur vérifié, `APP_BASE_URL` et éventuellement `PASSWORD_RESET_URL`, sans transmettre de secret. Les détails de démarrage et de configuration sont documentés dans le README backend.

Contact public : **lestudioviral@gmail.com**. Alertes administratives côté serveur : **adminorientia@gmail.com**. Aucune clé SendGrid, aucun secret JWT ou identifiant PostgreSQL ne doit entrer dans Flutter.

## Vérifications et limites

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

La campagne 1.3.1 a obtenu **68 tests réussis** et `flutter analyze` sans anomalie. Les tests supplémentaires d'audience Google passent en production et avec une surcharge explicite. Elle couvre les trois présentations et leur boucle/pause/accessibilité, la recherche et sélection réelle d'un pays, plusieurs plans téléphoniques, la récupération et le reset (transports simulés), l'échange du jeton Google, l'annulation, le conflit de compte et la protection contre les doubles clics. Les régressions d'inscription couvrent messagerie503, proxy503, HTML200, accusés202 incomplets, timeouts et formulaire figé avec soumission unique. Les protections de session/renouvellement et les parcours métier existants restent couverts.

APK debug **1.3.1+5** compilé avec la vraie URL Render et l'audience Google publique intégrée ; package/version contrôlés dans le manifeste de l'APK. Le Samsung était déconnecté au contrôle : cette nouvelle version n'a pas été installée par cette campagne. Pour une mise à jour conservant les données : `adb install -r build/app/outputs/flutter-apk/app-debug.apk` avec un appareil autorisé et la même signature.

Historique appareil : la 1.3.0+4 avait été installée par `adb install -r` sur Samsung SM-A326B. Connexion et nouvelle récupération observées, avec navigation publique vers le reset/vérification et message de configuration Google alors absente. Aucun formulaire n'a été soumis en production. Le sélecteur de pays et les trois présentations ont été testés automatiquement ; cette campagne ne prétend pas avoir observé chaque écran sur appareil. Les captures temporaires restent hors Git.

Backend associé : commit `162ff8de`, avec POST `/auth/google`, validation internationale et migration V84. Tests : 229 sur schéma PostgreSQL neuf puis 9 unitaires ciblés après deux régressions supplémentaires ; aucune base Render ni messagerie réelle utilisée. Push du code et activation/déploiement effectif sont distincts.

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
| Parcours 1.3.0 | Trois présentations illustrées automatiques/manuelles, récupération restylée et testée, téléphone international et validation serveur, authentification Google native raccordée sous configuration explicite ; harmonisation du thème métier |
| Activation 1.3.1 | Client Web public fourni et intégré en production, surcharge locale conservée, inscription sans faux succès avec erreurs précises et protection contre les doubles soumissions ; diagnostic du déploiement Render séparé de celui de SendGrid |

Les rapports supprimés couvraient F3.3, préservation/preuves, synchronisation, audit Render et validation mobile. Leurs détails historiques restent dans les commits, pas dans de nouveaux rapports concurrents.
