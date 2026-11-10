# Orientia mobile

Application Flutter Android de la plateforme Orientia. Le Bénin est le premier territoire couvert ; l'architecture conserve les autres pays. Dépôt : [Orientation-mobile](https://github.com/fbici/Orientation-mobile), branche `master`. Dernière consolidation : 10 novembre 2026.

Ce README est la documentation de référence du projet. Toute modification doit actualiser ici les comportements, commandes, résultats et limites utiles. Aucun nouveau rapport de sprint, récapitulatif ou fichier de preuves n'est à créer. Les anciens documents ont été consolidés puis supprimés ; leur historique reste consultable dans Git.

## Démarrage et Android

Flutter/Dart selon `pubspec.yaml` et `pubspec.lock`, Android SDK, JDK fourni par Android Studio. Version de cette interface : **1.4.0+7**. Package : **`com.orientia.orientia`**. Recette avec Flutter 3.38.4 / Dart 3.10.3 ; aucun remplacement du projet ou de son SDK.

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

- Démarrage : le logo statique du splash natif a été retiré pour éviter deux présentations successives. Android prépare Flutter sur le seul fond de marque ; la séquence animée de **3,2 secondes** démarre dès la première frame Flutter, sans attente de décodage, de réseau ou de restauration de session. Le délai de préparation du processus Android dépend encore du téléphone et du mode de compilation ; une animation Flutter ne peut pas précéder le démarrage de son moteur. Animations réduites/navigation accessible : logo statique pendant **700 ms**. Le démarrage à froid rejoue cette séquence ; une reprise depuis Google, le clavier ou la caméra ne redémarre pas le parcours. La restauration de session ne recrée pas le splash.
- Première ouverture : trois présentations illustrées — découverte, choix du parcours, bourses. Rotation toutes les 7 secondes, balayage manuel et points cliquables, commande de pause/reprise. La rotation s'arrête hors premier plan ou si la réduction des animations/navigation accessible est activée ; la navigation manuelle reste disponible. **Commencer** et **Passer** mènent à la même étape suivante. Une préférence non sensible `orientia_intro_seen_v1` évite de répéter cette présentation. **Découvrir Orientia** permet de la revoir depuis la connexion.
- Connexion : e-mail, mot de passe avec œil, mémorisation facultative, récupération, Google, inscription. Entrées progressives, pression du bouton et chargement réel ; les animations d'entrée respectent la réduction des animations système.
- Inscription : **Nom et Prénom distincts**, e-mail, téléphone facultatif, mot de passe et confirmation avec visibilités indépendantes. Les noms sont envoyés séparément (`lastName`, `firstName`). Mot de passe : 12 caractères minimum et 72 octets UTF-8 maximum ; la jauge est indicative, calculée à partir de la saisie. Une demande mobile acceptée ouvre directement l’écran de saisie du **code à six chiffres**, sans navigateur. Elle n’ouvre pas une session et ne prouve pas la livraison d’un e-mail.
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
| Compte et récupération | Inscription mobile `/auth/mobile/register`, code via POST `/auth/mobile/verify-email`, renvoi `/auth/mobile/resend-code` ; anciens liens et récupération par jeton conservés pour compatibilité |
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

Le journal initial montrait un déploiement expiré, puis le contrôle public a établi la présence de la route Google. Le propriétaire a ensuite confirmé le blocage de son offre SendGrid : le backend utilise désormais **Brevo**. Il confirme la rotation de la clé et l’enregistrement uniquement dans Render de `BREVO_API_KEY`, `BREVO_ENABLED=true` et `BREVO_FROM_EMAIL=adminorientia@gmail.com`, expéditeur vérifié. `BREVO_SENDER_NAME` est facultatif, défaut `Orientia`. Aucune clé n’entre dans Flutter. Vérifier le nouveau commit Live et les WARN avant une nouvelle tentative ; une configuration Render ne déploie pas le nouveau code automatiquement à elle seule.

