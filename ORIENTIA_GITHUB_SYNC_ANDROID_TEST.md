# Orientia — synchronisation GitHub et préparation Android

Mission exécutée les 7–8 novembre 2026. Aucun accès à la base de production, aucune migration Render, aucun déploiement ni création de service d'hébergement.

## 1. État Git initial

| Dépôt | Branche locale | HEAD initial | Référence distante après fetch | Retard |
|---|---|---|---|---|
| Mobile | master | `87b1d149b8b4e963b5e8ea743da04974cddbe26d` | `1597b449dcfedc09520c199a0b7914552d534f52` | 1 commit |
| Backend | main | `ef0134d215961997da2f409eaedfd04d1880b0a7` | `f7d4efe9ad1cd39a045d3669b10a19332617bd35` | 4 commits |

Les deux arbres contenaient déjà les travaux locaux des sprints, sans conflit initial. Les états et empreintes ont été conservés dans le dossier temporaire local `orientia-sync-audit` : 192 fichiers mobiles et 726 fichiers backend de référence. Aucun fichier de ces ensembles n'a disparu. Les 84 fichiers de migration présents au début de la mission conservent leurs empreintes. Aucun reset, clean, force-push ni réécriture d'historique.

## 2. Branches et remotes

- Mobile : `https://github.com/fbici/Orientation-mobile.git`, branche `master`.
- Backend : `https://github.com/fbici/Orientation-backend.git`, branche locale créée `validation/orientia-f1-f33-20261107`. La branche locale `main` n'a pas été déplacée.
- Fetch effectué dans les deux dépôts ; corrections distantes intégrées par fusion, sans supprimer leur ascendance.
- Mobile : ancien écran de connexion remplacé par l'écran F3.3 ; l'intention du correctif distant de vérification d'email est conservée dans `ApiFailure`, avec un test.
- Backend : l'inscription transactionnelle F1 est conservée ; les champs optionnels de localisation du DTO distant sont repris. Ils ne rétablissent pas une association non validée lors de l'inscription. La réponse d'authentification expose uniquement le marqueur connu `EMAIL_NOT_VERIFIED`, jamais un message d'exception arbitraire. Les permissions F1 restent en place.

## 3. Sécurité

Gitleaks officiel 8.30.1, archive vérifiée avec la somme publiée. Scans de l'historique accessible (`--all`) des deux dépôts et des contenus courants, avec occultation complète des valeurs. Historique : zéro alerte automatique dans chaque dépôt. **Cela ne constitue pas une preuve d'absence de secret : la revue manuelle a trouvé des valeurs historiques backend.**

- `src/main/resources/application.yml` dans l'historique contient une ancienne valeur JWT par défaut.
- `H.java`, `HashGen.java` et la migration historique `V38__seed_roles_permissions.sql` contiennent un ancien mot de passe d'amorçage. Aucune valeur n'est reproduite ici.
- Le code courant avait déjà retiré les valeurs de H/HashGen et le fallback JWT. `.env.example` a été neutralisé et documenté durant cette mission.
- Les anciennes migrations ne sont pas réécrites : leurs checksums et l'historique restent conservés. Confirmer la non-utilisation ou la rotation des anciens identifiants est indispensable avant publication backend.
- Contenu Git mobile final : zéro alerte. Contenu backend préparé : deux alertes dans `SPRINT_F3_2_PREUVES.json`, lignes 271 et 315, vérifiées comme des empreintes SHA-256 de fichiers de migration V68 et V37 ; faux positifs conservés sans désactiver le scanner.
- Rapports bruts du scanner conservés uniquement dans le dossier temporaire ; aucune clé, donnée personnelle réelle, clé de signature ou configuration privée ajoutée à Git.

**Tout push backend est suspendu**, y compris la branche de validation : les valeurs restent accessibles dans son ascendance. Aucune réécriture d'historique n'est autorisée par cette mission.

## 4. Vérifications exécutées

| Vérification | Résultat |
|---|---|
| `flutter pub get` | Réussi |
| `flutter analyze`, après fusion mobile | Aucune anomalie |
| `flutter test --reporter expanded`, après fusion mobile | 32 tests réussis |
| Maven, avant fusion backend | 178 tests standard réussis sur PostgreSQL privé |
| Maven, après fusion backend | 181 tests, 30 suites, zéro échec, erreur ou test ignoré |
| Angular ChromeHeadless | 42 tests réussis ; avertissements de fermeture du navigateur après réussite |
| Angular `build:prod` | Réussi |
| Docker | Contrôle statique seulement : CLI Docker indisponible |
| GitHub Actions backend modifié | Préparé, non exécuté sur GitHub puisque backend non poussé |
| Téléphone physique | Non exécuté : aucun appareil Android détecté |

Les tests Maven utilisent exclusivement `127.0.0.1:59745/orientia_f1`, PostgreSQL privé 18.4, avec schémas distincts `sync_regression_20261107` et `sync_final_20261108`. Les identifiants restent dans l'environnement du processus. Aucun test n'utilise la connexion Render. Les anciens rapports F3.3 gardent leurs résultats historiques ; ils ne sont pas présentés comme de nouveaux tests.

