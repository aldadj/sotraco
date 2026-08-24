<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /**
     * Inscription publique.
     * Seuls les rôles passager et chauffeur peuvent être créés ici.
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'telephone' => 'nullable|string|max:20',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = \App\Models\User::create([
            'name' => $request->name,
            'email' => $request->email,
            'telephone' => $request->telephone,
            'password' => Hash::make($request->password),
            'role' => 'passager',
        ]);

        // Un nouveau chauffeur n'a normalement pas encore de trajet actif.
        // On charge quand même les relations pour garder une réponse uniforme.
        $user->load([
            'trajetActif.bus',
            'trajetActif.ligne',
        ]);

        $token = $user->createToken('sotraco')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    /**
     * Création d'un compte chauffeur par un administrateur.
     */
    public function createChauffeur(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'telephone' => 'nullable|string|max:20',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = \App\Models\User::create([
            'name' => $request->name,
            'email' => $request->email,
            'telephone' => $request->telephone,
            'password' => Hash::make($request->password),
            'role' => 'chauffeur',
        ]);

        return response()->json($user, 201);
    }

    /**
     * Connexion.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = \App\Models\User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Identifiants invalides.',
            ], 401);
        }

        /*
         * Pour un chauffeur, on récupère automatiquement :
         *
         * utilisateur
         *     └── trajet actif
         *          ├── bus
         *          └── ligne
         */
        $user->load([
            'trajetActif.bus',
            'trajetActif.ligne',
        ]);

        $token = $user->createToken('sotraco')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    /**
     * Retourne l'utilisateur actuellement connecté.
     */
    public function me(Request $request)
    {
        $user = $request->user();

        /*
         * Permet au Flutter de récupérer le bus et la ligne
         * actuellement associés au chauffeur.
         */
        $user->load([
            'trajetActif.bus',
            'trajetActif.ligne',
        ]);

        return response()->json($user);
    }

    /**
     * Déconnexion.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Déconnecté.',
        ]);
    }
}