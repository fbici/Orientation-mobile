# ORIENTIA — Sprint F3.3 : intégration Flutter

Date de travail : 7 novembre 2026. Etat des preuves arrete apres les executions decrites ci-dessous. Les limites de recette sont indiquees explicitement.

## A. Objet et statut

Integration des parcours candidats F1 a F3.2 dans l'application Flutter existante. Les appels metier passent par le backend ; aucun calcul local d'eligibilite ou de probabilite d'admission. Les resultats absents restent inconnus. La validation sur appareil Android et la livraison effective des emails restent a etablir.

## B. Audit initial et sauvegarde

Avant les modifications F3.3 : empreintes SHA-256 de 170 fichiers mobiles et 725 fichiers backend, inventaires Git de 35 et 285 lignes respectivement, copies originales du code Dart et des manifests de dependances conserves dans le repertoire temporaire orientia-f33-baseline. Les modifications preexistantes de marque, ressources, configuration native et des sprints precedents ont ete conservees. Inventaires complets en annexe.

Constats : navigation MaterialApp/Navigator avec StatefulWidget ; Riverpod et GoRouter declares mais non employes. Le client initial rafraichissait recursivement les tokens, utilisait plusieurs routes divergentes du backend et des replis locaux pour les donnees academiques. Le test compteur referencait une classe absente. Les ecrans ont ete raccordes dans leur arborescence existante et les composants communs regroupes.

## C. Architecture finale

ApiClient gere la session, les epochs de compte, Dio et un transport d'authentification separe. SecureSessionStore conserve une enveloppe JSON dans le stockage securise. OrientationRepository porte les contrats metier. Les modeles representent explicitement la pagination, la version du profil, les analyses et les trois etats d'eligibilite. Les widgets gerent chargement, erreur, reprise et reponses tardives. Aucun nouvel outil de gestion d'etat impose. Les requetes relatives conservent le prefixe serveur /api/v1, y compris si l'URL configuree finit par une barre oblique.

## D. Authentification

Connexion, inscription avec validation du mot de passe et confirmation, verification email par token, demande de recuperation, reinitialisation, modification de compte et de mot de passe. Une inscription acceptee ne pretend pas qu'un email a ete livre. La restauration interroge /auth/me ; hors ligne, les pages privees restent verrouillees. Refresh mutualise avec une seule reprise, reconstruction du multipart et absence de resurrection apres deconnexion. La deconnexion efface l'identite locale et demande la revocation au serveur avec bearer et refresh token ; une impossibilite distante est affichee explicitement.

## E. Profil academique

Pays et annees provenant des referentiels, annee des notes distincte de l'admission, bareme filtre, matieres configurees, valeurs absentes nulles, type de bac distinct de la serie, preferences, budget/devise et revenus/periode explicites. Brouillon et confirmation personnelle separes. Version optimiste conservee ; conflit 409 explique. Une confirmation personnelle n'est jamais presentee comme une verification officielle.

## F. Releves et OCR

Selection PDF/PNG/JPEG avec verification de signature et limite de 10 Mo, apercu image et consentement avant transmission. Upload multipart rattache a l'annee des notes. Analyse backend avec bareme et periode explicites, historique pagine des versions, correction des notes/matieres/coefficients tout en preservant le texte source et la page. Confirmation bloquee si des modifications ne sont pas enregistrees. Selection d'une analyse confirmee puis confirmation explicite du profil. Aucune note inconnue convertie en zero. Nettoyage des fichiers temporaires du selecteur et des exports.

## G. Catalogues

Universites, campus, facultes, formations et bourses : pagination serveur, recherche et filtres de pays/annee/langue, detail et sources, liens hierarchiques et criteres d'admission. Montants et devises d'origine, dates et disponibilites inconnues affichees comme telles. Aucune certification ajoutee par le mobile.

## H. Recommandations

Generation uniquement depuis le profil persiste confirme. Liste paginee et historique des executions ; detail, classement, score, couverture, trois etats d'eligibilite, criteres et composants fournis par le serveur. Avertissements de sources obsoletes/profil modifie. Le score n'est pas une probabilite d'admission.

## I. Simulations

Changements hypothetiques explicites sur moyenne, notes, pays et preferences, transmis au moteur partage. Aucun PUT de profil. Affichage des resultats avant/apres et des changements de classement/eligibilite lorsqu'ils sont presents dans la reponse.

## J. Comparaisons et bourses

Selection de deux a six formations a travers les pages du catalogue ; comparaison canonique rechargee par identifiant. Evaluation des bourses par le backend, presentation des conditions, raisons, etats et sources disponibles. Aucun resultat favorable deduit d'un champ absent.

## K. Assistant

Sessions et messages persistants, reprise et pagination, intentions et contexte explicites, recommandations/formations/simulation rattachees aux appels. Etats ANSWERED, NEEDS_INPUT, INSUFFICIENT_DATA, HISTORICAL et UNSUPPORTED distingues. Reponse determinee et sourcee par le backend ; aucune promesse de modele externe payant. Les faits de recherche documentaire sont affiches sans badge d'eligibilite et ouvrent leur fiche universite, campus, faculte, formation ou bourse lorsque le backend fournit son identifiant.

