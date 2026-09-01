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
     * =========================================================================
     * ENVOYER UNE POSITION GPS
     * =========================================================================
     *
     * POST /api/chauffeur/position
     *
     * Body :
     *
     * {
     *     "latitude": 12.370000,
     *     "longitude": -1.520000,
     *     "cap": 90,
     *     "vitesse": 35
     * }
     */
    public function envoyerPosition(Request $request)
    {
        // =====================================================================
        // 1. UTILISATEUR CONNECTÉ
        // =====================================================================

        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' =>
                    'Seul un chauffeur peut partager une position.',
            ], 403);
        }

        // =====================================================================
        // 2. TRAJET ACTIF DU CHAUFFEUR
        // =====================================================================

        $trajet = Trajet::where(
                'chauffeur_id',
                $user->id
            )
            ->where(
                'statut',
                'en_cours'
            )
            ->with([
                'bus',
                'ligne',
                'chauffeur',
            ])
            ->latest('id')
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' =>
                    'Aucun trajet actif. '
                    . 'Démarrez un trajet avant de partager votre position.',
            ], 422);
        }

        // =====================================================================
        // 3. BUS ASSOCIÉ
        // =====================================================================

        $bus = $trajet->bus;

        if (! $bus) {
            return response()->json([
                'message' =>
                    'Aucun bus associé à ce trajet.',
            ], 422);
        }

        // =====================================================================
        // 4. VALIDATION GPS
        // =====================================================================

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

            /*
             * Le champ est nullable.
             *
             * Côté Flutter, si heading = -1,
             * il n'est pas envoyé.
             */
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

        // =====================================================================
        // 5. ENREGISTRER DANS L'HISTORIQUE
        // =====================================================================

        Position::create([
            'bus_id' => $bus->id,

            'latitude' => $data['latitude'],

            'longitude' => $data['longitude'],

            'cap' => $data['cap'] ?? null,

            'vitesse' => $data['vitesse'] ?? null,

            'capture_a' => $maintenant,
        ]);

        // =====================================================================
        // 6. METTRE À JOUR LE BUS
        // =====================================================================

        $bus->update([
            /*
             * Le bus est maintenant réellement en mouvement /
             * partage GPS actif.
             */
            'en_marche' => true,

            'derniere_latitude' =>
                $data['latitude'],

            'derniere_longitude' =>
                $data['longitude'],

            /*
             * Si le cap n'est pas envoyé,
             * on conserve l'ancien cap.
             */
            'dernier_cap' =>
                array_key_exists('cap', $data)
                    ? $data['cap']
                    : $bus->dernier_cap,

            /*
             * Même logique pour la vitesse.
             */
            'derniere_vitesse' =>
                array_key_exists('vitesse', $data)
                    ? $data['vitesse']
                    : $bus->derniere_vitesse,

            /*
             * Heure de la dernière position.
             */
            'derniere_position_a' =>
                $maintenant,

            /*
             * Heure du début du partage.
             *
             * On ne l'écrase pas à chaque position.
             */
            'debut_partage_a' =>
                $bus->debut_partage_a
                    ?? $maintenant,
        ]);

        // =====================================================================
        // 7. RECHARGER LES RELATIONS
        // =====================================================================

        $busActualise = $bus->fresh([
            'ligne',
            'trajetActif.chauffeur',
            'trajetActif.ligne',
        ]);

        // =====================================================================
        // 8. DIFFUSION TEMPS RÉEL
        // =====================================================================

        broadcast(
            new BusPositionUpdated(
                $busActualise
            )
        );

        // =====================================================================
        // 9. RÉPONSE
        // =====================================================================

        return response()->json([
            'message' =>
                'Position mise à jour.',

            'bus' =>
                $busActualise,
        ]);
    }

    /**
     * =========================================================================
     * ARRÊTER LE PARTAGE GPS
     * =========================================================================
     *
     * POST /api/chauffeur/arreter-partage
     *
     * IMPORTANT :
     * Le trajet reste en cours.
     * Seul le partage GPS est arrêté.
     */
    public function arreterPartage(Request $request)
    {
        // =====================================================================
        // 1. CHAUFFEUR
        // =====================================================================

        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' =>
                    'Accès refusé.',
            ], 403);
        }

        // =====================================================================
        // 2. TRAJET ACTIF
        // =====================================================================

        $trajet = Trajet::where(
                'chauffeur_id',
                $user->id
            )
            ->where(
                'statut',
                'en_cours'
            )
            ->with('bus')
            ->latest('id')
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' =>
                    'Aucun trajet actif.',
            ], 404);
        }

        // =====================================================================
        // 3. BUS
        // =====================================================================

        $bus = $trajet->bus;

        if (! $bus) {
            return response()->json([
                'message' =>
                    'Aucun bus associé à ce trajet.',
            ], 404);
        }

        // =====================================================================
        // 4. ARRÊTER LE PARTAGE
        // =====================================================================

        $bus->update([
            'en_marche' => false,
        ]);

        // =====================================================================
        // 5. DIFFUSION
        // =====================================================================

        $busActualise = $bus->fresh([
            'ligne',
            'trajetActif.chauffeur',
            'trajetActif.ligne',
        ]);

        broadcast(
            new BusPositionUpdated(
                $busActualise
            )
        );

        // =====================================================================
        // 6. RÉPONSE
        // =====================================================================

        return response()->json([
            'message' =>
                'Partage de position arrêté.',

            'bus' =>
                $busActualise,
        ]);
    }

    /**
     * =========================================================================
     * TERMINER COMPLÈTEMENT LE TRAJET
     * =========================================================================
     *
     * POST /api/chauffeur/terminer-trajet
     */
    public function terminerTrajet(Request $request)
    {
        // =====================================================================
        // 1. CHAUFFEUR
        // =====================================================================

        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' =>
                    'Seul un chauffeur peut terminer un trajet.',
            ], 403);
        }

        // =====================================================================
        // 2. TRAJET ACTIF
        // =====================================================================

        $trajet = Trajet::where(
                'chauffeur_id',
                $user->id
            )
            ->where(
                'statut',
                'en_cours'
            )
            ->with('bus')
            ->latest('id')
            ->first();

        if (! $trajet) {
            return response()->json([
                'message' =>
                    'Aucun trajet en cours.',
            ], 404);
        }

        // =====================================================================
        // 3. TERMINER LE TRAJET
        // =====================================================================

        $trajet->update([
            'statut' => 'termine',
            'fin_a' => now(),
        ]);

        // =====================================================================
        // 4. ARRÊTER LE BUS
        // =====================================================================

        if ($trajet->bus) {
            $trajet->bus->update([
                'en_marche' => false,
                'debut_partage_a' => null,
            ]);

            $busActualise = $trajet->bus->fresh([
                'ligne',
                'trajetActif.chauffeur',
                'trajetActif.ligne',
            ]);

            broadcast(
                new BusPositionUpdated(
                    $busActualise
                )
            );
        }

        // =====================================================================
        // 5. RÉPONSE
        // =====================================================================

        return response()->json([
            'message' =>
                'Trajet terminé avec succès.',

            'trajet' =>
                $trajet
                    ->fresh()
                    ->load([
                        'bus',
                        'ligne',
                        'chauffeur',
                    ]),
        ]);
    }

    /**
     * =========================================================================
     * TRAJET ACTIF DU CHAUFFEUR
     * =========================================================================
     *
     * GET /api/chauffeur/trajet-actif
     */
    public function trajetActif(Request $request)
    {
        // =====================================================================
        // 1. CHAUFFEUR
        // =====================================================================

        $user = $request->user();

        if (! $user || ! $user->isChauffeur()) {
            return response()->json([
                'message' =>
                    'Accès réservé aux chauffeurs.',
            ], 403);
        }

        // =====================================================================
        // 2. TRAJET
        // =====================================================================

        $trajet = Trajet::where(
                'chauffeur_id',
                $user->id
            )
            ->where(
                'statut',
                'en_cours'
            )
            ->with([
                'bus',
                'ligne',
            ])
            ->latest('id')
            ->first();

        // =====================================================================
        // 3. AUCUN TRAJET
        // =====================================================================

        if (! $trajet) {
            return response()->json([
                'trajet_actif' => false,

                'message' =>
                    'Aucun trajet en cours.',
            ]);
        }

        // =====================================================================
        // 4. TRAJET TROUVÉ
        // =====================================================================

        return response()->json([
            'trajet_actif' => true,

            'trajet' => $trajet,
        ]);
    }

    /**
     * =========================================================================
     * DERNIÈRE POSITION D'UN BUS
     * =========================================================================
     *
     * GET /api/buses/{bus}/position
     */
    public function derniere(Bus $bus)
    {
        $trajet = $bus
            ->trajetActif()
            ->with([
                'ligne',
                'chauffeur',
            ])
            ->first();

        return response()->json([
            'bus_id' =>
                $bus->id,

            'numero' =>
                $bus->numero,

            'ligne_id' =>
                $trajet?->ligne_id,

            'sens' =>
                $trajet?->sens,

            'latitude' =>
                $bus->derniere_latitude,

            'longitude' =>
                $bus->derniere_longitude,

            'cap' =>
                $bus->dernier_cap,

            'vitesse' =>
                $bus->derniere_vitesse,

            'en_marche' =>
                $bus->en_marche,

            'en_direct' =>
                $bus->estEnDirect(),

            'capture_a' =>
                $bus->derniere_position_a,

            'debut_partage_a' =>
                $bus->debut_partage_a,

            'chauffeur' =>
                $trajet?->chauffeur,

            'ligne' =>
                $trajet?->ligne,
        ]);
    }

    /**
     * =========================================================================
     * HISTORIQUE GPS
     * =========================================================================
     *
     * GET /api/buses/{bus}/historique
     */
    public function historique(
        Bus $bus,
        Request $request
    ) {
        $depuis =
            $request->query('depuis');

        $trajetActif =
            $bus->trajetActif()->first();

        if (! $trajetActif) {
            return response()->json([]);
        }

        $query = $bus
            ->positions()
            ->orderBy('capture_a');

        // =====================================================================
        // DEPUIS LE DÉBUT DU TRAJET
        // =====================================================================

        if ($trajetActif->debut_a) {
            $query->where(
                'capture_a',
                '>=',
                $trajetActif->debut_a
            );
        }

        // =====================================================================
        // DEPUIS UNE DATE FOURNIE
        // =====================================================================

        elseif ($depuis) {
            $query->where(
                'capture_a',
                '>=',
                $depuis
            );
        }

        // =====================================================================
        // PAR DÉFAUT : 3 DERNIÈRES HEURES
        // =====================================================================

        else {
            $query->where(
                'capture_a',
                '>=',
                now()->subHours(3)
            );
        }

        // =====================================================================
        // RÉSULTAT
        // =====================================================================

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