# Orientia mobile — connexion au backend Render et validation

Date : 8 novembre 2026. Backend fourni par le propriétaire : **https://orientation-backend-d0ys.onrender.com**. Cette mission modifie uniquement le projet mobile ; aucune API Spring, donnée de production, ressource Render ou configuration SendGrid modifiée. Aucun compte créé et aucun email envoyé. Le propriétaire confirme ne pas disposer d'un compte candidat de test autorisé : **les parcours authentifiés ne sont pas validés sur la production**.

## 1. Configuration trouvée avant modification

Arbre Git mobile initial propre, branche `master`, HEAD `a80ec126394b8ba0e07b570b91c6759012cbd576`. Audit des constantes, du client Dio et de ses intercepteurs, du stockage, des repositories, des modèles, des écrans et du script Android avant les modifications.

- `AppConstants.apiBaseUrl` lisait uniquement la constante de compilation `API_BASE_URL`, avec défaut `http://10.0.2.2:8080/api/v1`.
- `APP_ENV` était une constante de compilation, par défaut `development`. Elle imposait HTTPS en production mais ne sélectionnait pas une URL de production.
- `ORIENTIA_API_URL` était seulement une variable de terminal mentionnée dans le README. Flutter ne lit pas directement cette variable PowerShell : elle devait être transmise à `API_BASE_URL` via `--dart-define`.
- Le script exigeait `--api-url`, détectait un Android physique et affichait une commande en environnement development, sans rien installer.
- Dio ne rajoute aucun préfixe : les méthodes appellent `/auth/...`, `/recommendations`, etc. Le préfixe local `/api/v1` appartient à la base URL ; le test existant vérifie sa conservation.
- Aucun ancien hostname Render dans `lib/` ou `tool/`. Les anciennes adresses sont conservées dans les rapports historiques. L'URL fictive de build release du README était une instruction obsolète, désormais remplacée par l'URL réelle.
- Les adresses `.example.test` dans `test/`, le serveur loopback du harnais isolé et l'adresse émulateur restent des fixtures/environnements de développement. Ils ne sont pas utilisés par les commandes de production ci-dessous.

## 2. Fichiers modifiés ou ajoutés

| Fichier | Changement |
|---|---|
| `lib/core/constants/api_endpoints.dart` | Constantes publiques partagées : nouveau backend et URL locale |
| `lib/core/constants/app_constants.dart` | Défaut Render pour `APP_ENV=production`, défaut local préservé, refus d'un chemin ajouté au hostname de production |
| `tool/android_phone_command.dart` | URL connue par défaut, prise en compte de `ORIENTIA_API_URL`, surcharge `--api-url`, commande affichée avec `APP_ENV=production` |
| `test/production_configuration_test.dart` | Sélection d'environnement, racine HTTPS, login et refresh simulés sans préfixe |
| `test_live/public_render_smoke_test.dart` | Contrôle réel explicite des seuls endpoints GET publics, sans compte ni jeton |
| `README.md` | Commandes réelles production, local, APK et téléphone ; clarification des variables |
| Ce rapport | Contrats audités, preuves et limites |

Aucun écran supprimé, aucun projet reconstruit, aucun identifiant ou mécanisme de signature changé. Les changements restent dans l'arbre de travail ; aucun commit/push n'est effectué dans cette mission.

## 3. Configuration et sécurité retenues

`APP_ENV=production` sélectionne `https://orientation-backend-d0ys.onrender.com` si `API_BASE_URL` n'est pas fournie. Une `API_BASE_URL` explicite reste prioritaire. Sans paramètres, le développement local reste `http://10.0.2.2:8080/api/v1`.

Pour le hostname Render connu, seuls le chemin vide et `/` sont admis. Les valeurs contenant `/api/v1`, `/api/v1/api/v1` ou un endpoint complet sont rejetées. Aucun ajout automatique de préfixe et aucune substitution d'un endpoint existant. HTTPS obligatoire en production/release ; pas de certificat accepté artificiellement, d'URL contenant des identifiants ou de clé serveur embarquée.

Priorité du script : `--api-url` > variable de terminal `ORIENTIA_API_URL` > URL Render connue. Le script transmet l'adresse au processus Flutter sous forme de `--dart-define=API_BASE_URL=...`. Il refuse les chemins, paramètres et fragments, et n'exécute jamais `flutter run` lui-même.

Timeouts existants conservés : connexion 15 s, réception/envoi 90 s. Le délai de réception permet d'attendre un démarrage lent, mais ne constitue pas une garantie de disponibilité Render. Les erreurs réseau ont un message et un bouton de nouvelle tentative selon l'écran ; aucun POST métier n'est rejoué arbitrairement.

Session Android : `flutter_secure_storage` avec préférences chiffrées ; les anciens emplacements sont effacés à la déconnexion. Le client met le Bearer sur les appels protégés, utilise `/auth/refresh` sur 401, mutualise les renouvellements concurrents, rejoue une seule fois et invalide une session refusée. Les générations de session, l'annulation et les écritures sérialisées empêchent une réponse tardive de restaurer un compte déconnecté. Les tests existants couvrent aussi la reconstruction multipart après 401, la restauration hors réseau et le changement de compte. Aucun log des jetons ajouté.

