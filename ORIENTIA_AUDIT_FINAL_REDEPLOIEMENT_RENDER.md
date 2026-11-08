# Orientia — audit final et préparation du nouveau déploiement Render

Date : 8 novembre 2026. Ce rapport remplace les instructions opérationnelles de la mission précédente : le propriétaire confirme que l'ancien backend Render a été retiré et l'ancienne base est inaccessible. Aucun accès, création ou modification de ressource Render ou de base de production pendant cette mission. Aucun email réel envoyé.

## Audit des dépôts

| Projet | Dossier local | Branche au début | HEAD au début | État initial |
|---|---|---|---|---|
| Backend et Angular | `C:\Users\HP\Documents\projets\orientation-backend` | `validation/orientia-f1-f33-20261107` | `90ff0601a04ad6b3e4dcd78ebad41012a84ec9e8` | Propre ; contient les corrections distantes et trois commits locaux non publiés |
| Flutter | `C:\Users\HP\Documents\projets\Orientation-mobile` | `master` | `b9885f976b049543359f3309232b4b95e856419a` | Propre, synchronisé |

Remotes vérifiés et fetch effectué :

- Backend : `https://github.com/fbici/Orientation-backend.git`, `origin/main` initial `f7d4efe9ad1cd39a045d3669b10a19332617bd35` ; aucune divergence avec la branche de validation.
- Mobile : `https://github.com/fbici/Orientation-mobile.git`, `origin/master` identique au HEAD initial.

Backend structuré en modules Spring Boot, sécurité JWT, moteurs métier et pipeline documentaire ; backoffice Angular sous `frontend/` ; Flutter sous `lib/`, tests sous `test/`. Les fonctions des sprints sont conservées. Les changements de cette mission portent sur la sécurité de l'initialisation, les liens/configurations du nouveau service et les vérifications SendGrid. Indexation explicite des seuls fichiers revus, sans `git add .`, reset, clean ou force-push.

## Backend et corrections

- Compilation et packaging Java 21 via Maven `verify`, JAR exécutable embarquant le build Angular.
- Profil `prod` : PostgreSQL JDBC explicite, Flyway activé, `baseline-on-migrate=false`, `clean-disabled=true`, Hibernate `validate`, aucune initialisation SQL/H2 locale.
- Retrait du compte administrateur public seed de V38 et du fallback JWT historique restant dans le compose. Les rôles, permissions et le tenant `DEFAULT` restent créés. Le premier administrateur passe par l'amorçage explicite `BOOTSTRAP_*`.
- **V38 a un nouveau checksum : cette livraison cible exclusivement une nouvelle base vierge.** Ne pas lancer sur une base ayant déjà appliqué l'ancienne V38 ; aucun `repair` ou baseline automatique.
- URL supprimée retirée des configurations actives. `APP_BASE_URL` et `CORS_ALLOWED_ORIGINS` sont explicites en production ; WebSocket Angular utilise `/ws` sur la même origine.
- Correction d'un blocage constaté lors du premier essai prod : les GET des pages de connexion et récupération entraient en conflit avec les routes POST et répondaient en erreur. Des routes GET servent désormais Angular, sans modifier les POST d'authentification.
- Assets Angular reconstruits par Docker/CI, exclus de Git et du contexte Docker local. Aucun JAR, cache, clé ou document utilisateur ajouté au commit.

## Flyway et démarrage sur base vierge

Audit des **83 migrations SQL**, versions V1 à V82, dont V63.1 avant V64 : versions uniques et ordre vérifié. V1 crée notamment `uuid-ossp` et `pgcrypto`. V74 exige PostgreSQL 15 minimum.

Deux contrôles indépendants ont été effectués sur le cluster PostgreSQL privé `127.0.0.1:59745`, jamais sur Render :

1. Suite métier sur un nouveau schéma isolé, avec Flyway et validation Hibernate.
2. JAR final démarré avec `prod` depuis un nouveau dossier sans `.env`, environnement minimal, stockage temporaire et une **nouvelle base vide** du cluster privé.

Résultat du second contrôle : santé `UP`, 83 migrations réussies, zéro migration échouée, zéro utilisateur seed ; `/`, `/auth/login` et `/auth/reset-password` répondent en **200 HTML**. Le processus applicatif a été arrêté après les contrôles. Le cluster privé est arrêté proprement, ses données sont conservées.

La version locale est PostgreSQL 18.4. Flyway émet un avertissement indiquant que sa plage de support testée s'arrête à 17. **PostgreSQL 16 est recommandé pour Render**, correspondant également au service déclaré par la CI. La réussite locale sur 18.4 n'est pas présentée comme une certification de support de 18 ni comme un test effectué sur 16. La CI distante n'est pas confirmée par cette mission.

