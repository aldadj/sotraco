<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use App\Models\Ligne;
use App\Models\Trajet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TrajetController extends Controller
{
    /**
     * Démarrer un nouveau trajet.
     *
     * Le chauffeur choisit :
     * - un bus
     * - une ligne
     * - un sens
     *
     * POST /api/chauffeur/trajet
     */
    public function demarrer(Request $request)
    {
        $chauffeur = $request->user();

        if (! $chauffeur || ! $chauffeur->isChauffeur()) {
            return response()->json([
                'message' => 'Seul un chauffeur peut démarrer un trajet.'
            ], 403);
        }

        /*
        |--------------------------------------------------------------------------
        | Validation
        |--------------------------------------------------------------------------
        */

        $data = $request->validate([
            'bus_id' => [
                'required',
                'exists:buses,id',
            ],

            'ligne_id' => [
                'required',
                'exists:lignes,id',
            ],

            'sens' => [
                'required',
                'in:aller,retour',
            ],
        ]);

        /*
        |--------------------------------------------------------------------------
        | 1. Vérifier le trajet actif du chauffeur
        |--------------------------------------------------------------------------
        */

        $trajetChauffeur = Trajet::where(
            'chauffeur_id',
            $chauffeur->id
        )
            ->where('statut', 'en_cours')
            ->first();

        if ($trajetChauffeur) {
            return response()->json([
                'message' => 'Vous avez déjà un trajet en cours.'
            ], 422);
        }

        /*
        |--------------------------------------------------------------------------
        | 2. Vérifier que le bus n'est pas déjà utilisé
        |--------------------------------------------------------------------------
        */

        $trajetBus = Trajet::where(
            'bus_id',
            $data['bus_id']
        )
            ->where('statut', 'en_cours')
            ->first();

        if ($trajetBus) {
            return response()->json([
                'message' => 'Ce bus est déjà en circulation.'
            ], 422);
        }

        /*
        |--------------------------------------------------------------------------
        | 3. Vérifier la ligne
        |--------------------------------------------------------------------------
        */

        $ligne = Ligne::findOrFail(
            $data['ligne_id']
        );

        if (! $ligne->actif) {
            return response()->json([
                'message' => 'Cette ligne est actuellement inactive.'
            ], 422);
        }

        /*
        |--------------------------------------------------------------------------
        | 4. Récupérer le bus
        |--------------------------------------------------------------------------
        */

        $bus = Bus::findOrFail(
            $data['bus_id']
        );

        /*
        |--------------------------------------------------------------------------
        | 5. Vérifier le statut du bus
        |--------------------------------------------------------------------------
        */

        if ($bus->statut !== 'actif') {
            return response()->json([
                'message' => 'Ce bus est actuellement inactif.'
            ], 422);
        }

        /*
        |--------------------------------------------------------------------------
        | 6. Créer le trajet
        |--------------------------------------------------------------------------
        */

        $trajet = DB::transaction(
            function () use (
                $chauffeur,
                $bus,
                $ligne,
                $data
            ) {

                $trajet = Trajet::create([
                    'bus_id' => $bus->id,

                    'ligne_id' => $ligne->id,

                    'chauffeur_id' => $chauffeur->id,

                    'sens' => $data['sens'],

                    'debut_a' => now(),

                    'statut' => 'en_cours',
                ]);

                /*
                 * Le bus connaît maintenant sa ligne actuelle.
                 *
                 * Le GPS n'est pas encore actif.
                 */
                $bus->update([
                    'ligne_id' => $ligne->id,

                    'en_marche' => false,

                    'debut_partage_a' => null,
                ]);

                return $trajet;
            }
        );

        /*
        |--------------------------------------------------------------------------
        | 7. Réponse
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'message' => 'Trajet démarré avec succès.',

            'trajet' => $trajet->load([
                'bus',
                'ligne',
                'chauffeur',
            ]),
        ], 201);
    }

    /**
     * Terminer le trajet.
     *
     * POST /api/chauffeur/trajet/terminer
     */
    public function terminer(Request $request)
    {
        $chauffeur = $request->user();

        if (! $chauffeur || ! $chauffeur->isChauffeur()) {
            return response()->json([
                'message' => 'Accès refusé.'
            ], 403);
        }

        /*
        |--------------------------------------------------------------------------
        | Récupérer le trajet actif
        |--------------------------------------------------------------------------
        */

        $trajet = Trajet::where(
            'chauffeur_id',
            $chauffeur->id
        )
            ->where('statut', 'en_cours')
            ->with([
                'bus',
                'ligne',
            ])
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' => 'Aucun trajet en cours.'
            ], 404);
        }

        /*
        |--------------------------------------------------------------------------
        | Terminer
        |--------------------------------------------------------------------------
        */

        DB::transaction(function () use ($trajet) {

            $trajet->update([
                'statut' => 'termine',

                'fin_a' => now(),
            ]);

            if ($trajet->bus) {
                $trajet->bus->update([
                    'en_marche' => false,

                    'debut_partage_a' => null,
                ]);
            }
        });

        return response()->json([
            'message' => 'Trajet terminé avec succès.',

            'trajet' => $trajet
                ->fresh()
                ->load([
                    'bus',
                    'ligne',
                    'chauffeur',
                ]),
        ]);
    }
}