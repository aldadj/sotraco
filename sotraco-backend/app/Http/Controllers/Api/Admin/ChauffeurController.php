<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class ChauffeurController extends Controller
{
    public function index()
    {
        $chauffeurs = User::where('role', 'chauffeur')
            ->with([
                'trajetActif.bus',
                'trajetActif.ligne',
            ])
            ->get();

        return response()->json($chauffeurs);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'telephone' => 'required|string|max:20',
            'password' => 'required|string|min:6',
        ]);

        $chauffeur = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'telephone' => $data['telephone'],
            'password' => Hash::make($data['password']),
            'role' => 'chauffeur',
        ]);

        return response()->json($chauffeur, 201);
    }

    public function show(User $chauffeur)
    {
        if (! $chauffeur->isChauffeur()) {
            return response()->json([
                'message' => 'Cet utilisateur n\'est pas un chauffeur.'
            ], 404);
        }

        $chauffeur->load([
            'trajetActif.bus',
            'trajetActif.ligne',
            'trajets.bus',
            'trajets.ligne',
        ]);

        return response()->json($chauffeur);
    }

    public function update(Request $request, User $chauffeur)
    {
        if (! $chauffeur->isChauffeur()) {
            return response()->json([
                'message' => 'Cet utilisateur n\'est pas un chauffeur.'
            ], 404);
        }

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $chauffeur->id,
            'telephone' => 'sometimes|string|max:20',
            'password' => 'nullable|string|min:6',
        ]);

        if (! empty($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        } else {
            unset($data['password']);
        }

        $chauffeur->update($data);

        return response()->json($chauffeur);
    }

    public function destroy(User $chauffeur)
    {
        if (! $chauffeur->isChauffeur()) {
            return response()->json([
                'message' => 'Cet utilisateur n\'est pas un chauffeur.'
            ], 404);
        }

        $chauffeur->delete();

        return response()->json([
            'message' => 'Chauffeur supprimé avec succès.'
        ]);
    }
}