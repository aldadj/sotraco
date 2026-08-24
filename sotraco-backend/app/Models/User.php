<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'telephone',
        'password',
        'role', // admin | chauffeur | passager
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isChauffeur(): bool
    {
        return $this->role === 'chauffeur';
    }


    public function trajetActif()
    {
        return $this->hasOne(Trajet::class, 'chauffeur_id')
            ->where('statut', 'en_cours')
            ->latestOfMany();
    }
    
    public function trajets()
    {
        return $this->hasMany(Trajet::class, 'chauffeur_id');
    }
}