La navigation ouvre l'accueil seulement après acceptation d'une vraie paire de jetons et d'un utilisateur ; une restauration vérifie `/auth/me`. Hors réseau, les écrans privés restent verrouillés. Les tests utilisent un stockage simulé : le fonctionnement du Keystore sur un téléphone réel n'est pas annoncé comme vérifié.

## 4. Modules et contrats examinés

Les contrats ont été comparés aux sources locales Spring sur `main`, HEAD `019c9b1fd9f2ef4a060a5fda968a411b0d8275fa`. L'identité exacte de ce SHA avec l'instance déployée n'est pas établie par l'API publique. L'OpenAPI distant est vide ; cette comparaison n'est donc pas une validation exhaustive du contrat déployé.

| Module / écran présent | Contrats examinés | Points vérifiés dans le code ; statut réel |
|---|---|---|
| Connexion, session, déconnexion | POST `/auth/login`, `/auth/refresh`, `/auth/logout` ; GET `/auth/me` | JSON email/password, paire de jetons et utilisateur ; erreurs 401/403, email non vérifié ; tests simulés, pas de login production |
| Inscription | POST `/auth/register` | firstName, lastName, email, phone, password ; réponse acceptée sans connexion automatique ; envoi interdit durant cette mission |
| Récupération et vérification | POST `/auth/forgot-password`, `/auth/reset-password` ; GET `/auth/verify?token=...` | email ou token/newPassword ; extraction d'un token collé depuis un lien ; aucune requête réelle, y compris GET verify qui consomme un jeton |
| Compte / mot de passe | GET/PUT `/auth/me`, PUT `/auth/me/password` | DTO coordonnées et currentPassword/newPassword ; session invalidée après changement ; pas d'écriture production |
| Accueil et profil académique | GET/PUT `/candidates/me/academic-profile` | DTO versionné, données numériques, références, consentement et confirmedAt ; concurrence 409 ; accueil candidat non testé avec un compte administrateur |
| Référentiels | GET `/locations/countries`, `/academic-years`, `/grade-scales`, `/subjects` | Listes JSON, identifiants et codes, filtre de barème ; **seuls les pays sont testés réellement en production** |
| Universités, campus, facultés et formations | GET listes/détails, `/{resource}/{id}/sources`, `/admission-criteria?programId=...` | Pages Spring content/totalElements/number/size, filtres pays/année/langue/relations, sources ; comparaison statique, aucune lecture privée production |
| Relevés et OCR | GET/POST `/transcripts`, GET/POST `/{id}/analyses`, PUT `/{analysisId}`, POST `/{analysisId}/confirm` | Multipart file + academicYearId ; Analyze gradeScaleId/period ; review average/marks/pages/passages ; taille et signature du fichier avant envoi ; aucune transmission réelle |
| Recommandations | GET `/recommendations`, `/recommendations/history`, POST `/recommendations/generate` | runId, pages, profil confirmé avant génération, score nullable, statut inconnu traité comme données insuffisantes ; tests locaux ciblés |
| Simulations | POST `/recommendations/simulate` | modifiedGeneralAverage/Grades/Countries/Fields/Language/BacSeries ; aucune sauvegarde du profil ; test simulé vérifie cette séparation |
| Comparaison de formations | POST `/ai/compare/programs`, GET `/ai/decisions/{id}` | programIds, sélection de 2 à 6, restitution de décision ; contrat local comparé, pas de calcul production |
| Bourses | GET `/scholarships`, détails/sources ; POST `/scholarships/evaluate` | scholarshipIds/programId, disponibilité séparée de l'éligibilité ; aucune évaluation réelle |
| Assistant et recherche | GET/POST `/ai/chat/sessions`, GET/POST messages, GET `/knowledge/search` | message, programIds, recommendationId, simulation explicite ; pages d'historique et sources ; pas de session créée en production |
| Historique, décisions et exports | GET `/ai/decisions?kind=...`, `/recommendations/history`, `/ai/export/{pdf,csv,excel}/{id}` | Métadonnées, kinds, byte responses et signatures PDF/XLSX, partage conditionné à la même session ; tests existants, aucun export production |
| Onboarding et API auxiliaires | Wrapper de profil académique ; méthodes guides du client | Onboarding délègue au profil, sans nouveau parcours automatique ; pas d'écran de guides autonome inventé |

Les listes ont des états de chargement, d'erreur et de vide, et les écrans principaux permettent de réessayer. Les catalogues/historiques utilisent des numéros de génération pour écarter les résultats obsolètes ; boutons de traitement désactivés pendant une opération. Les modèles correspondent aux objets racine/records JSON et aux pages Spring observés dans les sources, sans inventer d'enveloppe `data` globale.

