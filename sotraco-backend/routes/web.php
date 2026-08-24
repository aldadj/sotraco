<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    $frontendUrl = env('FRONTEND_URL');

    return $frontendUrl
        ? redirect()->away($frontendUrl)
        : response()->json(['message' => 'API SOTRACO opérationnelle.']);
});

Route::get('/login', function () {
    return response()->json(['message' => 'Non authentifié.'], 401);
})->name('login');