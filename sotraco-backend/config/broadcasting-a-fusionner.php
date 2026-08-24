<?php
/*
 * Ceci N'EST PAS un fichier de config à copier tel quel, c'est un mémo.
 *
 * 1) Installer Reverb (serveur websocket officiel Laravel, gratuit, auto-hébergé) :
 *      composer require laravel/reverb
 *      php artisan reverb:install
 *
 *    Reverb parle le protocole Pusher : le SDK Flutter "pusher_channels_flutter"
 *    fonctionnera donc directement avec, sans dépendre d'un service tiers payant.
 *
 * 2) Dans config/broadcasting.php, s'assurer que la connexion par défaut est "reverb".
 *
 * 3) Variables à ajouter dans .env :
 *
 *      BROADCAST_CONNECTION=reverb
 *
 *      REVERB_APP_ID=sotraco
 *      REVERB_APP_KEY=sotraco-key      (générée par reverb:install, à copier ici)
 *      REVERB_APP_SECRET=sotraco-secret
 *      REVERB_HOST="0.0.0.0"
 *      REVERB_PORT=8080
 *      REVERB_SCHEME=http               (https en production avec un reverse-proxy nginx)
 *
 * 4) Lancer le serveur websocket (à garder actif en permanence, ex: supervisor) :
 *      php artisan reverb:start
 *
 * 5) Sanctum : dans .env, définir SANCTUM_STATEFUL_DOMAINS si besoin (API mobile pure =
 *    on utilise les tokens Bearer classiques, donc pas indispensable pour Flutter).
 *
 * 6) N'oublie pas d'enregistrer le middleware "role" dans bootstrap/app.php (Laravel 11) :
 *
 *      ->withMiddleware(function (Middleware $middleware) {
 *          $middleware->alias([
 *              'role' => \App\Http\Middleware\CheckRole::class,
 *          ]);
 *      })
 */
