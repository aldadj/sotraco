<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lignes', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();      // ex: "L1", "L12"
            $table->string('nom');                  // ex: "Ouaga 2000 - Zone du Bois"
            $table->string('couleur')->default('#1E824C'); // couleur pour affichage carte
            $table->text('description')->nullable();
            $table->boolean('actif')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lignes');
    }
};
