<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trajets', function (Blueprint $table) {
            $table->id();

            $table->foreignId('bus_id')
                ->constrained('buses')
                ->cascadeOnDelete();

            $table->foreignId('ligne_id')
                ->constrained('lignes')
                ->cascadeOnDelete();

            $table->foreignId('chauffeur_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Sens du trajet
            $table->enum('sens', [
                'aller',
                'retour'
            ]);

            $table->timestamp('debut_a')->nullable();

            $table->timestamp('fin_a')->nullable();

            $table->enum('statut', [
                'planifie',
                'en_cours',
                'termine',
                'annule'
            ])->default('planifie');

            $table->timestamps();

            // Recherche rapide des trajets d'un bus
            $table->index([
                'bus_id',
                'statut'
            ]);

            // Recherche rapide des trajets d'un chauffeur
            $table->index([
                'chauffeur_id',
                'statut'
            ]);

            // Recherche par ligne, sens et statut
            $table->index([
                'ligne_id',
                'sens',
                'statut'
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trajets');
    }
};