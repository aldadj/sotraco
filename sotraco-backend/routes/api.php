<?php

use App\Http\Controllers\Api\ArretController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BusController;
use App\Http\Controllers\Api\LigneController;
use App\Http\Controllers\Api\PositionController;
use App\Http\Controllers\Api\TrajetController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Routes publiques
|--------------------------------------------------------------------------
*/

// Inscription
Route::post('/register', [AuthController::class, 'register']);

// Connexion
Route::post('/login', [AuthController::class, 'login']);


/*
|--------------------------------------------------------------------------
| Routes protégées
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Authentification
    |--------------------------------------------------------------------------
    */

    // Déconnexion
    Route::post('/logout', [AuthController::class, 'logout']);

    // Utilisateur connecté
    Route::get('/me', [AuthController::class, 'me']);


    /*
    |--------------------------------------------------------------------------
    | Consultation générale
    |--------------------------------------------------------------------------
    |
    | Accessible aux utilisateurs authentifiés :
    | - passagers
    | - chauffeurs
    | - administrateurs
    |
    */

    /*
    |--------------------------------------------------------------------------
    | Lignes
    |--------------------------------------------------------------------------
    */

    Route::get(
        '/lignes',
        [LigneController::class, 'index']
    );

    Route::get(
        '/lignes/{ligne}',
        [LigneController::class, 'show']
    );


    /*
    |--------------------------------------------------------------------------
    | Arrêts
    |--------------------------------------------------------------------------
    */

    Route::get(
        '/arrets',
        [ArretController::class, 'index']
    );


    /*
    |--------------------------------------------------------------------------
    | Bus
    |--------------------------------------------------------------------------
    */

    Route::get(
        '/buses',
        [BusController::class, 'index']
    );

    Route::get(
        '/buses/{bus}',
        [BusController::class, 'show']
    );


    /*
    |--------------------------------------------------------------------------
    | Position actuelle d'un bus
    |--------------------------------------------------------------------------
    */

    Route::get(
        '/buses/{bus}/position',
        [PositionController::class, 'derniere']
    );


    /*
    |--------------------------------------------------------------------------
    | Historique GPS d'un bus
    |--------------------------------------------------------------------------
    */

    Route::get(
        '/buses/{bus}/historique',
        [PositionController::class, 'historique']
    );


    /*
    |--------------------------------------------------------------------------
    | ESPACE CHAUFFEUR
    |--------------------------------------------------------------------------
    |
    | Ces routes nécessitent :
    | - authentification Sanctum
    | - rôle chauffeur
    |
    */

    Route::middleware('role:chauffeur')
        ->prefix('chauffeur')
        ->group(function () {

            /*
            |--------------------------------------------------------------------------
            | Gestion du trajet
            |--------------------------------------------------------------------------
            */

            // Démarrer un trajet
            // POST /api/chauffeur/trajet/demarrer
            Route::post(
                '/trajet/demarrer',
                [TrajetController::class, 'demarrer']
            );


            // Annuler le trajet
            // POST /api/chauffeur/trajet/annuler
            Route::post(
                '/trajet/annuler',
                [TrajetController::class, 'annuler']
            );


            // Voir le trajet actif
            // GET /api/chauffeur/trajet-actif
            Route::get(
                '/trajet-actif',
                [PositionController::class, 'trajetActif']
            );


            // Terminer le trajet
            // POST /api/chauffeur/trajet/terminer
            Route::post(
                '/trajet/terminer',
                [TrajetController::class, 'terminer']
            );


            /*
            |--------------------------------------------------------------------------
            | Partage GPS
            |--------------------------------------------------------------------------
            */

            // Envoyer une position GPS
            // POST /api/chauffeur/position
            Route::post(
                '/position',
                [PositionController::class, 'envoyerPosition']
            );


            // Arrêter temporairement le partage GPS
            // POST /api/chauffeur/arreter-partage
            Route::post(
                '/arreter-partage',
                [PositionController::class, 'arreterPartage']
            );
        });


    /*
    |--------------------------------------------------------------------------
    | ESPACE ADMINISTRATEUR
    |--------------------------------------------------------------------------
    |
    | Ces routes nécessitent :
    | - authentification Sanctum
    | - rôle admin
    |
    */

    Route::middleware('role:admin')->group(function () {

        /*
        |--------------------------------------------------------------------------
        | Gestion des lignes
        |--------------------------------------------------------------------------
        */

        // Créer une ligne
        // POST /api/lignes
        Route::post(
            '/lignes',
            [LigneController::class, 'store']
        );


        // Modifier une ligne
        // PUT /api/lignes/{ligne}
        Route::put(
            '/lignes/{ligne}',
            [LigneController::class, 'update']
        );


        // Supprimer une ligne
        // DELETE /api/lignes/{ligne}
        Route::delete(
            '/lignes/{ligne}',
            [LigneController::class, 'destroy']
        );


        /*
        |--------------------------------------------------------------------------
        | Gestion des arrêts
        |--------------------------------------------------------------------------
        */

        // Créer un arrêt
        // POST /api/arrets
        Route::post(
            '/arrets',
            [ArretController::class, 'store']
        );


        // Modifier un arrêt
        // PUT /api/arrets/{arret}
        Route::put(
            '/arrets/{arret}',
            [ArretController::class, 'update']
        );


        // Supprimer un arrêt
        // DELETE /api/arrets/{arret}
        Route::delete(
            '/arrets/{arret}',
            [ArretController::class, 'destroy']
        );


        /*
        |--------------------------------------------------------------------------
        | Gestion des bus
        |--------------------------------------------------------------------------
        */

        // Créer un bus
        // POST /api/buses
        Route::post(
            '/buses',
            [BusController::class, 'store']
        );


        // Modifier un bus
        // PUT /api/buses/{bus}
        Route::put(
            '/buses/{bus}',
            [BusController::class, 'update']
        );


        // Supprimer un bus
        // DELETE /api/buses/{bus}
        Route::delete(
            '/buses/{bus}',
            [BusController::class, 'destroy']
        );
    });
});