<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Canaux de diffusion temps réel
|--------------------------------------------------------------------------
| Ces canaux sont publics (au sens "n'importe quel utilisateur connecté
| peut suivre un bus") : un passager doit pouvoir suivre n'importe quel
| bus en circulation, pas seulement "ses propres" bus.
| On garde tout de même l'authentification pour éviter les abus.
*/

Broadcast::channel('bus.{busId}', function ($user, $busId) {
    return $user !== null; // tout utilisateur connecté peut suivre un bus
});

Broadcast::channel('lignes.{ligneId}', function ($user, $ligneId) {
    return $user !== null;
});
