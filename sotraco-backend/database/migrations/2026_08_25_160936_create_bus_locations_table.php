<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bus_locations', function (Blueprint $table) {
            $table->id();

            $table->foreignId('bus_id')
                ->constrained('buses')
                ->cascadeOnDelete();

            $table->foreignId('trajet_id')
                ->nullable()
                ->constrained('trajets')
                ->nullOnDelete();

            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);

            $table->decimal('speed', 8, 2)->nullable();
            $table->decimal('heading', 8, 2)->nullable();
            $table->decimal('accuracy', 8, 2)->nullable();

            $table->timestamp('recorded_at')->useCurrent();

            $table->timestamps();

            $table->index(['bus_id', 'recorded_at']);
            $table->index(['trajet_id', 'recorded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bus_locations');
    }
};