## 5. Commits créés

| Dépôt | SHA | Objet |
|---|---|---|
| Mobile | `78c161b3a9dec610e3f981780ddaa563cbf2ee69` | Intégration F3.3, tests, identité visuelle et préparation Android |
| Mobile | `3bbf8d79788d118fe64b45413d07c24c4f7d4215` | Fusion de la correction distante de connexion |
| Backend local | `162fbd3dfd3c2d410d78ede290fb5b8e38740d91` | Fondations F1–F3.2 et préparation Render |
| Backend local | `5139cfe054f14f6e82c1a2c57fcc55b45f28ace6` | Fusion des quatre corrections distantes en conservant la sécurité F1 |
| Backend local | `90ff0601a04ad6b3e4dcd78ebad41012a84ec9e8` | Trois tests de confidentialité et de vérification d'email après fusion |

Les commits complémentaires de validation sont indiqués plus bas. Le SHA du commit contenant ce rapport est consultable avec `git log -1 -- ORIENTIA_GITHUB_SYNC_ANDROID_TEST.md` ; un fichier ne peut pas contenir son propre SHA Git final.

## 6. Publications effectives

Mobile `origin/master` poussé sans force : `1597b44` → `3bbf8d7`. La commande `git ls-remote origin refs/heads/master` a renvoyé exactement `3bbf8d79788d118fe64b45413d07c24c4f7d4215`, identique au HEAD local. Le rapport fait l'objet d'un commit documentaire complémentaire.

**Backend : aucun push**, ni vers main ni vers une branche de validation. Les commits sont sauvegardés localement. Les quatre commits distants restent intégrés dans leur ascendance.

## 7. Backend Render

Service existant identifié dans la configuration backend et l'environnement Angular de production : **`https://orientation-backend-4lcp.onrender.com`**.

Le profil backend `prod` expose le contexte `/`, contrairement au contexte local `/api/v1`. La commande téléphone doit donc employer l'URL ci-dessus **sans suffixe `/api/v1`**.

Tentative de lecture publique de `/api-docs` : expiration après 60 secondes, HTTP 000, zéro octet. Ce résultat ne prouve ni l'arrêt du service ni sa version. Aucun endpoint métier, aucune requête SQL de production exécutés. Version effectivement déployée, version PostgreSQL, branche Render, auto-déploiement et prévisualisations : non confirmés. Le dépôt ne contient pas de configuration de service suffisante et aucun accès d'administration Render n'était disponible.

Le Dockerfile préparé conserve Java 21 et ajoute Node 22, Tesseract français/anglais, curl et un utilisateur sans privilèges UID/GID 10001. Le profil prod exige les variables JDBC explicites, conserve Flyway et la validation Hibernate, utilise le port fourni par Render. Le compose contrôle `/actuator/health` à la racine. Aucun conteneur n'a été construit ici.

