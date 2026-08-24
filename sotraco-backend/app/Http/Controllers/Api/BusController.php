<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use Illuminate\Http\Request;

class BusController extends Controller
{
    // GET /api/buses?ligne_id=1&en_marche=1
    public function index(Request $request)
    {
        $query = Bus::with(['ligne.arrets', 'trajetActif.chauffeur']);

        if ($request->filled('ligne_id')) {
            $query->where('ligne_id', $request->ligne_id);
        }

        if ($request->boolean('en_marche')) {
            $query->where('en_marche', true);
        }

        $buses = $query->get()->map(function (Bus $bus) {
            $bus->en_direct = $bus->estEnDirect();
            return $bus;
        });

        return response()->json($buses);
    }

    public function show(Bus $bus)
    {
        $bus->load(['ligne.arrets', 'trajetActif.chauffeur']);
        $bus->en_direct = $bus->estEnDirect();

        return response()->json($bus);
    }

    // Réservé admin
    public function store(Request $request)
    {
        $data = $request->validate([
            'numero' => 'required|string|max:255',
            'immatriculation' => 'required|string|unique:buses,immatriculation',
            'capacite' => 'nullable|integer|min:1',
            'ligne_id' => 'nullable|exists:lignes,id',
            'statut' => 'nullable|in:actif,inactif,maintenance',
        ]);

        $bus = Bus::create($data);
        $bus->load(['ligne', 'trajetActif.chauffeur']);

        return response()->json($bus, 201);
    }

    public function update(Request $request, Bus $bus)
    {
        $data = $request->validate([
            'numero' => 'sometimes|string|max:255',
            'immatriculation' => 'sometimes|string|unique:buses,immatriculation,' . $bus->id,
            'capacite' => 'nullable|integer|min:1',
            'ligne_id' => 'nullable|exists:lignes,id',
            'statut' => 'nullable|in:actif,inactif,maintenance',
        ]);

        $bus->update($data);

        return response()->json($bus);
    }

    public function destroy(Bus $bus)
    {
        $bus->delete();

        return response()->json(['message' => 'Bus supprimé.']);
    }
}
