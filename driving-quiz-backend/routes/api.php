<?php

use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\LevelController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\QuestionController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Models\MediaLibrary;

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


// Fetch all images for the Flutter library picker
Route::get('/media-library', function () {
    return response()->json(MediaLibrary::all());
});

// Upload a new image to storage and save URL in MySQL
Route::post('/media-library/upload', function (Request $request) {
    $request->validate([
        'title' => 'required|string',
        'image' => 'required|image|mimes:jpeg,png,jpg,svg|max:2048',
    ]);

    // Stores image in 'storage/app/public/media'
    $path = $request->file('image')->store('media', 'public');
    $url = asset('storage/' . $path);

    $media = MediaLibrary::create([
        'title' => $request->title,
        'category' => $request->category ?? 'General',
        'image_url' => $url,
    ]);

    return response()->json($media, 201);
});
