<?php

namespace App\Events;

use App\Models\Bus;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Queue\SerializesModels;

/**
 * Diffusé à chaque fois qu'un chauffeur envoie une nouvelle position GPS.
 * Les clients Flutter abonnés au canal "bus.{id}" reçoivent l'événement
 * instantanément (via Laravel Reverb / Pusher) et déplacent le marqueur
 * sur la carte, comme le "partage de position en direct" de Google Maps.
 */
class BusPositionUpdated implements ShouldBroadcastNow
{
    use InteractsWithSockets, SerializesModels;

    public function __construct(public Bus $bus)
    {
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('bus.' . $this->bus->id),
            new Channel('lignes.' . $this->bus->ligne_id), // pour rafraîchir la liste des bus d'une ligne
        ];
    }

    public function broadcastAs(): string
    {
        return 'position.maj';
    }

    public function broadcastWith(): array
    {
        return [
            'bus_id' => $this->bus->id,
            'numero' => $this->bus->numero,
            'ligne_id' => $this->bus->ligne_id,
            'sens' => $this->bus->trajetActif?->sens,
            'latitude' => $this->bus->derniere_latitude,
            'longitude' => $this->bus->derniere_longitude,
            'cap' => $this->bus->dernier_cap,
            'vitesse' => $this->bus->derniere_vitesse,
            'en_marche' => $this->bus->en_marche,
            'capture_a' => $this->bus->derniere_position_a?->toIso8601String(),
        ];
    }
}
