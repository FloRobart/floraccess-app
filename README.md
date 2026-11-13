# FlorAccess App

FlorAccess app est un panel d'administration pour l'API d'authentification [FlorAccess](https://github.com/FloRobart/floraccess-api).

Elle permet de :

- Gérer les utilisateurs
- Faire des campagnes d'emailing
- Renvoyer des emails de vérification d'adresse email
- Savoir qui est connecté
- Déconnecter un utilisateur
- Modifier un utilisateur (Email, pseudo)
- Supprimer un utilisateur

Les mentions légales et la politique de confidentialité de FlorAccess sont sur la page `/legal`, ouverte depuis le bouton « Mentions légales » de la page de profil, et lisible sans être connecté. Leur contenu est dans `lib/features/legal/legal_notice_content.dart` : le mettre à jour quand l'éditeur, l'hébergeur, le service d'envoi des emails, les données conservées par l'API ou leur durée de conservation changent.

# Table des matières

- [Configuration](#configuration)
- [Développement](#développement)
- [Production](#production)
- [CI et versions](#ci-et-versions)
- [License](#license)

# Configuration

L'application lit sa configuration au démarrage dans le fichier `.env`, servi à l'adresse `/assets/.env` : changer une URL ne demande pas de recompiler le code Dart.

| Variable | Rôle |
|---|---|
| `APP_NAME` | Nom de l'application |
| `DATA_URL` | URL de l'API FlorAccess |

⚠️ **Ce fichier est servi à tous les visiteurs.** Ne jamais y mettre de secret.

En production, le navigateur ne peut appeler que les adresses listées dans le `connect-src` de `nginx.conf` (`https://api.floraccess.florobart.fr`). Une nouvelle adresse de l'API doit donc aussi y être ajoutée, puis publiée avec une nouvelle image. En local, `http://localhost` est toujours autorisé. La police Manrope est embarquée dans l'application (`assets/fonts/`) : aucune police n'est téléchargée chez Google.

# Développement

La version de Flutter est fixée dans `pubspec.yaml` (`environment.flutter`) : la CI et le `Dockerfile` utilisent exactement celle-ci.

1. Copier le fichier d'environnement :

    ```bash
    cp .env.example .env
    ```

2. Lancer l'application dans Chrome :

    ```bash
    flutter run -d chrome --web-port 26007
    ```

    Ou construire la version web, puis la servir avec la configuration nginx de production (en-têtes de sécurité compris) sur `http://localhost:26007` :

    ```bash
    flutter build web --release --no-web-resources-cdn
    ```

    ```bash
    docker compose -f docker-compose.dev.yml up
    ```

L'API FlorAccess doit tourner en local (voir le README de `floraccess-api`), avec `http://localhost:26007` dans son `CORS_ALLOWED_ORIGINS`.

Vérifications lancées par la CI, à lancer en local avant une pull request :

```bash
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test
```

# Production

En production, [floraccess-wrapper](https://github.com/FloRobart/floraccess-wrapper) déploie le panel avec le reste de l'écosystème. Voir son README.

Cette section décrit comment lancer ce dépôt seul. `docker-compose.yml` est réservé à la production. Le conteneur ne publie aucun port : il n'est joignable que par le reverse proxy (Traefik), qui doit rejoindre le réseau `floraccess-app-net` et router le domaine de l'application vers `http://floraccess-app:8080`.

1. Copier `docker-compose.yml` et créer le `.env` à partir de `.env.example`, avec l'URL publique de l'API dans `DATA_URL`. nginx le lit avec un utilisateur non-root :

    ```bash
    chmod 644 .env
    ```

2. Récupérer l'image, puis démarrer. La dernière release est prise par défaut ; pour une autre version, la définir dans `APP_VERSION` :

    ```bash
    docker compose pull
    ```

    ```bash
    docker compose up -d
    ```

Le conteneur tourne en lecture seule, sans capacité Linux, avec un utilisateur non-root et des ressources limitées. L'image ne contient ni shell ni client HTTP : c'est le reverse proxy qui vérifie qu'elle répond.

# CI et versions

La CI vient de [FloRobart/github-ci](https://github.com/FloRobart/github-ci) (`.github/workflows/ci.yml`) :

- **Pull request** : règles du git flow, messages de commit au format [Conventional Commits](https://www.conventionalcommits.org/fr/), `dart format`, `flutter analyze`, `flutter test`, build Android et build de l'image Docker.
- **Bouton Run workflow sur `dev`** : release candidate `vX.Y.Z-rc.N`.
- **Merge sur `main`** : version finale `vX.Y.Z`, image `florobart/floraccess-app:X.Y.Z` et `latest` sur Docker Hub et GHCR, et APK attaché à la GitHub Release.

La version est calculée à partir des messages de commit : ne pas modifier la `version` du `pubspec.yaml` à la main.

Dependabot (`.github/dependabot.yml`) propose chaque mois, vers `dev`, les mises à jour des paquets Dart et des images de base du `Dockerfile`.

# License

FlorAccess est un projet open-source sous licence [GNU General Public License v3.0](https://opensource.org/licenses/GPL-3.0).
