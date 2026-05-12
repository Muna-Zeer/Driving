<?php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {

        if (!Auth::check()) {
            Log::warning('AdminMiddleware: No user authenticated via Sanctum.');
            return response()->json(['message' => 'Not authenticated'], 401);
        }

        $user = Auth::user();

        Log::info('AdminMiddleware: Checking user permissions', [
            'id' => $user->id,
            'email' => $user->email,
            'is_admin_raw_value' => $user->is_admin,
        ]);

        if ($user->is_admin) {
            return $next($request);
        }

        Log::error('AdminMiddleware: Access denied for user ' . $user->email);
        return response()->json(['message' => 'Forbidden: Admin access only'], 403);
    }
}
