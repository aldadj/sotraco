<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('buses', function (Blueprint $table) {
            $table->id();
            $table->string('numero')->unique();         // ex: "BUS-014"
            $table->string('immatriculation')->unique(); // plaque
            $table->unsignedInteger('capacite')->default(60);
            $table->foreignId('ligne_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('chauffeur_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('statut', ['actif', 'inactif', 'maintenance'])->default('actif');

            // Suivi en direct
            $table->boolean('en_marche')->default(false); // le chauffeur a activé le partage
            $table->decimal('derniere_latitude', 10, 7)->nullable();
            $table->decimal('derniere_longitude', 10, 7)->nullable();
            $table->decimal('dernier_cap', 6, 2)->nullable();   // heading/direction en degrés
            $table->decimal('derniere_vitesse', 6, 2)->nullable(); // km/h
            $table->timestamp('derniere_position_a')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('buses');
    }
};
