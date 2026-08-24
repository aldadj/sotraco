<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ligne extends Model
{
    use HasFactory;

    protected $fillable = ['code', 'nom', 'depart', 'destination', 'couleur', 'description', 'actif'];

    protected $casts = [
        'actif' => 'boolean',
    ];

    public function arrets()
    {
        return $this->belongsToMany(Arret::class, 'ligne_arret')
            ->withPivot('ordre')
            ->orderBy('ligne_arret.ordre');
    }

    public function buses()
    {
        return $this->hasMany(Bus::class);
    }
}
