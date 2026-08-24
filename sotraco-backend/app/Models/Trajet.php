<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Trajet extends Model
{
    use HasFactory;

    protected $fillable = [
        'bus_id',
        'ligne_id',
        'chauffeur_id',
        'sens',
        'debut_a',
        'fin_a',
        'statut',
    ];

    protected $casts = [
        'debut_a' => 'datetime',
        'fin_a' => 'datetime',
    ];

    /**
     * Bus utilisé pour ce trajet.
     */
    public function bus()
    {
        return $this->belongsTo(Bus::class);
    }

    /**
     * Ligne parcourue.
     */
    public function ligne()
    {
        return $this->belongsTo(Ligne::class);
    }

    /**
     * Chauffeur du trajet.
     */
    public function chauffeur()
    {
        return $this->belongsTo(User::class, 'chauffeur_id');
    }

    /**
     * Vérifie si le trajet est actuellement actif.
     */
    public function estEnCours(): bool
    {
        return $this->statut === 'en_cours';
    }

    /**
     * Retourne le départ réel selon le sens.
     */
    public function getDepartReelAttribute(): ?string
    {
        if (! $this->ligne) {
            return null;
        }

        return $this->sens === 'aller'
            ? $this->ligne->depart
            : $this->ligne->destination;
    }

    /**
     * Retourne la destination réelle selon le sens.
     */
    public function getDestinationReelleAttribute(): ?string
    {
        if (! $this->ligne) {
            return null;
        }

        return $this->sens === 'aller'
            ? $this->ligne->destination
            : $this->ligne->depart;
    }
}