## L. Historique et exports

Historique des recommandations, simulations, comparaisons et bourses ; consultation des decisions canoniques. PDF, CSV et XLSX telecharges avec authentification, comme octets ; signatures PDF et ZIP/XLSX controlees avant partage. Fichier temporaire prive et nom genere, nettoyage apres partage et changement de session. La session est recontrolee avant l'ouverture du partage. Le comportement natif reste a verifier sur appareil.

## M. Navigation et presentation

Identite visuelle et ressources Orientia conservees. Accueil, Explorer, Parcours, Assistant et Profil ; acces directs aux releves, historique, simulation et dossier academique. Ecrans charges a la demande. Formulaires defilants, erreurs avec reprise, actions desactivees pendant traitement, mots de passe masques. Polices systeme pour eviter les telechargements implicites de Google Fonts. Des tests de widgets couvrent un petit ecran et la fermeture des pages privees.

## N. Matrice ecran / endpoint / contrat

| Ecran | Appels | Contrat principal |
|---|---|---|
| Connexion/restauration | POST /auth/login, /auth/refresh ; GET /auth/me | accessToken, refreshToken, user |
| Inscription/verification | POST /auth/register ; GET /auth/verify?token | champs d'identite, mot de passe ; message 202 |
| Recuperation | POST /auth/forgot-password, /auth/reset-password | email ; token, newPassword |
| Compte/deconnexion | PUT /auth/me, /auth/me/password ; POST /auth/logout | identite ; currentPassword/newPassword ; refreshToken + bearer |
| Dossier academique | GET/PUT /candidates/me/academic-profile | version, data, confirmedAt |
| Referentiels | GET /locations/countries, /academic-years, /grade-scales, /subjects | listes serveur et filtres explicites |
| Releves | GET/POST /transcripts | Page, multipart file + academicYearId |
| OCR | GET/POST /transcripts/{id}/analyses ; PUT /{analysisId} ; POST /{analysisId}/confirm | gradeScaleId, period ; review et versions |
| Catalogue | GET /universities, /campuses, /faculties, /programs, /scholarships ; /{id} ; /{id}/sources | Page, detail et provenance |
| Criteres | GET /admission-criteria?programId | Page de criteres sources |
| Recommandations | POST /recommendations/generate ; GET /recommendations, /history, /{id}, /{id}/scores, /{id}/explanation | runId, rank, eligibilityStatus, score, explanation |
| Simulation | POST /recommendations/simulate | modifications hypothetiques ; DecisionView |
| Comparaison | POST /ai/compare/programs ; GET /ai/decisions/{id} | programIds ; comparaison puis decision canonique |
| Bourses | POST /scholarships/evaluate | scholarshipIds/programId ; DecisionView |
| Historique | GET /ai/decisions?kind | Page de DecisionView |
| Assistant | GET/POST /ai/chat/sessions ; GET/POST /{id}/messages | sessionId ; message et contexte ; Page de decisions/messages |
| Exports | GET /ai/export/pdf|csv|excel/{id} | octets authentifies |

La base URL est configurable par --dart-define=API_BASE_URL. Valeur de developpement : http://10.0.2.2:8080/api/v1 pour emulateur Android. APP_ENV=production et les builds release exigent HTTPS ; aucun contournement TLS. HTTP de debug limite aux adresses locales/privees IPv4 valides ; un nom DNS ressemblant a 10.x ou 192.168.x ne suffit pas. Android : permission INTERNET, sauvegarde desactivee, cleartext interdit dans le manifest principal et autorise uniquement en debug.

## O. Verifications et preuves

Environnement : Flutter 3.38.4, Dart 3.10.3, Java 21, PostgreSQL prive 18.4. Aucun appareil Android connecte et aucun AVD configure detecte. Aucun test sur appareil revendique.

| Commande / preuve | Resultat verifie |
|---|---|
| flutter pub get | Succes |
| flutter analyze | Aucune anomalie : No issues found! |
| flutter test --reporter expanded | 31 tests reussis : 26 tests unitaires/de contrats et 5 tests de widgets |
| flutter build web --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.test/api/v1 | Compilation JavaScript release reussie sur le code final. Aucun contact avec le domaine d'exemple, aucun deploiement |
| python tool/run_backend_journey.py | 1 test HTTP reel reussi : vrai client Dart, Spring et PostgreSQL prive |
| python tool/run_backend_journey.py --full | 178 tests backend / 29 suites, 0 echec, 0 erreur, 0 ignore |
| Empreintes backend preexistantes | 725 fichiers preserves, dont 83 migrations SQL et 95 fichiers Angular ; aucun fichier original modifie ou manquant |
| Arret PostgreSQL prive | Succes, cluster et donnees conserves |
| flutter build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1 | Succes : build/app/outputs/flutter-apk/app-debug.apk |
| flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.test/api/v1 | Succes : build/app/outputs/flutter-apk/app-release.apk, 50,4 Mo selon Flutter |
| Manifest release fusionne | usesCleartextTraffic=false ; allowBackup=false ; permission INTERNET presente |
| git diff --check | Aucun probleme d'espacement ; avertissements Git de normalisation LF/CRLF des registrants generes |

