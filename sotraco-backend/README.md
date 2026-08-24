# SOTRACO Backend (Laravel API)

Backend API REST + temps réel pour l'application de gestion et de suivi des bus SOTRACO.

## Installation

Ce dossier contient uniquement le **code applicatif** (app/, database/, routes/, config)
à fusionner dans un projet Laravel fraîchement créé, car l'environnement qui a généré
ce code n'a pas accès à Packagist :

```bash
composer create-project laravel/laravel sotraco-backend
cd sotraco-backend

# copier le contenu de ce dossier par-dessus (fusionner les dossiers) :
#   app/Models, app/Http/Controllers/Api, app/Http/Middleware, app/Events
#   database/migrations, database/seeders
#   routes/api.php, routes/channels.php

composer require laravel/sanctum laravel/reverb
php artisan install:api        # si pas déjà fait (publie Sanctum)
php artisan reverb:install
```

### Middleware "role"

Dans `bootstrap/app.php` (Laravel 11+) :

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'role' => \App\Http\Middleware\CheckRole::class,
    ]);
})
```

### Variables .env

```
DB_CONNECTION=mysql
DB_DATABASE=sotraco
...

BROADCAST_CONNECTION=reverb
REVERB_APP_ID=sotraco
REVERB_APP_KEY=<générée par reverb:install>
REVERB_APP_SECRET=<générée par reverb:install>
REVERB_HOST="0.0.0.0"
REVERB_PORT=8080
REVERB_SCHEME=http
```

### Migrations + données de démo

```bash
php artisan migrate
php artisan db:seed --class=Database\\Seeders\\SotracoSeeder
```

### Lancer

```bash
php artisan serve            # API sur http://127.0.0.1:8000
php artisan reverb:start     # serveur websocket sur le port 8080
```

## Déploiement Render de l'application Flutter Web

Le backend Laravel et l'application Flutter sont deux services distincts sur Render :

- `https://sotraco-backend-3htu.onrender.com` expose l'API Laravel ;
- `https://sotraco-app.onrender.com` expose l'interface Flutter Web.

Le fichier `render.yaml` situé à la racine du dépôt configure les deux services. Dans Render,
crée un Blueprint depuis le dépôt contenant `sotraco-backend/` et `sotraco_app/`, puis déploie
le Blueprint. Flutter est compilé automatiquement avec l'URL publique de l'API.

La racine du backend redirige vers l'application Flutter grâce à `FRONTEND_URL`.
## Comptes de démo (mot de passe : `password`)

| Rôle       | Email                        |
|------------|-------------------------------|
| Admin      | admin@sotraco.bf              |
| Chauffeur  | issa.chauffeur@sotraco.bf      |
| Chauffeur  | awa.chauffeur@sotraco.bf       |
| Passager   | passager@sotraco.bf            |

## Principe du suivi en direct

1. Le **chauffeur** clique sur "Partager ma position" dans l'app Flutter.
2. L'app envoie `POST /api/chauffeur/position` toutes les ~5 secondes (via `geolocator`).
3. Le backend enregistre la position, met à jour le bus, et diffuse l'événement
   `BusPositionUpdated` sur le canal websocket `bus.{id}` (Reverb, compatible Pusher).
4. Tout **passager** abonné à ce canal (car il a ouvert la carte de ce bus) reçoit
   la nouvelle position instantanément et déplace le marqueur sur `google_maps_flutter`
   — exactement comme le partage de position en direct de Google Maps.
5. Si le chauffeur ferme l'app sans arrêter le partage, `estEnDirect()` bascule
   automatiquement à `false` après 2 minutes sans nouvelle position (évite les bus fantômes).

## Endpoints principaux

- `POST /api/register`, `POST /api/login` — auth (Sanctum, token Bearer)
- `GET /api/lignes`, `GET /api/lignes/{id}`
- `GET /api/buses?ligne_id=&en_marche=1`
- `GET /api/buses/{id}/position` — dernière position (fallback sans websocket)
- `GET /api/buses/{id}/historique` — trace GPS des dernières heures
- `POST /api/chauffeur/position` — chauffeur uniquement
- `POST /api/chauffeur/arreter-partage` — chauffeur uniquement
- CRUD admin : `/api/lignes`, `/api/arrets`, `/api/buses` (POST/PUT/DELETE)
