<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('positions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bus_id')->constrained()->cascadeOnDelete();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->decimal('cap', 6, 2)->nullable();
            $table->decimal('vitesse', 6, 2)->nullable();
            $table->timestamp('capture_a');
            $table->timestamps();

            $table->index(['bus_id', 'capture_a']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('positions');
    }
};
