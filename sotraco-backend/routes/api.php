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
| ROUTES PUBLIQUES
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);

Route::post('/login', [AuthController::class, 'login']);


/*
|--------------------------------------------------------------------------
| ROUTES PROTÉGÉES
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | AUTHENTIFICATION
    |--------------------------------------------------------------------------
    */

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/me', [AuthController::class, 'me']);


    /*
    |--------------------------------------------------------------------------
    | CONSULTATION
    |--------------------------------------------------------------------------
    |
    | Accessible aux passagers, chauffeurs et administrateurs.
    |
    */

    // ----------------------------------------------------------------------
    // LIGNES
    // ----------------------------------------------------------------------

    Route::get('/lignes', [
        LigneController::class,
        'index'
    ]);

    Route::get('/lignes/{ligne}', [
        LigneController::class,
        'show'
    ]);


    // ----------------------------------------------------------------------
    // ARRÊTS
    // ----------------------------------------------------------------------

    Route::get('/arrets', [
        ArretController::class,
        'index'
    ]);


    // ----------------------------------------------------------------------
    // BUS
    // ----------------------------------------------------------------------

    Route::get('/buses', [
        BusController::class,
        'index'
    ]);

    Route::get('/buses/{bus}', [
        BusController::class,
        'show'
    ]);


    // ----------------------------------------------------------------------
    // POSITION ACTUELLE
    // ----------------------------------------------------------------------

    Route::get('/buses/{bus}/position', [
        PositionController::class,
        'derniere'
    ]);


    // ----------------------------------------------------------------------
    // HISTORIQUE GPS
    // ----------------------------------------------------------------------

    Route::get('/buses/{bus}/historique', [
        PositionController::class,
        'historique'
    ]);


    /*
    |--------------------------------------------------------------------------
    | ESPACE CHAUFFEUR
    |--------------------------------------------------------------------------
    |
    | Toutes ces routes nécessitent :
    | - authentification Sanctum
    | - rôle chauffeur
    |
    */

    Route::middleware('role:chauffeur')
        ->prefix('chauffeur')
        ->group(function () {

            // ==============================================================
            // TRAJET
            // ==============================================================

            /*
             * Démarrer un trajet
             *
             * POST /api/chauffeur/trajet/demarrer
             */
            Route::post('/trajet/demarrer', [
                TrajetController::class,
                'demarrer'
            ]);


            /*
             * Annuler un trajet
             *
             * POST /api/chauffeur/trajet/annuler
             */
            Route::post('/trajet/annuler', [
                TrajetController::class,
                'annuler'
            ]);


            /*
             * Trajet actuellement actif
             *
             * GET /api/chauffeur/trajet-actif
             */
            Route::get('/trajet-actif', [
                PositionController::class,
                'trajetActif'
            ]);


            /*
             * Terminer un trajet
             *
             * POST /api/chauffeur/trajet/terminer
             */
            Route::post('/trajet/terminer', [
                TrajetController::class,
                'terminer'
            ]);


            // ==============================================================
            // GPS
            // ==============================================================

            /*
             * Envoyer une position GPS
             *
             * POST /api/chauffeur/position
             */
            Route::post('/position', [
                PositionController::class,
                'envoyerPosition'
            ]);


            /*
             * Arrêter temporairement le partage GPS
             *
             * POST /api/chauffeur/arreter-partage
             */
            Route::post('/arreter-partage', [
                PositionController::class,
                'arreterPartage'
            ]);
        });


    /*
    |--------------------------------------------------------------------------
    | ESPACE ADMINISTRATEUR
    |--------------------------------------------------------------------------
    |
    | Toutes ces routes nécessitent :
    | - authentification Sanctum
    | - rôle admin
    |
    */

    Route::middleware('role:admin')->group(function () {

        // ==============================================================
        // LIGNES
        // ==============================================================

        Route::post('/lignes', [
            LigneController::class,
            'store'
        ]);

        Route::put('/lignes/{ligne}', [
            LigneController::class,
            'update'
        ]);

        Route::delete('/lignes/{ligne}', [
            LigneController::class,
            'destroy'
        ]);


        // ==============================================================
        // ARRÊTS
        // ==============================================================

        Route::post('/arrets', [
            ArretController::class,
            'store'
        ]);

        Route::put('/arrets/{arret}', [
            ArretController::class,
            'update'
        ]);

        Route::delete('/arrets/{arret}', [
            ArretController::class,
            'destroy'
        ]);


        // ==============================================================
        // BUS
        // ==============================================================

        Route::post('/buses', [
            BusController::class,
            'store'
        ]);

        Route::put('/buses/{bus}', [
            BusController::class,
            'update'
        ]);

        Route::delete('/buses/{bus}', [
            BusController::class,
            'destroy'
        ]);
    });
});