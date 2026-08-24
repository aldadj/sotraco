<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bus extends Model
{
    use HasFactory;

    /**
     * Les champs pouvant être remplis en masse.
     */
    protected $fillable = [
        'numero',
        'immatriculation',
        'capacite',
        'ligne_id',
        'statut',

        // État du partage GPS
        'en_marche',
        'debut_partage_a',

        // Dernière position connue
        'derniere_latitude',
        'derniere_longitude',
        'dernier_cap',
        'derniere_vitesse',
        'derniere_position_a',
    ];

    /**
     * Conversion automatique des types.
     */
    protected $casts = [
        'capacite' => 'integer',

        'en_marche' => 'boolean',

        'derniere_latitude' => 'float',
        'derniere_longitude' => 'float',
        'dernier_cap' => 'float',
        'derniere_vitesse' => 'float',

        'derniere_position_a' => 'datetime',
        'debut_partage_a' => 'datetime',
    ];

    /*
    |--------------------------------------------------------------------------
    | RELATIONS
    |--------------------------------------------------------------------------
    */

    /**
     * Ligne actuellement associée au bus.
     */
    public function ligne()
    {
        return $this->belongsTo(Ligne::class);
    }

    /**
     * Toutes les positions GPS enregistrées pour ce bus.
     */
    public function positions()
    {
        return $this->hasMany(Position::class);
    }

    /**
     * Tous les trajets effectués par ce bus.
     */
    public function trajets()
    {
        return $this->hasMany(Trajet::class);
    }

    /**
     * Trajet actuellement en cours.
     */
    public function trajetActif()
    {
        return $this->hasOne(Trajet::class)
            ->where('statut', 'en_cours')
            ->latestOfMany();
    }

    /**
     * Chauffeur actuellement affecté au bus.
     *
     * Le chauffeur est déterminé à partir du trajet actif.
     */
    public function chauffeurActuel()
    {
        return $this->hasOneThrough(
            User::class,
            Trajet::class,
            'bus_id',
            'id',
            'id',
            'chauffeur_id'
        )->where('trajets.statut', 'en_cours');
    }

    /*
    |--------------------------------------------------------------------------
    | ACCESSEURS
    |--------------------------------------------------------------------------
    */

    /**
     * Retourne le sens actuel du bus.
     *
     * Exemple :
     * - aller
     * - retour
     */
    public function getSensActuelAttribute()
    {
        return $this->trajetActif?->sens;
    }

    /**
     * Retourne le chauffeur actuel.
     */
    public function getChauffeurActuelAttribute()
    {
        return $this->trajetActif?->chauffeur;
    }

    /*
    |--------------------------------------------------------------------------
    | MÉTHODES MÉTIER
    |--------------------------------------------------------------------------
    */

    /**
     * Détermine si le bus est actuellement suivi en direct.
     *
     * Un bus est considéré comme en direct si :
     *
     * 1. le partage GPS est actif ;
     * 2. une position existe ;
     * 3. cette position date de moins de 2 minutes.
     */
    public function estEnDirect(): bool
    {
        if (! $this->en_marche) {
            return false;
        }

        if (! $this->derniere_position_a) {
            return false;
        }

        return $this->derniere_position_a->diffInSeconds(now()) < 120;
    }
}