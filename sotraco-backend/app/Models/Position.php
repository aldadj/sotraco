<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Position extends Model
{
    protected $fillable = ['bus_id', 'latitude', 'longitude', 'cap', 'vitesse', 'capture_a'];

    protected $casts = [
        'capture_a' => 'datetime',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function bus()
    {
        return $this->belongsTo(Bus::class);
    }
}
