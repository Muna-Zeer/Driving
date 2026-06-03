<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    // handles both the zero-click anonymous authentication and the conversion process.

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_id' => 'required'
        ]);


        $user = User::firstOrCreate(
            ['device_id' => $request->device_id],
            ['name' => 'زائر مجهول', 'role' => 'guest']
        );

        $token = $user->createToken('guest')->plainTextToken;
        return response()->json([
            'message' => 'Authenticated successfully as guest',
            'token' => $token,
            'role' => $user->role
        ], 200);
    }

    public function UpgradesGuestAccount(Request $request)
    {
        $user = $request->user();
        if (!$user || $user->role !== 'guest') {
            return response()->json(['error' => 'Invalid action context'], 400);
        }

        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique|:users,email',
            'password' => 'required|string|min:6',
            'name' => 'required|string'
        ]);
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }
        $user->update([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'device_id' => null
        ]);
        return response()->json([

            'message' => 'Account successfully upgraded',
            'user' => $user
        ], 200);
    }
    //     if (!$user || !Hash::check($request->password, $user->password)) {
    //         return response()->json(['message' => 'Invalid credentials'], 401);
    //     }

    //     // Generate the token
    //     $token = $user->createToken('admin_token')->plainTextToken;

    //     return response()->json([
    //         'status' => true,
    //         'admin_token' => $token
    //     ]);
    // }

}