Les e-mails côté serveur reprennent le vrai logo transparent, le fond lavande, une carte blanche, les titres bleu nuit et le bouton violet. Ils contiennent du texte lisible sans images et un lien de secours. Vérification valable 24 heures, reset une heure ; aucun envoi réel ni réception en boîte n’a été validé.
Contrôle après publication : OPTIONS `/auth/google` annonce désormais **POST/OPTIONS** et `/actuator/health` répond **HTTP 200 UP**. La route publique attendue est donc maintenant exposée. Ce constat ne certifie ni le SHA Live exact du tableau de bord, ni une connexion Google complète ou un e-mail d'inscription livré. Aucun formulaire ni compte réel n'a été utilisé pendant cette vérification ; la cause précise du 503 observé par l'utilisateur reste à confirmer dans les logs de sa tentative.

Contact public : **lestudioviral@gmail.com**. Alertes administratives côté serveur : **adminorientia@gmail.com**. Aucune clé Brevo, aucun secret JWT ou identifiant PostgreSQL ne doit entrer dans Flutter.

## Vérifications et limites

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

La campagne 1.3.2 a obtenu **73 tests réussis** et `flutter analyze` sans anomalie. Les tests supplémentaires d'audience Google passent en production et avec une surcharge explicite. Elle couvre les trois présentations et leur boucle/pause/accessibilité, la recherche et sélection réelle d'un pays, plusieurs plans téléphoniques, la récupération et le reset (transports simulés), l'échange du jeton Google, l'annulation, le conflit de compte et la protection contre les doubles clics. Les régressions d'inscription couvrent messagerie503, proxy503, HTML200, accusés202 incomplets, timeouts et formulaire figé avec soumission unique. Les protections de session/renouvellement et les parcours métier existants restent couverts.

APK debug **1.3.2+6** compilé avec la vraie URL Render et l’audience Google publique intégrée, puis installé avec succès par `adb install -r` sur Samsung SM-A326B (package `com.orientia.orientia`, versionName 1.3.2, versionCode 6 contrôlés). Démarrage à froid lancé sans effacement des données. Les deux captures ADB étaient noires : elles ne permettent pas de certifier le rendu visuel sur ce téléphone. Les tests couvrent la lisibilité et l’ordre du splash, la réduction des animations, le nettoyage à la fermeture, la restauration concurrente et la conservation binaire du vrai logo natif.
Historique appareil : la 1.3.0+4 avait été installée par `adb install -r` sur Samsung SM-A326B. Connexion et nouvelle récupération observées, avec navigation publique vers le reset/vérification et message de configuration Google alors absente. Aucun formulaire n'a été soumis en production. Le sélecteur de pays et les trois présentations ont été testés automatiquement ; cette campagne ne prétend pas avoir observé chaque écran sur appareil. Les captures temporaires restent hors Git.

Le contrat natif a été introduit dans le commit backend `162ff8de` (POST `/auth/google`, validation internationale, V84). Le profil de production avec l'audience Google reçue et les logs de démarrage visibles est livré dans **`eb3ccc02`**. Campagne historique précédente : **231 tests backend / 40 suites réussis**, puis JAR prod lancé hors `.env` sur un schéma PostgreSQL privé neuf, 85 migrations SQL et santé UP après 106,18 s. La route locale annonce POST/OPTIONS et refuse un jeton malformé sans appel Google réel. Aucun accès direct à la base Render ni envoi d'e-mail réel. Push du code et déploiement effectif restent distincts : attendre le bon commit Live avant la recette sur téléphone.

Les tests utilisent des transports simulés et des données synthétiques. `test_live/backend_journey_test.dart` n'est lancé qu'avec la fixture `F33_LIVE_FIXTURE`, via le harnais backend isolé `MobileFlutterJourneyIT`. Les commandes `python tool/run_backend_journey.py` et `--full` nécessitent les configurations temporaires F1/F2 et un PostgreSQL **privé** déjà démarré. Ne jamais viser Render avec ce harnais. L'ancien résultat de ce parcours ne compte pas comme nouvelle exécution.

