<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ligne_arret', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ligne_id')->constrained()->cascadeOnDelete();
            $table->foreignId('arret_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('ordre')->default(0); // ordre de passage sur la ligne
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ligne_arret');
    }
};