## SendGrid et sécurité

L'intégration existante conserve `https://api.sendgrid.com/v3/mail/send` et l'authentification Bearer. Les variables `SENDGRID_API_KEY`, `SENDGRID_ENABLED`, `SENDGRID_FROM_EMAIL` sont validées par un test chargeant le vrai YAML `prod`. `APP_BASE_URL` est nécessaire aux liens ; `PASSWORD_RESET_URL` est maintenant raccordée explicitement à la configuration, avec repli sur `APP_BASE_URL/auth/reset-password`.

Fonctions réellement raccordées : inscription et demande de vérification, renvoi conditionnel pour un compte non vérifié, récupération du mot de passe. La vérification consomme ensuite le jeton sans nouvel envoi. Une méthode d'email de bienvenue existe sans appel actif identifié. Les notifications du backoffice sont internes/WebSocket ; aucun envoi SendGrid de notification n'a été trouvé.

Tests HTTP entièrement simulés : acceptation 202, requête et liens, configuration désactivée/incomplète, réponses 400/401/429/500, erreur réseau, interruption et confidentialité des journaux. Aucun appel SendGrid réel. Les erreurs journalisent uniquement le statut HTTP ou une catégorie générique ; aucun destinataire, contenu, jeton, Authorization, clé ou corps d'erreur fournisseur n'est journalisé. Une acceptation HTTP ne prouve pas une livraison en boîte mail.

Gitleaks 8.30.1, valeurs occultées : scan des fichiers publiables et de l'historique accessible des deux dépôts. Mobile : zéro alerte. Backend : deux alertes dans `SPRINT_F3_2_PREUVES.json`, lignes 271 et 315, vérifiées comme SHA-256 des migrations V68 et V37 ; aucune clé API dans ces alertes. Une vérification complémentaire compare sans affichage les anciennes valeurs JWT/seed avec tous les fichiers courants : **aucune occurrence restante**.

**L'historique Git conserve les anciennes valeurs JWT/seed déjà exposées.** Les scans automatiques n'avaient pas détecté ces valeurs ; leur présence historique est connue et signalée. Un push normal ne les efface pas, et aucune réécriture ni force-push n'a été fait. Le nouveau service utilisera uniquement de nouvelles clés JWT/SendGrid et les identifiants d'une nouvelle base, conformément à la consigne du propriétaire. Les anciennes valeurs ne doivent jamais être réutilisées. Les rapports bruts du scanner restent temporaires et ne sont pas publiés.

## Tests exécutés

| Vérification | Résultat final |
|---|---|
| Maven `verify`, Java 21, PostgreSQL privé et OCR réel local | **195 tests, 32 suites**, zéro échec, erreur ou test ignoré ; JAR construit |
| Angular ChromeHeadless | **42 tests réussis** |
| Angular `npm --prefix frontend run build:prod` | Réussi, intégré au JAR de validation |
| Flutter `flutter analyze` | Aucune anomalie |
| Flutter `flutter test --reporter expanded` | **32 tests réussis** |
| Aide Android `--help`, puis sans URL | Aide correcte ; refuse de proposer une URL supprimée ou inventée |
| Profil prod sur nouvelle base privée | 83 migrations, Hibernate validé, santé UP, pages Angular 200 |
| `git diff --check` et contenu indexé | Propres |
| Image Docker | Revue statique uniquement : CLI Docker indisponible |

Les dépendances Angular étaient déjà installées et utilisables ; aucune réinstallation inutile. Le parcours HTTP Flutter réel `MobileFlutterJourneyIT` n'a pas été relancé et son ancien XML est exclu des 195 tests. Aucun test visuel sur téléphone ni test de délivrabilité SendGrid réelle n'est annoncé.

## Commits et pushes

| Dépôt / branche | Nouveau commit | Publication vérifiée |
|---|---|---|
| Backend `main` | `019c9b1fd9f2ef4a060a5fda968a411b0d8275fa` — `fix: secure fresh Render deployment and verify SendGrid delivery handling` | `git push origin main` réussi ; SHA distant identique via `git ls-remote` |
| Mobile `master` | `25344447e714b23e3ecbb851fffd33c074ebdcd1` — `fix: require the new backend URL for Android phone testing` | `git push origin master` réussi ; SHA distant identique via `git ls-remote` |

