<?php

use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\LevelController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\QuestionController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

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

/*
|--------------------------------------------------------------------------
| Public Routes (المسارات العامة - المتاحة للجميع بدون صلاحيات)
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);

Route::post('/login', [AuthController::class, 'login']);

Route::post('/auth/guest-authenticate', [AuthController::class, 'guestAuthenticate']);




Route::middleware('auth:sanctum')->group(function () {

    Route::post('/auth/upgrade-account', [AuthController::class, 'upgradeGuestAccount']);

    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});

Route::post('login', [AuthController::class, 'login']);

Route::middleware(['auth:sanctum', 'admin'])->group(function () {
 Route::apiResource('level', LevelController::class);
});

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

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('questions', [QuestionController::class, 'index']);
    Route::get('levels/{level_id}/questions', [QuestionController::class, 'getQuestionByLevel']);
});

// Public routes (Guests can see categories)
Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('questions', QuestionController::class);
});