Les 31 tests Flutter couvrent : sessions et stockage, refresh concurrent, refus de refresh, restauration hors ligne, isolation des reponses entre comptes, deconnexion avec access expire, purge apres changement de mot de passe, reprise multipart, conservation du prefixe API, pagination et contrats, integrite des exports, refus des faux PDF, signatures des uploads, trois etats d'eligibilite, navigation privee, petit ecran avec facteur de texte 1,6, notes OCR inconnues et interdiction de confirmer une correction non enregistree, rendu des faits documentaires du chat sans verdict d'eligibilite et navigation vers leur fiche. Les fixtures restent limitees aux tests.

Le parcours HTTP reel realise : connexion et GET /auth/me ; dossier brouillon ; upload du vrai PDF synthetique marque NOT OFFICIAL ; extraction backend ; preservation d'une note inconnue ; correction d'une note ; trois versions d'analyse ; confirmation personnelle ; profil confirme ; recommandations du runId genere et sources ; simulation avec controle d'invariance de la version et des donnees du profil ; comparaison de trois formations ; evaluation des bourses ; chat persistant et lecture des messages ; historique ; PDF/CSV/XLSX reels ; refus 403 de consulter et exporter la decision d'un autre candidat ; deconnexion et purge locale.

Deux ecarts ont ete detectes et corriges par cette integration : prefixe servlet /api/v1 absent de l'URL initiale et melange de calculs historiques dans une liste non filtree. L'ecran recharge desormais le runId genere et selectionne le dernier calcul a l'ouverture. Les tests ont aussi corrige une course entre annulation de requete et purge securisee. Aucun test n'a ete desactive pour obtenir ces resultats.

Le build Web avertit que certaines dependances actuelles (notamment stockage securise Web) ne sont pas compatibles avec le dry-run Wasm. Le build JavaScript release reussit ; aucune compatibilite Wasm n'est revendiquee. Les essais Android ont identifie un artefact Kotlin 2.3.0 absent du cache ; sa copie officielle Maven Central a ete telechargee avec controle de l'empreinte publiee avant reprise. Le conflit de fusion du manifest debug a ete corrige par tools:replace limite au debug. Le build debug final a reussi. Le controle du manifest release hors ligne a rencontre des dependances Flutter release absentes du cache ; le build release en ligne avec HTTPS a ensuite reussi et le manifest fusionne a ete controle. Un essai direct initial avec le Java 25 du shell a ete remplace par Java 21, identique a celui de Flutter. Aucun contournement TLS ni acceptation automatique de licence n'a ete effectue.

Les journaux sont dans le repertoire temporaire local sous orientia-f33-*.log ; les resultats XML backend sont dans target/surefire-reports. Les fichiers temporaires du harnais contenant le releve et les identifiants synthetiques sont supprimes a sa sortie. Aucune livraison effective d'email n'a ete validee avec un fournisseur externe.

## P. Securite et preservation

Aucun token dans les journaux applicatifs, aucune cle/API distante imposee, aucune connexion a la base principale. Les reponses d'un compte precedent sont rejetees, l'arbre de navigation prive est reconstruit lors du changement de compte. Les donnees privees ne sont pas mises dans SharedPreferences. Aucune migration historique modifiee, aucune modification Angular realisee. Les tests backend ont utilise exclusivement PostgreSQL prive 127.0.0.1:59745, base orientia_f1 et schema F3.3 distinct.

## Q. Limites et recette restante

Verifier livraison email avec fournisseur configure, parcours natif sur appareil/emulateur, stockage securise Android, selection de fichiers et partage PDF/CSV/XLSX, comportement reseau reel et restauration apres fermeture. L'APK release produit est un artefact de validation : URL HTTPS d'exemple et configuration de signature debug deja presente dans le depot. Configurer une vraie URL de service et une signature de distribution externe avant livraison en magasin ; les secrets ne doivent pas entrer dans le code. Verification iOS/macOS sur environnement Apple requise. L'absence de source ne doit pas etre contournee pour remplir une demonstration. Aucun deploiement, commit ou push effectue.

## R. Verdict

Sprint partiellement termine au sens de la recette globale : fonctionnalites raccordees et validations automatiques reussies, parcours Dart/Spring reel verifie. La recette sur appareil Android, la livraison effective des emails et les validations sur environnement Apple ne sont pas etablies dans cet environnement. Aucun appareil Android ni AVD disponible ; les tests de widgets et le parcours HTTP ne sont pas presentes comme une recette materielle. Les builds Android debug, Android release et Web release ainsi que le manifest release sont verifies. Les preuves sont indiquees en section O et dans [SPRINT_F3_3_PREUVES.json](SPRINT_F3_3_PREUVES.json) ; la preservation des fichiers initiaux est detaillee dans [SPRINT_F3_3_PRESERVATION.json](SPRINT_F3_3_PRESERVATION.json).

## Annexe : inventaires Git captures avant modifications F3.3

### mobile