Le backend local `main` a avancé uniquement par fast-forward depuis la branche de validation, sans conflit ni écrasement. Les trois commits préparés lors de la mission précédente sont également publiés dans son ascendance : `162fbd3d`, `5139cfe0`, `90ff0601`. Le présent rapport fait l'objet d'un commit documentaire mobile complémentaire ; son SHA est consultable avec `git log -1 -- ORIENTIA_AUDIT_FINAL_REDEPLOIEMENT_RENDER.md`.

## Configuration du futur service Render

Guide complet versionné dans le backend : [nouveau déploiement Render](https://github.com/fbici/Orientation-backend/blob/main/docs/RENDER_NOUVEAU_DEPLOIEMENT.md).

| Champ | Valeur / action |
|---|---|
| Type | Web Service Docker ; disque persistant pour les documents |
| Dépôt / branche | `fbici/Orientation-backend`, `main` |
| Root directory | Racine du dépôt, champ vide |
| Dockerfile / contexte | `./Dockerfile` / `.` |
| Build Command Render | Aucun champ de commande native ; Render construit le Dockerfile |
| Équivalent de build local | `docker build -t orientia .` — non exécuté ici |
| Docker Command | Laisser vide pour conserver l'ENTRYPOINT |
| Démarrage effectif, dans `/app` | `java -Djava.awt.headless=true -jar app.jar --spring.profiles.active=prod` |
| Java / profil | Java 21 / `prod` |
| Santé / port | `/actuator/health` ; `PORT` fourni par Render, adresse `0.0.0.0` |
| PostgreSQL recommandé | 16, nouvelle base vide, même région que le service |
| TLS JDBC | `sslmode=require`, utilisateur et mot de passe séparés de l'URL |
| Stockage | `STORAGE_DIR=/app/uploads`, disque monté et accessible à UID/GID 10001 |
| OCR | Tesseract et langues `fra+eng` installés dans l'image |

Variables à renseigner hors Git : `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, **nouveau** `JWT_SECRET`, `APP_BASE_URL`, `CORS_ALLOWED_ORIGINS`, `SENDGRID_ENABLED=true`, **nouvelle** `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL` vérifié. Variables complémentaires : `PASSWORD_RESET_URL` facultative, `REGISTRATION_TENANT_CODE=DEFAULT`, `STORAGE_DIR`, `TESSERACT_COMMAND`, `OCR_LANGUAGES`, `TESSDATA_DIR` facultative et `OCR_TIMEOUT_SECONDS`.

Amorçage administrateur ponctuel : `BOOTSTRAP_ENABLED=true`, `BOOTSTRAP_EMAIL`, nouveau `BOOTSTRAP_PASSWORD` robuste, `BOOTSTRAP_TENANT_CODE=DEFAULT`. Après création réussie, remettre `BOOTSTRAP_ENABLED=false` et retirer le mot de passe de l'environnement. Le bootstrap refuse de remplacer un compte administrateur existant ; ne pas le laisser actif aux démarrages suivants.

Flyway démarre automatiquement sur la nouvelle base vide, avant la validation Hibernate. Ne pas utiliser `baseline`, `repair`, `clean` ou `outOfOrder`. Observer les journaux, les droits de création des extensions et la santé du service. Ne pas réutiliser l'ancienne base ni ses secrets.

Références officielles : [Docker Render](https://render.com/docs/docker), [PostgreSQL et TLS](https://render.com/docs/postgresql-creating-connecting), [disques persistants](https://render.com/docs/disks), [identité d'expéditeur SendGrid](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/sender-identity).

## Après publication de la véritable URL

Aucune nouvelle URL Render n'est connue ou inventée. À la racine du mobile :

```powershell
$env:ORIENTIA_API_URL = Read-Host 'URL HTTPS réelle du nouveau backend Render'
dart run tool/android_phone_command.dart --api-url $env:ORIENTIA_API_URL
```

L'aide affiche une commande `flutter run` avec l'identifiant du téléphone détecté, `APP_ENV=development` et `API_BASE_URL` égal à l'URL saisie. Le contexte prod est `/`, **sans `/api/v1`**. L'aide ne lance pas d'installation. Identifiant `com.orientia.orientia` et signature conservés. Aucun ancien APK configuré avec une URL de test ne remplace cette configuration.

## Points restant à réaliser

Créer et configurer manuellement le nouveau service et sa base après choix du plan ; renseigner les nouveaux secrets, l'URL, le disque et les sauvegardes. Vérifier les permissions du disque et des extensions, le build Docker réel, le statut CI distant, le démarrage Render et la recette mobile. La délivrabilité SendGrid exige un expéditeur/domaine vérifié et une autorisation distincte pour envoyer un email réel. Aucun de ces contrôles distants non exécutés n'est présenté comme réussi.