Le mobile vise le candidat ; le serveur contrôle la propriété et le tenant des ressources. Chat/comparaison/exports imposent notamment les rôles CANDIDAT/ADMIN/SUPER_ADMIN et les services vérifient le propriétaire. Une connexion administrateur fonctionnelle au backoffice ne prouve pas l'existence d'un profil candidat dans le mobile. Aucune permission backend assouplie et aucun identifiant de candidat arbitraire ajouté aux requêtes personnelles.

## 5. Vérifications réellement exécutées

| Contrôle | Résultat |
|---|---|
| GET HTTPS public `/actuator/health` | HTTP 200, status UP |
| GET HTTPS public `/locations/countries` | HTTP 200, liste JSON de 42 pays lors du contrôle |
| GET public `/api-docs` | HTTP 200 mais **paths vide**, serveurs obsolètes ; limite détaillée plus bas |
| Test réel Flutter/Dio public explicite | Réussi : health UP et pays JSON via le vrai client, stockage mémoire vide, aucun compte ni jeton |
| `flutter test --reporter expanded` | **35 tests réussis**, dont les 3 nouveaux tests de configuration |
| Tests configuration avec `APP_ENV=production` | **3 tests réussis**, nouvelle URL par défaut et renouvellement simulé |
| `flutter analyze` final | Aucune anomalie, code retour 0 |
| Build APK debug avec APP_ENV production + URL réelle | Réussi, assembleDebug |
| ADB | Liste vide : aucun téléphone Android autorisé détecté |

Le contrôle public réel est opt-in et ne fait que deux GET publics :

```powershell
flutter test test_live/public_render_smoke_test.dart --dart-define=ORIENTIA_PUBLIC_SMOKE=true --dart-define=APP_ENV=production
```

Les autres tests sont simulés. Le harnais `test_live/backend_journey_test.dart` est réservé à son backend/PostgreSQL isolés et n'a pas été lancé contre Render. Aucun POST, PUT, DELETE, login, inscription ou appel authentifié n'a été effectué sur la production.

## 6. APK et Android

APK : `build/app/outputs/flutter-apk/app-debug.apk`, 177 048 556 octets.

SHA-256 : `27b0de7739358e8012333c810222ac9611c1cb6e46a67eba9a13c799692c4088`.

Inspection du paquet compilé : `com.orientia.orientia`, version 1.0.0/code 1, minSdk 24, target/compile SDK 36, permission INTERNET, APK debuggable. Aucun changement de package ou de signature. Le manifeste principal interdit le trafic clair et les sauvegardes ; le manifeste debug autorise HTTP pour conserver le développement local, tandis que la configuration applicative production exige HTTPS.

Cet APK est un artefact de recette, pas un APK signé pour distribution. Le build release existant utilise toujours la signature debug ; une livraison magasin nécessite une configuration de signature privée distincte. L'APK n'est ni installé ni publié et reste ignoré par Git.

## 7. Commandes exactes

Lancement avec le backend fourni :

```powershell
flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

Sur téléphone, connecter USB et autoriser le débogage, puis :

```powershell
dart run tool/android_phone_command.dart
```

Le script affiche la commande exacte incluant `-d` et l'identifiant physique détecté. Aucun identifiant n'est inventé dans ce rapport. Le simple `flutter run` sans cible n'affirme pas qu'un téléphone est branché.

Génération de l'APK de test :

```powershell
flutter build apk --debug --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://orientation-backend-d0ys.onrender.com
```

Développement local conservé :

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

## 8. Limites et corrections Spring éventuelles

L'accès HTTPS et les deux API publiques sont validés par le client mobile réel. **L'inscription, la connexion candidat, les profils, relevés/OCR, recommandations, comparaisons, bourses, assistant, historiques et exports ne sont pas validés fonctionnellement en production**, faute de compte autorisé. La compilation et les tests simulés ne remplacent pas cette recette ni celle du stockage sécurisé sur appareil.

Anomalie backend réellement constatée : `/api-docs` publie zéro chemin et des serveurs dont les URL contiennent l'ancien contexte `/api/v1`, notamment une adresse de production générique. À corriger côté Spring lors d'une mission backend : contrôler le filtre `springdoc.packages-to-scan`, inclure les packages réels modules/recengine/ai/knowledge et déclarer l'URL serveur de production racine correcte (ou une URL relative appropriée). Cette anomalie documentaire n'empêche pas les endpoints publics testés de fonctionner. Aucun correctif backend ou redéploiement déclenché ici.

Une recette finale doit utiliser un candidat de test autorisé, avec consentement explicite pour créer/modifier ses données et envoyer un relevé synthétique. Ne pas utiliser les identifiants administrateur de production comme substitut ni réutiliser les fixtures secrètes d'un ancien déploiement. Aucun secret n'est nécessaire dans ce rapport.

## Résultat final de l'analyse

`flutter analyze` : aucune anomalie (code retour 0). L'aide Android s'exécute avec l'import partagé valide et s'arrête avec le code attendu 2, accompagné des instructions USB/RSA, faute de téléphone détecté. Aucun lancement d'application. Les vérifications Git finales ne révèlent aucune modification backend ni fichier de configuration privée ajouté.
