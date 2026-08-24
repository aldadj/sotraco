<?php

namespace App\Http\Controllers\Api;

use App\Events\BusPositionUpdated;
use App\Http\Controllers\Controller;
use App\Models\Bus;
use App\Models\Position;
use App\Models\Trajet;
use Illuminate\Http\Request;

class PositionController extends Controller
{
    /**
     * Le chauffeur partage sa position GPS.
     *
     * POST /api/chauffeur/position
     *
     * Body :
     * {
     *     "latitude": 12.37,
     *     "longitude": -1.52,
     *     "cap": 90,
     *     "vitesse": 35
     * }
     */
    public function envoyerPosition(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' => 'Seul un chauffeur peut partager une position.'
            ], 403);
        }

        /*
        |--------------------------------------------------------------------------
        | Récupérer le trajet actif du chauffeur
        |--------------------------------------------------------------------------
        */

        $trajet = Trajet::where('chauffeur_id', $user->id)
            ->where('statut', 'en_cours')
            ->with([
                'bus',
                'ligne',
                'chauffeur',
            ])
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' => 'Aucun trajet actif. Démarrez un trajet avant de partager votre position.'
            ], 422);
        }

        $bus = $trajet->bus;

        if (! $bus) {
            return response()->json([
                'message' => 'Aucun bus associé à ce trajet.'
            ], 422);
        }

        /*
        |--------------------------------------------------------------------------
        | Validation GPS
        |--------------------------------------------------------------------------
        */

        $data = $request->validate([
            'latitude' => [
                'required',
                'numeric',
                'between:-90,90',
            ],

            'longitude' => [
                'required',
                'numeric',
                'between:-180,180',
            ],

            'cap' => [
                'nullable',
                'numeric',
                'between:0,360',
            ],

            'vitesse' => [
                'nullable',
                'numeric',
                'min:0',
            ],
        ]);

        $maintenant = now();

        /*
        |--------------------------------------------------------------------------
        | Enregistrer la position dans l'historique
        |--------------------------------------------------------------------------
        */

        Position::create([
            'bus_id' => $bus->id,
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'cap' => $data['cap'] ?? null,
            'vitesse' => $data['vitesse'] ?? null,
            'capture_a' => $maintenant,
        ]);

        /*
        |--------------------------------------------------------------------------
        | Mettre à jour la position actuelle du bus
        |--------------------------------------------------------------------------
        */

        $bus->update([
            'en_marche' => true,

            'derniere_latitude' => $data['latitude'],
            'derniere_longitude' => $data['longitude'],

            'dernier_cap' => $data['cap'] ?? $bus->dernier_cap,
            'derniere_vitesse' => $data['vitesse'] ?? $bus->derniere_vitesse,

            'derniere_position_a' => $maintenant,

            /*
             * Si le partage n'avait pas encore commencé,
             * on mémorise l'heure actuelle.
             */
            'debut_partage_a' => $bus->debut_partage_a ?? $maintenant,
        ]);

        /*
        |--------------------------------------------------------------------------
        | Diffusion temps réel
        |--------------------------------------------------------------------------
        */

        $busActualise = $bus->fresh([
            'ligne',
            'trajetActif.chauffeur',
            'trajetActif.ligne',
        ]);

        broadcast(
            new BusPositionUpdated($busActualise)
        );

        /*
        |--------------------------------------------------------------------------
        | Réponse
        |--------------------------------------------------------------------------
        */

        return response()->json([
            'message' => 'Position mise à jour.',

            'bus' => $busActualise,
        ]);
    }

    /**
     * Arrêter temporairement le partage GPS.
     *
     * POST /api/chauffeur/arreter-partage
     *
     * IMPORTANT :
     * Cela n'arrête PAS le trajet.
     */
    public function arreterPartage(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' => 'Accès refusé.'
            ], 403);
        }

        /*
        |--------------------------------------------------------------------------
        | Récupérer le trajet actif
        |--------------------------------------------------------------------------
        */

        $trajet = Trajet::where('chauffeur_id', $user->id)
            ->where('statut', 'en_cours')
            ->with('bus')
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' => 'Aucun trajet actif.'
            ], 404);
        }

        $bus = $trajet->bus;

        if (! $bus) {
            return response()->json([
                'message' => 'Aucun bus associé à ce trajet.'
            ], 404);
        }

        /*
        |--------------------------------------------------------------------------
        | Arrêter uniquement le GPS
        |--------------------------------------------------------------------------
        */

        $bus->update([
            'en_marche' => false,
        ]);

        /*
        |--------------------------------------------------------------------------
        | Notification temps réel
        |--------------------------------------------------------------------------
        */

        broadcast(
            new BusPositionUpdated(
                $bus->fresh([
                    'ligne',
                    'trajetActif.chauffeur',
                    'trajetActif.ligne',
                ])
            )
        );

        return response()->json([
            'message' => 'Partage de position arrêté.',
        ]);
    }

    /**
     * Terminer complètement le trajet.
     *
     * POST /api/chauffeur/terminer-trajet
     */
    public function terminerTrajet(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' => 'Seul un chauffeur peut terminer un trajet.'
            ], 403);
        }

        /*
        |--------------------------------------------------------------------------
        | Récupérer le trajet actif
        |--------------------------------------------------------------------------
        */

        $trajet = Trajet::where('chauffeur_id', $user->id)
            ->where('statut', 'en_cours')
            ->with('bus')
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' => 'Aucun trajet en cours.'
            ], 404);
        }

        /*
        |--------------------------------------------------------------------------
        | Terminer le trajet
        |--------------------------------------------------------------------------
        */

        $trajet->update([
            'statut' => 'termine',
            'fin_a' => now(),
        ]);

        /*
        |--------------------------------------------------------------------------
        | Arrêter le partage GPS
        |--------------------------------------------------------------------------
        */

        if ($trajet->bus) {
            $trajet->bus->update([
                'en_marche' => false,
                'debut_partage_a' => null,
            ]);

            broadcast(
                new BusPositionUpdated(
                    $trajet->bus->fresh([
                        'ligne',
                        'trajetActif.chauffeur',
                        'trajetActif.ligne',
                    ])
                )
            );
        }

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

    /**
     * Récupérer le trajet actif du chauffeur.
     *
     * GET /api/chauffeur/trajet-actif
     */
    public function trajetActif(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' => 'Accès réservé aux chauffeurs.'
            ], 403);
        }

        $trajet = Trajet::where('chauffeur_id', $user->id)
            ->where('statut', 'en_cours')
            ->with([
                'bus',
                'ligne',
            ])
            ->first();

        if (! $trajet) {
            return response()->json([
                'trajet_actif' => false,
                'message' => 'Aucun trajet en cours.',
            ]);
        }

        return response()->json([
            'trajet_actif' => true,
            'trajet' => $trajet,
        ]);
    }

    /**
     * GET /api/buses/{bus}/position
     *
     * Dernière position connue du bus.
     */
    public function derniere(Bus $bus)
    {
        $trajet = $bus->trajetActif()
            ->with([
                'ligne',
                'chauffeur',
            ])
            ->first();

        return response()->json([
            'bus_id' => $bus->id,

            'numero' => $bus->numero,

            'ligne_id' => $trajet?->ligne_id,

            'sens' => $trajet?->sens,

            'latitude' => $bus->derniere_latitude,

            'longitude' => $bus->derniere_longitude,

            'cap' => $bus->dernier_cap,

            'vitesse' => $bus->derniere_vitesse,

            'en_marche' => $bus->en_marche,

            'en_direct' => $bus->estEnDirect(),

            'capture_a' => $bus->derniere_position_a,

            'debut_partage_a' => $bus->debut_partage_a,

            'chauffeur' => $trajet?->chauffeur,

            'ligne' => $trajet?->ligne,
        ]);
    }

    /**
     * GET /api/buses/{bus}/historique
     *
     * Historique GPS du bus.
     */
    public function historique(
        Bus $bus,
        Request $request
    ) {
        $depuis = $request->query('depuis');
        $trajetActif = $bus->trajetActif()->first();

        $query = $bus->positions()
            ->orderBy('capture_a');

        if ($trajetActif?->debut_a) {
            $query->where('capture_a', '>=', $trajetActif->debut_a);
        } elseif ($depuis) {
            $query->where(
                'capture_a',
                '>=',
                $depuis
            );
        } else {
            $query->where(
                'capture_a',
                '>=',
                now()->subHours(3)
            );
        }

        return response()->json(
            $query->get([
                'latitude',
                'longitude',
                'capture_a',
                'cap',
                'vitesse',
            ])
        );
    }
}