Le workflow backend prépare tests Angular et Maven avec PostgreSQL 16 éphémère, puis un artefact ; il ne contient aucune étape de déploiement. **Cela ne désactive pas le mécanisme externe de Render.** [Documentation des déploiements Render](https://render.com/docs/deploys), [prévisualisations](https://render.com/docs/preview-environments).

Node 22 remplace Node 20 arrivé en fin de support et correspond à la version Angular du projet. [Versions Node](https://nodejs.org/en/about/eol), [compatibilité Angular](https://angular.dev/reference/versions).

Stockage documentaire persistant, permissions du disque pour UID 10001, variables JWT/SMTP, tenant d'inscription, CORS et ressources OCR doivent être confirmés sur le service existant. Aucun fournisseur ni disque créé. Le mobile seul ne met pas à jour Render : les fonctions des nouveaux sprints pourront rester indisponibles avec l'ancien backend.

## 8. Risques de migration

La réussite sur un schéma vierge PostgreSQL 18.4 ne valide pas une base Render déjà peuplée, éventuellement créée par Hibernate sans historique Flyway.

- V63.1 est intercalée avant V64 : si V64 est déjà enregistrée, définir une stratégie contrôlée ; ne pas activer automatiquement `outOfOrder`, `baseline` ou `repair`.
- V65 nécessite pgcrypto et change les sessions : révocation/reconnexion à prévoir.
- V66 rapproche les propriétaires par email : associations ambiguës, doublons et éléments sans propriétaire exigent une revue.
- V67–V76 : contraintes, objets éventuellement existants et périmètres des catalogues nécessitent comparaison du schéma et répétition sur copie.
- V74 utilise `UNIQUE NULLS NOT DISTINCT`, donc PostgreSQL 15 minimum. La version Render reste inconnue. [Syntaxe PostgreSQL 15](https://www.postgresql.org/docs/15/sql-createtable.htm).
- V77–V82 : nouveaux champs, clés étrangères, historique de recommandations et confirmations nécessitent répétition sur données existantes.
- `ddl-auto=validate`, Flyway activé, baseline automatique désactivé : sécurité contre une adoption implicite, mais possibilité d'échec au démarrage si le schéma diffère.

Préparer sauvegarde vérifiée, restauration isolée, contrôles de structure et agrégats, simulation de toutes les migrations puis plan de retour base/fichiers. Documents backend : `docs/RENDER_VALIDATION_F1_F33.md` et `docs/render-preflight-readonly.sql`. Le SQL est préparé, **jamais exécuté**, et ne contient pas de migration.

## 9. Fichiers exclus et préservation

Indexation par manifestes explicites, sans `git add .`. Exclusion des `.env` privés, clés de signature, fichiers locaux SDK, caches, sorties build, logs, documents uploadés et rapports bruts de secrets.

Sept chemins IDE mobile et 25 fichiers `.angular` auparavant suivis sont retirés de l'index. Les fichiers existants sur disque sont conservés ; le fichier `orientation_mobile.iml` était déjà absent avant la mission. Les assets de marque et sources générées de registre de plugins nécessaires au projet restent suivis. Aucun APK, keystore ou document candidat réel publié. Les CSV de référence du catalogue déjà suivis sont conservés.

## 10. État Android

Flutter et ADB disponibles ; `flutter devices --machine` ne présente aucun Android physique. `adb devices -l` renvoie une liste vide. Windows, Chrome et Edge ne sont pas des téléphones Android. L'aide `tool/android_phone_command.dart` retourne le code attendu 2 en l'absence de téléphone, sans installer ni démarrer l'application.

Connecter un câble USB de données, activer les options développeur et le débogage USB, déverrouiller le téléphone et accepter l'empreinte RSA. Vérifier ensuite `adb devices -l` et `flutter devices`.

Identifiant courant, déjà présent dans les travaux locaux avant cette mission : `com.orientia.orientia`. Le précédent code distant utilisait `com.example.orientation_mobile`. Le package et la signature réellement installés sont inconnus en l'absence du téléphone. Ne pas modifier ces paramètres ni désinstaller une application pour forcer l'installation ; vérifier la compatibilité si une version existe déjà.

## 11. URL API

`https://orientation-backend-4lcp.onrender.com`

`AppConstants` lit réellement `API_BASE_URL` et `APP_ENV` via `String.fromEnvironment`; HTTPS et le contexte racine sont compatibles avec le client. Les anciennes constructions APK des sprints, faites avec des URL de test, ne constituent pas une application configurée pour Render : utiliser la commande ci-dessous.

## 12. Commande téléphone

Dans le terminal VS Code, à la racine du dépôt mobile, après connexion USB :

```powershell
dart run tool/android_phone_command.dart
```

Cette aide détecte un téléphone Android physique autorisé et affiche la commande exacte avec son identifiant. Elle ne lance pas Flutter. En cas de plusieurs téléphones : `dart run tool/android_phone_command.dart --device ID`.

La commande affichée suit exactement cette forme ; **`ID_DETECTE` est un emplacement à remplacer, pas un appareil détecté pendant cette mission** :

```powershell
flutter run -d "ID_DETECTE" --dart-define=APP_ENV=development --dart-define=API_BASE_URL=https://orientation-backend-4lcp.onrender.com
```

Aucun identifiant inventé, aucune commande exécutée sur un téléphone absent.

## 13. Opérations en attente

Avant tout push backend : confirmer la rotation ou la non-utilisation des anciennes valeurs historiques et définir le traitement de leur exposition publique. Une éventuelle réécriture d'historique exige une autorisation distincte ; aucune n'a été faite.

Avant toute branche susceptible de déploiement ou tout changement de branche Render : confirmer dans Render la branche suivie, le mode auto-déploiement, les prévisualisations et la version PostgreSQL ; vérifier les variables privées sans les publier. L'état inconnu suffit à interdire le push sur main selon la mission.

Avant toute migration/déploiement : approuver une procédure concrète après restauration isolée et validation du schéma peuplé, sauvegarde, stockage/OCR/messagerie et plan de retour. Aucun accès à la base de production n'est présumé autorisé.

La recette visuelle Android attend uniquement la connexion et l'autorisation USB du téléphone. La recette fonctionnelle complète attend en plus un backend des nouveaux sprints déployé après ces validations.

## Complément de validation

Suite backend standard après fusion : 181 tests dans 30 suites, zéro échec, erreur ou test ignoré. Les trois nouveaux tests vérifient le marqueur public de vérification d'email et la confidentialité des autres messages. Le rapport ancien `MobileFlutterJourneyIT` est exclu de ce décompte : le parcours HTTP Flutter réel n'a pas été relancé dans cette mission.

Le cluster PostgreSQL privé a été arrêté proprement après validation ; ses données sont conservées. Les deux arbres Git sont propres après leurs commits respectifs, hors fichiers locaux ignorés. Aucune branche backend n'a été publiée et aucune opération Render n'a été déclenchée.
