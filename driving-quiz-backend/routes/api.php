<?php

use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\LevelController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\QuestionController;
use Illuminate\Http\Request;

use Illuminate\Support\Facades\Route;
use App\Models\MediaLibrary;
use Illuminate\Support\Facades\Storage;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::post('login', [AuthController::class, 'login']);
Route::apiResource('level', LevelController::class);
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Public routes (Guests can see categories)
Route::get('categories', [CategoryController::class, 'index']);
Route::get('categories/{id}', [CategoryController::class, 'show']);

// Protected routes (Only Admins can modify)
Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::post('categories', [CategoryController::class, 'store']);
    Route::put('categories/{id}', [CategoryController::class, 'update']);
    Route::delete('categories/{id}', [CategoryController::class, 'destroy']);
});


// Protected routes for question processes(Only Admins can modify)
    Route::get('categories/{id}/levels', [LevelController::class, 'index']);

Route::middleware(['auth:sanctum'])->group(function () {

    // Questions routes
    Route::get('questions', [QuestionController::class, 'index']);
    Route::get('levels/{level_id}/questions', [QuestionController::class, 'getQuestionByLevel']);

    // Level management routes
    Route::post('level', [LevelController::class, 'store']);
    Route::put('level/{id}', [LevelController::class, 'update']);
    Route::delete('level/{id}', [LevelController::class, 'destroy']);
});

// Public routes (Guests can see categories)
Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('questions', QuestionController::class);
});
Route::get('/media-library', function () {
    return response()->json(MediaLibrary::all(), 200);
});

// 2. Stream individual images with explicit CORS headers
Route::get('/media-library/{filename}', function ($filename) {
    $path = storage_path('app/public/media/' . $filename);

    if (!file_exists($path)) {
        return response()->json(['message' => 'Image not found'], 404);
    }

    $file = file_get_contents($path);
    return response($file, 200)
        ->header('Content-Type', mime_content_type($path))
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, OPTIONS');
});

// 3. Upload a new image and save its custom stream URL in MySQL
Route::post('/media-library/upload', function (Request $request) {
    $request->validate([
        'title' => 'required|string',
        'image' => 'required|image|mimes:jpeg,png,jpg,svg|max:2048',
    ]);

    $path = $request->file('image')->store('media', 'public');
    $filename = basename($path);
    $url = url('/api/media-library/' . $filename);

    $media = MediaLibrary::create([
        'title' => $request->title,
        'category' => $request->category ?? 'General',
        'image_url' => $url,
    ]);

    return response()->json($media, 201);
});
Route::delete('/media-library/{id}', function ($id) {
    $media = MediaLibrary::find($id);

    if (!$media) {
        return response()->json(['message' => 'Media not found'], 404);
    }

    $filename = basename($media->image_url);
    $path = 'media/' . $filename;

    if (Storage::disk('public')->exists($path)) {
        Storage::disk('public')->delete($path);
    }

    $media->delete();

    return response()->json(['message' => 'Media deleted successfully'], 200);
});