Aucun compte candidat de test autorisé n'est disponible en production. Les parcours authentifiés de production, la délivrabilité Brevo, le lecteur d'écran et les garanties Keystore sur appareil ne sont pas présentés comme validés par les tests simulés. Les contrôles publics précédents ont établi la santé du service, pas l'exécution de chaque fonctionnalité métier.

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
| Démarrage et messagerie 1.3.2 | Splash natif et Flutter avec vrai logo, 73 tests réussis, APK compilé et installé ; migration Brevo et e-mails de marque côté backend, sans envoi réel |
| Activation 1.3.1 | Client Web public fourni et intégré en production, surcharge locale conservée, inscription sans faux succès avec erreurs précises et protection contre les doubles soumissions ; diagnostic du déploiement Render séparé de celui de SendGrid |

Les rapports supprimés couvraient F3.3, préservation/preuves, synchronisation, audit Render et validation mobile. Leurs détails historiques restent dans les commits, pas dans de nouveaux rapports concurrents.

## Corrections critiques — version 1.4.0

L’inscription mobile utilise désormais POST `/auth/mobile/register`. Un HTTP 202 n’est reconnu que s’il contient un message et un `challengeId` UUID valide. L’application conserve ce défi dans le parcours de création et affiche immédiatement `VerificationCodePage` avec l’adresse saisie, collage/autofill et clavier numérique, état de chargement unique, renvoi temporisé, erreurs et animation de confirmation. Aucun code n’est renvoyé par l’API, conservé comme jeton de session ou écrit dans les logs. Le mot de passe saisi est effacé du formulaire dès l’acceptation.

Le code envoyé par Brevo est valable dix minutes, à usage unique, limité à cinq essais et trois envois dans une période ; délai minimal de renvoi de 60 secondes. Le backend stocke un HMAC lié au défi et au secret serveur, pas le code en clair. Un refus ne valide pas le compte. Après réussite, **Aller à la connexion** reste une action explicite ; aucune session automatique et aucune navigation vers le backoffice. Les anciens liens et le reset de mot de passe restent disponibles séparément pour compatibilité. Une fermeture forcée complète de l’application n’est pas une persistance du parcours : recommencer la demande avec la même adresse permet au serveur de retrouver le défi éligible, selon ses limites.

L’accueil a été restructuré avec une illustration de marque, une prochaine étape issue du vrai profil et les mêmes accès métier : profil académique, relevés, recommandations, formations/comparaison, simulation, bourses, historique/exports. Cartes, listes, navigation et formulaires partagent la palette lavande/violette. Aucun score ni état d’avancement académique fictif n’est ajouté.

Validation finale locale : **77 tests Flutter réussis**, `flutter analyze` sans anomalie. APK **release 1.4.0+7** compilé avec la vraie URL Render, puis installé par `adb install -r` sur Samsung SM-A326B ; package/version contrôlés, données conservées. La signature reste la clé debug existante : cet APK sert à la recette sur téléphone, pas à une publication Play Store. Les tests du code utilisent des transports simulés ; aucun e-mail réel et aucun compte de production créé. Contrôle visuel ADB du 10 novembre sur le Samsung éveillé : captures successives du logo avec orbites en mouvement puis de la connexion ; aucun ancien logo natif figé en haut observé dans ces captures. Elles ne constituent pas une mesure exhaustive du temps de démarrage Android sur tous les appareils. Aucun formulaire de production soumis.

Commande optimisée de recette :

```powershell
flutter run --release -d RFCT30G1ABE --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

APK : `build/app/outputs/flutter-apk/app-release.apk`. Déployer le backend contenant V85/V86 avant de soumettre le nouveau formulaire ; les anciens clients restent compatibles avec leurs routes existantes. Le nouveau code vérifie les contrats et les droits localement, sans prétendre certifier tous les parcours authentifiés sur Render ni les facultés de toutes les universités du monde.