```text
M .gitignore
 M .idea/modules.xml
 M README.md
 M android/app/build.gradle.kts
 M android/app/src/main/AndroidManifest.xml
 M ios/Runner.xcodeproj/project.pbxproj
 M ios/Runner/Info.plist
 M linux/CMakeLists.txt
 M linux/runner/my_application.cc
 M macos/Runner.xcodeproj/project.pbxproj
 M macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
 M macos/Runner/Configs/AppInfo.xcconfig
 D orientation_mobile.iml
 M pubspec.lock
 M test/widget_test.dart
 M web/index.html
 M web/manifest.json
 M windows/CMakeLists.txt
 M windows/runner/Runner.rc
 M windows/runner/main.cpp
?? android/app/src/main/kotlin/com/orientia/
?? android/app/src/main/res/drawable-hdpi/
?? android/app/src/main/res/drawable-mdpi/
?? android/app/src/main/res/drawable-xhdpi/
?? android/app/src/main/res/drawable-xxhdpi/
?? android/app/src/main/res/drawable-xxxhdpi/
?? android/app/src/main/res/mipmap-anydpi-v26/
?? android/app/src/main/res/values/colors.xml
?? assets/
?? ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@1x.png
?? ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@2x.png
?? ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@1x.png
?? ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@2x.png
?? ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@1x.png
?? ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@2x.png
```

### backend

