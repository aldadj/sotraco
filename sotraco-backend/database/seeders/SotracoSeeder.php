<?php

namespace Database\Seeders;

use App\Models\Arret;
use App\Models\Bus;
use App\Models\Ligne;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class SotracoSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | ADMIN
        |--------------------------------------------------------------------------
        */

        User::create([
            'name' => 'Administrateur SOTRACO',
            'email' => 'admin@sotraco.bf',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        /*
        |--------------------------------------------------------------------------
        | CHAUFFEURS
        |--------------------------------------------------------------------------
        |
        | IMPORTANT :
        | Aucun chauffeur n'est affecté directement à un bus.
        |
        | Un chauffeur pourra conduire :
        | - BUS-001 aujourd'hui
        | - BUS-003 demain
        | - BUS-016 après-demain
        |
        | L'affectation se fait au démarrage d'un trajet.
        |
        */

        User::create([
            'name' => 'Issa Ouédraogo',
            'email' => 'issa.chauffeur@sotraco.bf',
            'telephone' => '+226 70 00 00 01',
            'password' => Hash::make('password'),
            'role' => 'chauffeur',
        ]);

        User::create([
            'name' => 'Awa Kaboré',
            'email' => 'awa.chauffeur@sotraco.bf',
            'telephone' => '+226 70 00 00 02',
            'password' => Hash::make('password'),
            'role' => 'chauffeur',
        ]);

        /*
        |--------------------------------------------------------------------------
        | PASSAGER DE TEST
        |--------------------------------------------------------------------------
        */

        User::create([
            'name' => 'Passager Test',
            'email' => 'passager@sotraco.bf',
            'password' => Hash::make('password'),
            'role' => 'passager',
        ]);

        /*
        |--------------------------------------------------------------------------
        | ARRÊTS
        |--------------------------------------------------------------------------
        */

        $gareCentre = Arret::create([
            'nom' => 'Gare Routière Centre',
            'latitude' => 12.3714,
            'longitude' => -1.5197,
            'quartier' => 'Centre-ville',
        ]);

        $ouaga2000 = Arret::create([
            'nom' => 'Rond-Point Ouaga 2000',
            'latitude' => 12.3260,
            'longitude' => -1.4880,
            'quartier' => 'Ouaga 2000',
        ]);

        $zoneBois = Arret::create([
            'nom' => 'Zone du Bois',
            'latitude' => 12.3660,
            'longitude' => -1.5000,
            'quartier' => 'Zone du Bois',
        ]);

        $dassasgho = Arret::create([
            'nom' => 'Dassasgho Carrefour',
            'latitude' => 12.3830,
            'longitude' => -1.4950,
            'quartier' => 'Dassasgho',
        ]);

        $patteOie = Arret::create([
            'nom' => "Patte d'Oie",
            'latitude' => 12.3550,
            'longitude' => -1.4700,
            'quartier' => "Patte d'Oie",
        ]);

        /*
        |--------------------------------------------------------------------------
        | LIGNE 1
        |--------------------------------------------------------------------------
        */

        $ligne1 = Ligne::create([
            'code' => 'L1',
            'nom' => 'Centre-ville - Ouaga 2000',
            'depart' => 'Gare Routière Centre',
            'destination' => 'Ouaga 2000',
            'couleur' => '#1E824C',
            'description' => 'Dessert le centre-ville jusqu\'à Ouaga 2000 via Zone du Bois.',
            'actif' => true,
        ]);

        $ligne1->arrets()->attach([
            $gareCentre->id => [
                'ordre' => 1,
            ],

            $zoneBois->id => [
                'ordre' => 2,
            ],

            $ouaga2000->id => [
                'ordre' => 3,
            ],
        ]);

        /*
        |--------------------------------------------------------------------------
        | LIGNE 2
        |--------------------------------------------------------------------------
        */

        $ligne2 = Ligne::create([
            'code' => 'L2',
            'nom' => 'Dassasgho - Patte d\'Oie',
            'depart' => 'Dassasgho',
            'destination' => "Patte d'Oie",
            'couleur' => '#F2A104',
            'description' => 'Liaison Est-Ouest passant par le centre-ville.',
            'actif' => true,
        ]);

        $ligne2->arrets()->attach([
            $dassasgho->id => [
                'ordre' => 1,
            ],

            $gareCentre->id => [
                'ordre' => 2,
            ],

            $patteOie->id => [
                'ordre' => 3,
            ],
        ]);

        /*
        |--------------------------------------------------------------------------
        | BUS
        |--------------------------------------------------------------------------
        |
        | Aucun chauffeur ici.
        |
        | Le même bus peut être utilisé par plusieurs chauffeurs
        | à différents moments.
        |
        */

        Bus::create([
            'numero' => 'BUS-001',
            'immatriculation' => '11-BF-2201',
            'capacite' => 60,
            'ligne_id' => null,
            'statut' => 'actif',
            'en_marche' => false,
        ]);

        Bus::create([
            'numero' => 'BUS-002',
            'immatriculation' => '11-BF-2202',
            'capacite' => 60,
            'ligne_id' => null,
            'statut' => 'actif',
            'en_marche' => false,
        ]);

        Bus::create([
            'numero' => 'BUS-003',
            'immatriculation' => '11-BF-2203',
            'capacite' => 45,
            'ligne_id' => null,
            'statut' => 'inactif',
            'en_marche' => false,
        ]);
    }
}