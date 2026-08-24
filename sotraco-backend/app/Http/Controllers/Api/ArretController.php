<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Arret;
use Illuminate\Http\Request;

class ArretController extends Controller
{
    public function index()
    {
        return response()->json(Arret::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nom' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'quartier' => 'nullable|string',
        ]);

        return response()->json(Arret::create($data), 201);
    }

    public function update(Request $request, Arret $arret)
    {
        $data = $request->validate([
            'nom' => 'sometimes|string',
            'latitude' => 'sometimes|numeric',
            'longitude' => 'sometimes|numeric',
            'quartier' => 'nullable|string',
        ]);

        $arret->update($data);

        return response()->json($arret);
    }

    public function destroy(Arret $arret)
    {
        $arret->delete();

        return response()->json(['message' => 'Arrêt supprimé.']);
    }
}
