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

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/me', [AuthController::class, 'me']);


    /*
    |--------------------------------------------------------------------------
    | Consultation
    |--------------------------------------------------------------------------
    |
    | Accessible aux passagers, chauffeurs et administrateurs.
    |
    */

    // Lignes
    Route::get('/lignes', [LigneController::class, 'index']);
    Route::get('/lignes/{ligne}', [LigneController::class, 'show']);

    // Arrêts
    Route::get('/arrets', [ArretController::class, 'index']);

    // Bus
    Route::get('/buses', [BusController::class, 'index']);
    Route::get('/buses/{bus}', [BusController::class, 'show']);

    // Position actuelle d'un bus
    Route::get(
        '/buses/{bus}/position',
        [PositionController::class, 'derniere']
    );

    // Historique GPS d'un bus
    Route::get(
        '/buses/{bus}/historique',
        [PositionController::class, 'historique']
    );


    /*
    |--------------------------------------------------------------------------
    | Espace chauffeur
    |--------------------------------------------------------------------------
    |
    | Toutes ces routes nécessitent :
    | - une authentification Sanctum
    | - le rôle chauffeur
    |
    */

    Route::middleware('role:chauffeur')
        ->prefix('chauffeur')
        ->group(function () {

            /*
            |------------------------------------------------------------------
            | Gestion du trajet
            |------------------------------------------------------------------
            */

            // Démarrer un trajet
            Route::post(
                '/trajet/demarrer',
                [TrajetController::class, 'demarrer']
            );

            // Voir le trajet actuellement en cours
            Route::get(
                '/trajet-actif',
                [PositionController::class, 'trajetActif']
            );

            // Terminer le trajet
            Route::post(
                '/trajet/terminer',
                [TrajetController::class, 'terminer']
            );


            /*
            |------------------------------------------------------------------
            | Partage GPS
            |------------------------------------------------------------------
            */

            // Envoyer une nouvelle position GPS
            Route::post(
                '/position',
                [PositionController::class, 'envoyerPosition']
            );

            // Arrêter temporairement le partage GPS
            Route::post(
                '/arreter-partage',
                [PositionController::class, 'arreterPartage']
            );
        });


    /*
    |--------------------------------------------------------------------------
    | Espace administrateur
    |--------------------------------------------------------------------------
    |
    | Toutes ces routes nécessitent :
    | - une authentification Sanctum
    | - le rôle admin
    |
    */

    Route::middleware('role:admin')->group(function () {

        /*
        |--------------------------------------------------------------------------
        | Chauffeurs
        |--------------------------------------------------------------------------
        */

        Route::get('/chauffeurs', function () {

            return \App\Models\User::where('role', 'chauffeur')
                ->select(
                    'id',
                    'name',
                    'telephone'
                )
                ->get();
        });

            Route::post('/chauffeurs', [AuthController::class, 'createChauffeur']);


        /*
        |--------------------------------------------------------------------------
        | Lignes
        |--------------------------------------------------------------------------
        */

        Route::post(
            '/lignes',
            [LigneController::class, 'store']
        );

        Route::put(
            '/lignes/{ligne}',
            [LigneController::class, 'update']
        );

        Route::delete(
            '/lignes/{ligne}',
            [LigneController::class, 'destroy']
        );


        /*
        |--------------------------------------------------------------------------
        | Arrêts
        |--------------------------------------------------------------------------
        */

        Route::post(
            '/arrets',
            [ArretController::class, 'store']
        );

        Route::put(
            '/arrets/{arret}',
            [ArretController::class, 'update']
        );

        Route::delete(
            '/arrets/{arret}',
            [ArretController::class, 'destroy']
        );


        /*
        |--------------------------------------------------------------------------
        | Bus
        |--------------------------------------------------------------------------
        */

        Route::post(
            '/buses',
            [BusController::class, 'store']
        );

        Route::put(
            '/buses/{bus}',
            [BusController::class, 'update']
        );

        Route::delete(
            '/buses/{bus}',
            [BusController::class, 'destroy']
        );
    });
});