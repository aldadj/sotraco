<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Arret extends Model
{
    use HasFactory;

    protected $fillable = ['nom', 'latitude', 'longitude', 'quartier'];

    public function lignes()
    {
        return $this->belongsToMany(Ligne::class, 'ligne_arret')->withPivot('ordre');
    }
}
