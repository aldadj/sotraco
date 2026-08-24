<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ligne;
use Illuminate\Http\Request;

class LigneController extends Controller
{
    public function index()
    {
        return response()->json(
            Ligne::where('actif', true)
                ->withCount('buses')
                ->get()
        );
    }

    public function show(Ligne $ligne)
    {
        $ligne->load(['arrets', 'buses' => function ($q) {
            $q->with('chauffeur:id,name');
        }]);

        return response()->json($ligne);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'code' => 'required|string|unique:lignes,code',
            'nom' => 'required|string',
            'depart' => 'required|string',
            'destination' => 'required|string',
            'couleur' => 'nullable|string',
            'description' => 'nullable|string',
        ]);

        $ligne = Ligne::create($data);

        // Attache les arrêts avec leur ordre, ex: [{"arret_id":1,"ordre":1}, ...]
        if ($request->filled('arrets')) {
            foreach ($request->arrets as $item) {
                $ligne->arrets()->attach($item['arret_id'], ['ordre' => $item['ordre'] ?? 0]);
            }
        }

        return response()->json($ligne->load('arrets'), 201);
    }

    public function update(Request $request, Ligne $ligne)
    {
        $data = $request->validate([
            'code' => 'sometimes|string|unique:lignes,code,' . $ligne->id,
            'nom' => 'sometimes|string',
            'depart' => 'sometimes|string',
            'destination' => 'sometimes|string',
            'couleur' => 'nullable|string',
            'description' => 'nullable|string',
            'actif' => 'nullable|boolean',
        ]);

        $ligne->update($data);

        return response()->json($ligne);
    }

    public function destroy(Ligne $ligne)
    {
        $ligne->delete();

        return response()->json(['message' => 'Ligne supprimée.']);
    }
}