```text
M H.java
 M HashGen.java
 M frontend/.angular/cache/19.2.27/orientation-backoffice/.tsbuildinfo
 M frontend/angular.json
 M frontend/package-lock.json
 M frontend/package.json
 M frontend/src/app/administration/components/roles.component.ts
 M frontend/src/app/analytics/components/analytics.component.ts
 M frontend/src/app/app.routes.ts
 M frontend/src/app/auth/forgot-password/forgot-password.component.ts
 M frontend/src/app/auth/login/login.component.ts
 M frontend/src/app/auth/reset-password/reset-password.component.ts
 M frontend/src/app/core/interceptors/auth.interceptor.ts
 M frontend/src/app/core/services/api.service.ts
 M frontend/src/app/core/services/auth.service.ts
 M frontend/src/app/core/services/notification.service.ts
 M frontend/src/app/core/services/realtime.service.ts
 M frontend/src/app/core/services/websocket.service.ts
 M frontend/src/app/documents/components/documents.component.ts
 M frontend/src/app/documents/documents.routes.ts
 M frontend/src/app/imports/components/imports.component.ts
 M frontend/src/app/intelligence/intelligence.routes.ts
 M frontend/src/app/knowledge/components/knowledge.component.ts
 M frontend/src/app/knowledge/components/smart-query.component.ts
 M frontend/src/app/layout/layout.component.ts
 M frontend/src/app/recommendations/components/recommendations.component.ts
 M frontend/src/app/reports/components/reports.component.ts
 M frontend/src/app/rules/components/rules.component.ts
 M frontend/src/app/universities/components/universities.component.ts
 M frontend/src/app/universities/components/university-detail.component.ts
 M frontend/src/environments/environment.ts
 M frontend/src/index.html
 M frontend/tsconfig.app.json
 M frontend/tsconfig.spec.json
 M mvnw.cmd
 M pom.xml
 M src/main/java/com/orientation/orientationapp/ai/chat/controller/ChatController.java
 M src/main/java/com/orientation/orientationapp/ai/chat/model/ChatMessage.java
 M src/main/java/com/orientation/orientationapp/ai/chat/model/ChatSession.java
 M src/main/java/com/orientation/orientationapp/ai/chat/service/ChatService.java
 M src/main/java/com/orientation/orientationapp/ai/chat/service/impl/DefaultChatService.java
 M src/main/java/com/orientation/orientationapp/ai/comparator/controller/ComparisonController.java
 M src/main/java/com/orientation/orientationapp/ai/comparator/model/ComparisonResult.java
 M src/main/java/com/orientation/orientationapp/ai/comparator/service/ComparisonService.java
 M src/main/java/com/orientation/orientationapp/ai/comparator/service/impl/DefaultComparisonService.java
 M src/main/java/com/orientation/orientationapp/ai/export/controller/ExportController.java
 M src/main/java/com/orientation/orientationapp/ai/export/service/impl/DefaultExportService.java
 M src/main/java/com/orientation/orientationapp/backoffice/analytics/dto/response/AnalyticsResponse.java
 M src/main/java/com/orientation/orientationapp/backoffice/analytics/service/impl/AnalyticsServiceImpl.java
 M src/main/java/com/orientation/orientationapp/backoffice/config/WebSocketConfig.java
 M src/main/java/com/orientation/orientationapp/backoffice/dashboard/service/impl/DashboardServiceImpl.java
 M src/main/java/com/orientation/orientationapp/backoffice/monitoring/controller/DashboardSocketController.java
 M src/main/java/com/orientation/orientationapp/backoffice/monitoring/controller/MonitoringSocketController.java
 M src/main/java/com/orientation/orientationapp/backoffice/notification_center/controller/NotificationController.java
 M src/main/java/com/orientation/orientationapp/backoffice/notification_center/controller/NotificationSocketController.java
 M src/main/java/com/orientation/orientationapp/backoffice/notification_center/service/impl/NotificationServiceImpl.java
 M src/main/java/com/orientation/orientationapp/backoffice/report/service/impl/ReportServiceImpl.java
 M src/main/java/com/orientation/orientationapp/config/ProdDataInitializer.java
 M src/main/java/com/orientation/orientationapp/config/web/WebConfig.java
 M src/main/java/com/orientation/orientationapp/dataplat_history/entity/ImportHistoryRecord.java
 M src/main/java/com/orientation/orientationapp/dataplat_history/repository/ImportHistoryRecordRepository.java
 M src/main/java/com/orientation/orientationapp/dataplat_import/controller/ImportController.java
 M src/main/java/com/orientation/orientationapp/dataplat_import/entity/ImportEntityMapping.java
 M src/main/java/com/orientation/orientationapp/dataplat_import/service/impl/ImportOrchestratorImpl.java
 M src/main/java/com/orientation/orientationapp/dataplat_parser/strategy/impl/CsvParser.java
 M src/main/java/com/orientation/orientationapp/dataplat_parser/strategy/impl/ExcelParser.java
 M src/main/java/com/orientation/orientationapp/dataplat_quality/entity/QualityReportRecord.java
 M src/main/java/com/orientation/orientationapp/docintel/document/controller/DocumentController.java
 M src/main/java/com/orientation/orientationapp/docintel/document/entity/Document.java
 M src/main/java/com/orientation/orientationapp/docintel/document/entity/DocumentClassification.java
 M src/main/java/com/orientation/orientationapp/docintel/document/entity/DocumentExtraction.java
 M src/main/java/com/orientation/orientationapp/docintel/document/entity/DocumentMetadata.java
 M src/main/java/com/orientation/orientationapp/docintel/document/entity/DocumentPage.java
 M src/main/java/com/orientation/orientationapp/docintel/document/repository/DocumentRepository.java
 M src/main/java/com/orientation/orientationapp/docintel/document/service/impl/DocumentServiceImpl.java
 M src/main/java/com/orientation/orientationapp/docintel/ocr/engine/impl/LocalOcrEngine.java
 M src/main/java/com/orientation/orientationapp/exception/handler/GlobalExceptionHandler.java
 M src/main/java/com/orientation/orientationapp/intelligence/api/IntelligenceController.java
 M src/main/java/com/orientation/orientationapp/intelligence/extraction/EntityExtractionService.java
 M src/main/java/com/orientation/orientationapp/intelligence/indexing/SearchIndexService.java
 M src/main/java/com/orientation/orientationapp/intelligence/knowledge/KnowledgeGraphService.java
 M src/main/java/com/orientation/orientationapp/intelligence/ocr/OcrService.java
 M src/main/java/com/orientation/orientationapp/intelligence/ocr/impl/TesseractOcrEngine.java
 M src/main/java/com/orientation/orientationapp/intelligence/pipeline/DocumentProcessingPipeline.java
 M src/main/java/com/orientation/orientationapp/intelligence/pipeline/PersistenceService.java
 M src/main/java/com/orientation/orientationapp/intelligence/smartquery/SmartQueryEngine.java
 M src/main/java/com/orientation/orientationapp/knowledge/controller/KnowledgeController.java
 M src/main/java/com/orientation/orientationapp/knowledge/engine/service/impl/DefaultKnowledgeEngineService.java
 M src/main/java/com/orientation/orientationapp/knowledge/entity/KnowledgeNode.java
 M src/main/java/com/orientation/orientationapp/knowledge/entity/KnowledgeRelation.java
 M src/main/java/com/orientation/orientationapp/knowledge/entity/LearningHistory.java
 M src/main/java/com/orientation/orientationapp/knowledge/entity/SearchIndex.java
 M src/main/java/com/orientation/orientationapp/knowledge/entity/SimilarityMatrix.java
 M src/main/java/com/orientation/orientationapp/knowledge/graph/service/impl/DefaultKnowledgeGraphService.java
 M src/main/java/com/orientation/orientationapp/knowledge/repository/KnowledgeNodeRepository.java
 M src/main/java/com/orientation/orientationapp/knowledge/repository/KnowledgeRelationRepository.java
 M src/main/java/com/orientation/orientationapp/knowledge/repository/SearchIndexRepository.java
 M src/main/java/com/orientation/orientationapp/knowledge/search/service/SemanticSearchService.java
 M src/main/java/com/orientation/orientationapp/knowledge/search/service/impl/DefaultSemanticSearchService.java
 M src/main/java/com/orientation/orientationapp/knowledge/similarity/service/impl/DefaultSimilarityEngineService.java
 M src/main/java/com/orientation/orientationapp/knowledge/smartquery/service/impl/DefaultSmartQueryService.java
 M src/main/java/com/orientation/orientationapp/modules/admin/entity/ActivityLog.java
 M src/main/java/com/orientation/orientationapp/modules/admin/entity/Invitation.java
 M src/main/java/com/orientation/orientationapp/modules/admin/service/impl/InvitationServiceImpl.java
 M src/main/java/com/orientation/orientationapp/modules/admin/service/impl/OrganizationServiceImpl.java
 M src/main/java/com/orientation/orientationapp/modules/admin/service/impl/TenantServiceImpl.java
 M src/main/java/com/orientation/orientationapp/modules/admin/service/impl/UserAdminServiceImpl.java
 M src/main/java/com/orientation/orientationapp/modules/auth/controller/AuthController.java
 M src/main/java/com/orientation/orientationapp/modules/auth/controller/RegisterController.java
 M src/main/java/com/orientation/orientationapp/modules/auth/dto/request/ChangePasswordRequest.java
 M src/main/java/com/orientation/orientationapp/modules/auth/dto/request/RegisterRequest.java
 M src/main/java/com/orientation/orientationapp/modules/auth/dto/request/ResetPasswordRequest.java
 M src/main/java/com/orientation/orientationapp/modules/auth/entity/RefreshToken.java
 M src/main/java/com/orientation/orientationapp/modules/auth/entity/User.java
 M src/main/java/com/orientation/orientationapp/modules/auth/repository/RefreshTokenRepository.java
 M src/main/java/com/orientation/orientationapp/modules/auth/repository/RoleRepository.java
 M src/main/java/com/orientation/orientationapp/modules/auth/repository/UserRepository.java
 M src/main/java/com/orientation/orientationapp/modules/auth/service/EmailService.java
 M src/main/java/com/orientation/orientationapp/modules/auth/service/impl/AuthenticationServiceImpl.java
 M src/main/java/com/orientation/orientationapp/modules/auth/service/impl/RefreshTokenServiceImpl.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/controller/OrientationGuideController.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/entity/AdmissionCriterion.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/entity/GuideVersion.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/entity/OrientationGuide.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/repository/AdmissionCriterionRepository.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/repository/GuideVersionRepository.java
 M src/main/java/com/orientation/orientationapp/modules/orientation/repository/OrientationGuideRepository.java
 M src/main/java/com/orientation/orientationapp/modules/recommendation/entity/Recommendation.java
 M src/main/java/com/orientation/orientationapp/modules/recommendation/repository/RecommendationRepository.java
 M src/main/java/com/orientation/orientationapp/modules/scholarship/controller/ScholarshipController.java
 M src/main/java/com/orientation/orientationapp/modules/scholarship/entity/Scholarship.java
 M src/main/java/com/orientation/orientationapp/modules/scholarship/entity/ScholarshipCriterion.java
 M src/main/java/com/orientation/orientationapp/modules/scholarship/repository/ScholarshipCriterionRepository.java
 M src/main/java/com/orientation/orientationapp/modules/scholarship/repository/ScholarshipRepository.java
 M src/main/java/com/orientation/orientationapp/modules/transcript/controller/TranscriptController.java
 M src/main/java/com/orientation/orientationapp/modules/transcript/entity/Transcript.java
 M src/main/java/com/orientation/orientationapp/modules/transcript/entity/TranscriptAnalysis.java
 M src/main/java/com/orientation/orientationapp/modules/transcript/entity/TranscriptLine.java
 M src/main/java/com/orientation/orientationapp/modules/transcript/repository/TranscriptAnalysisRepository.java
 M src/main/java/com/orientation/orientationapp/modules/transcript/repository/TranscriptRepository.java
 M src/main/java/com/orientation/orientationapp/modules/university/controller/BeninOrientationController.java
 M src/main/java/com/orientation/orientationapp/modules/university/entity/Campus.java
 M src/main/java/com/orientation/orientationapp/modules/university/entity/Faculty.java
 M src/main/java/com/orientation/orientationapp/modules/university/entity/Program.java
 M src/main/java/com/orientation/orientationapp/modules/university/entity/University.java
 M src/main/java/com/orientation/orientationapp/modules/university/repository/CampusRepository.java
 M src/main/java/com/orientation/orientationapp/modules/university/repository/CountryRepository.java
 M src/main/java/com/orientation/orientationapp/modules/university/repository/FacultyRepository.java
 M src/main/java/com/orientation/orientationapp/modules/university/repository/ProgramRepository.java
 M src/main/java/com/orientation/orientationapp/modules/university/repository/UniversityRepository.java
 M src/main/java/com/orientation/orientationapp/modules/user/controller/CandidateController.java
 M src/main/java/com/orientation/orientationapp/modules/user/entity/Candidate.java
 M src/main/java/com/orientation/orientationapp/modules/user/repository/CandidateRepository.java
 M src/main/java/com/orientation/orientationapp/recengine/eligibility/engine/impl/RealEligibilityEngine.java
 M src/main/java/com/orientation/orientationapp/recengine/eligibility/model/EligibilityResult.java
 M src/main/java/com/orientation/orientationapp/recengine/profile/analyzer/impl/DefaultProfileAnalyzer.java
 M src/main/java/com/orientation/orientationapp/recengine/profile/model/AcademicProfile.java
 M src/main/java/com/orientation/orientationapp/recengine/ranking/engine/impl/DefaultRankingEngine.java
 M src/main/java/com/orientation/orientationapp/recengine/ranking/model/RankedRecommendation.java
 M src/main/java/com/orientation/orientationapp/recengine/recommendation/controller/RecommendationController.java
 M src/main/java/com/orientation/orientationapp/recengine/recommendation/dto/request/SimulationRequest.java
 M src/main/java/com/orientation/orientationapp/recengine/recommendation/engine/HistoricalEngine.java
 M src/main/java/com/orientation/orientationapp/recengine/scoring/engine/impl/DefaultScoringEngine.java
 M src/main/java/com/orientation/orientationapp/recengine/scoring/engine/impl/RealScoringEngine.java
 M src/main/java/com/orientation/orientationapp/recengine/simulation/engine/impl/DefaultSimulationEngine.java
 M src/main/java/com/orientation/orientationapp/security/config/SecurityConfig.java
 M src/main/java/com/orientation/orientationapp/security/filter/JwtAuthenticationFilter.java
 M src/main/java/com/orientation/orientationapp/security/jwt/JwtTokenProvider.java
 M src/main/java/com/orientation/orientationapp/security/service/CustomUserDetails.java
 M src/main/java/com/orientation/orientationapp/security/service/CustomUserDetailsService.java
 M src/main/java/com/orientation/orientationapp/storage/service/StorageService.java
 M src/main/java/com/orientation/orientationapp/storage/service/StorageServiceImpl.java
 M src/main/resources/application-dev.yml
 M src/main/resources/application-prod.yml
 M src/main/resources/application-test.yml
 M src/main/resources/application.yml
 M src/test/java/com/orientation/orientationapp/dataplat_import/ImportOrchestratorTest.java
 M src/test/java/com/orientation/orientationapp/integration/AuthIntegrationTest.java
 M src/test/java/com/orientation/orientationapp/integration/RecommendationIntegrationTest.java
 M src/test/java/com/orientation/orientationapp/recengine/ProfileAnalyzerTest.java
 M src/test/java/com/orientation/orientationapp/recengine/RankingEngineTest.java
 M src/test/java/com/orientation/orientationapp/recengine/ScoringEngineTest.java
 M src/test/java/com/orientation/orientationapp/recengine/SimulationEngineTest.java
 M src/test/resources/application-test.yml
?? SPRINT_F1_SECURITE_FONDATIONS.md
?? SPRINT_F2_BACKEND_METIER_DOCUMENT_INTELLIGENCE.md
?? SPRINT_F2_PREUVES.json
?? SPRINT_F3_1_MOTEUR_CANDIDAT_RECOMMANDATIONS.md
?? SPRINT_F3_1_PREUVES.json
?? SPRINT_F3_2_INTELLIGENCE_AVANCEE.md
?? SPRINT_F3_2_PREUVES.json
?? frontend/AUDIT_GLOBAL_ORIENTIA.md
?? frontend/src/app/catalog/
?? frontend/src/app/core/services/academic-api.spec.ts
?? frontend/src/app/core/services/auth.service.spec.ts
?? frontend/src/app/core/services/websocket.service.spec.ts
?? frontend/src/app/documents/components/document-review.component.spec.ts
?? frontend/src/app/documents/components/document-review.component.ts
?? frontend/src/app/intelligence/decisions.component.spec.ts
?? frontend/src/app/intelligence/decisions.component.ts
?? frontend/src/app/recommendations/components/recommendations.component.spec.ts
?? frontend/src/sockjs-polyfills.ts
?? src/main/java/com/orientation/orientationapp/ai/chat/model/AskRequest.java
?? src/main/java/com/orientation/orientationapp/ai/chat/service/AssistantIntentRouter.java
?? src/main/java/com/orientation/orientationapp/ai/comparator/dto/
?? src/main/java/com/orientation/orientationapp/ai/decision/
?? src/main/java/com/orientation/orientationapp/ai/history/
?? src/main/java/com/orientation/orientationapp/backoffice/config/PipelineSocketListener.java
?? src/main/java/com/orientation/orientationapp/backoffice/config/SocketAuthenticationInterceptor.java
?? src/main/java/com/orientation/orientationapp/docintel/document/controller/DocumentReviewController.java
?? src/main/java/com/orientation/orientationapp/docintel/document/dto/request/AddFactRequest.java
?? src/main/java/com/orientation/orientationapp/docintel/document/dto/request/PublishDocumentRequest.java
?? src/main/java/com/orientation/orientationapp/docintel/document/dto/request/ReviewFactRequest.java
?? src/main/java/com/orientation/orientationapp/docintel/document/entity/ExtractedFact.java
?? src/main/java/com/orientation/orientationapp/docintel/document/repository/ExtractedFactRepository.java
?? src/main/java/com/orientation/orientationapp/docintel/document/service/DocumentPagePreview.java
?? src/main/java/com/orientation/orientationapp/docintel/document/service/DocumentProcessingState.java
?? src/main/java/com/orientation/orientationapp/docintel/document/service/DocumentReviewService.java
?? src/main/java/com/orientation/orientationapp/docintel/document/service/FactPayloadMapper.java
?? src/main/java/com/orientation/orientationapp/docintel/ocr/engine/impl/PdfImageOcrEngine.java
?? src/main/java/com/orientation/orientationapp/docintel/ocr/engine/impl/TesseractProcess.java
?? src/main/java/com/orientation/orientationapp/intelligence/pipeline/AcademicPublicationService.java
?? src/main/java/com/orientation/orientationapp/modules/auth/dto/request/UpdateProfileRequest.java
?? src/main/java/com/orientation/orientationapp/modules/auth/entity/AccountToken.java
?? src/main/java/com/orientation/orientationapp/modules/auth/repository/AccountTokenRepository.java
?? src/main/java/com/orientation/orientationapp/modules/auth/service/AccountProfileService.java
?? src/main/java/com/orientation/orientationapp/modules/auth/service/AccountRecoveryService.java
?? src/main/java/com/orientation/orientationapp/modules/auth/service/LoginSessionIssuer.java
?? src/main/java/com/orientation/orientationapp/modules/auth/service/RegistrationService.java
?? src/main/java/com/orientation/orientationapp/modules/auth/service/impl/InvalidRefreshException.java
?? src/main/java/com/orientation/orientationapp/modules/auth/service/impl/LoginAttemptService.java
?? src/main/java/com/orientation/orientationapp/modules/orientation/controller/AcademicReferenceController.java
?? src/main/java/com/orientation/orientationapp/modules/orientation/controller/AdmissionCriterionController.java
?? src/main/java/com/orientation/orientationapp/modules/orientation/dto/
?? src/main/java/com/orientation/orientationapp/modules/orientation/service/
?? src/main/java/com/orientation/orientationapp/modules/recommendation/entity/RecommendationRun.java
?? src/main/java/com/orientation/orientationapp/modules/recommendation/repository/RecommendationRunRepository.java
?? src/main/java/com/orientation/orientationapp/modules/recommendation/service/
?? src/main/java/com/orientation/orientationapp/modules/scholarship/controller/ScholarshipEvaluationController.java
?? src/main/java/com/orientation/orientationapp/modules/scholarship/dto/
?? src/main/java/com/orientation/orientationapp/modules/scholarship/service/
?? src/main/java/com/orientation/orientationapp/modules/transcript/controller/TranscriptAnalysisController.java
?? src/main/java/com/orientation/orientationapp/modules/transcript/dto/
?? src/main/java/com/orientation/orientationapp/modules/transcript/service/
?? src/main/java/com/orientation/orientationapp/modules/university/controller/AcademicProvenanceController.java
?? src/main/java/com/orientation/orientationapp/modules/university/controller/CampusController.java
?? src/main/java/com/orientation/orientationapp/modules/university/controller/FacultyController.java
?? src/main/java/com/orientation/orientationapp/modules/university/controller/ProgramController.java
?? src/main/java/com/orientation/orientationapp/modules/university/controller/UniversityController.java
?? src/main/java/com/orientation/orientationapp/modules/university/dto/
?? src/main/java/com/orientation/orientationapp/modules/university/service/
?? src/main/java/com/orientation/orientationapp/modules/user/controller/CandidateAcademicController.java
?? src/main/java/com/orientation/orientationapp/modules/user/dto/
?? src/main/java/com/orientation/orientationapp/modules/user/service/
?? src/main/java/com/orientation/orientationapp/recengine/eligibility/model/EligibilityStatus.java
?? src/main/java/com/orientation/orientationapp/recengine/profile/normalization/
?? src/main/java/com/orientation/orientationapp/security/filter/AuthRateLimitFilter.java
?? src/main/java/com/orientation/orientationapp/security/service/AccountState.java
?? src/main/java/com/orientation/orientationapp/security/service/ResourceAccess.java
?? src/main/resources/db/migration/V63_1__legacy_seed_column_compatibility.sql
?? src/main/resources/db/migration/V65__secure_sessions.sql
?? src/main/resources/db/migration/V66__resource_ownership_and_permissions.sql
?? src/main/resources/db/migration/V67__missing_schema_objects.sql
?? src/main/resources/db/migration/V68__account_tokens.sql
?? src/main/resources/db/migration/V69__search_embedding.sql
?? src/main/resources/db/migration/V70__canonical_permission_grants.sql
?? src/main/resources/db/migration/V71__tenant_dashboard_permission.sql
?? src/main/resources/db/migration/V72__academic_catalog_scope.sql
?? src/main/resources/db/migration/V73__document_review_provenance.sql
?? src/main/resources/db/migration/V74__academic_uniqueness_per_tenant.sql
?? src/main/resources/db/migration/V75__knowledge_relationship_filters.sql
?? src/main/resources/db/migration/V76__tabular_import_evidence.sql
?? src/main/resources/db/migration/V77__candidate_academic_profile.sql
?? src/main/resources/db/migration/V78__recommendation_history.sql
?? src/main/resources/db/migration/V79__versioned_transcript_analyses.sql
?? src/main/resources/db/migration/V80__recommendation_runs.sql
?? src/main/resources/db/migration/V81__transcript_confirmation_idempotency.sql
?? src/main/resources/db/migration/V82__decision_support_history.sql
?? src/test/java/com/orientation/orientationapp/ai/
?? src/test/java/com/orientation/orientationapp/docintel/ocr/RealDocumentOcrTest.java
?? src/test/java/com/orientation/orientationapp/recengine/GradeNormalizerTest.java
?? src/test/java/com/orientation/orientationapp/recengine/ScoringContractTest.java
?? src/test/java/com/orientation/orientationapp/recengine/eligibility/
?? src/test/java/com/orientation/orientationapp/security/
?? src/test/resources/application-f1-test.yml
```
