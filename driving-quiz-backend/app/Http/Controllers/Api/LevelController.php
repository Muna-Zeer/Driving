<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreLevelRequest;
use App\Http\Requests\UpdateLevelRequest;
use App\Http\Resources\LevelResource;
use App\Models\Level;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Vinkla\Hashids\Facades\Hashids;

class LevelController extends Controller
{
    /**
     * List levels
     */
    // 1. Accept $id as an explicit argument parameter matched from your route {id}
    public function index(Request $request, $id): JsonResponse
    {
        $decoded = Hashids::decode($id);

        if (empty($decoded)) {
            return response()->json(['status' => false, 'message' => 'Invalid Category Hash'], 400);
        }

        // Force it to be a clean integer (e.g., 6)
        $categoryId = (int) $decoded[0];

        $levels = Level::with('translations')
            ->whereRaw('category_id = ?', [$categoryId])
            ->where('is_active', true)
            ->orderBy('order')
            ->get();

        return response()->json([
            'status' => true,
            'message' => 'Levels fetched successfully',
            'data' => LevelResource::collection($levels)
        ]);
    }

    /**
     * Show single level
     */
    public function show(Level $level): JsonResponse
    {
        $level->load('translations');

        return response()->json([
            'status' => true,
            'message' => 'Level fetched successfully',
            'data' => new LevelResource($level)
        ]);
    }

    /**
     * Store new level
     */
    public function store(StoreLevelRequest $request): JsonResponse
    {
        $levelData = $request->validated();
        $nextOrder = Level::where('category_id', $request->category_id)->max('order') + 1;
        $levelData['order'] = $nextOrder;

        $hasAtLeastOneName = collect($request->translations)->contains(function ($t) {
            return !empty(trim($t['name'] ?? ''));
        });

        if (!$hasAtLeastOneName) {
            return response()->json([
                'status' => false,
                'message' => 'At least one translation language is required',
            ], 422);
        }

        $level = Level::create($levelData);

        foreach ($levelData['translations'] as $t) {
            if (!empty(trim($t['name'] ?? ''))) {
                $level->translations()->create([
                    'locale' => $t['locale'],
                    'name' => $t['name'],
                    'description' => $t['description'] ?? null,
                ]);
            }
        }

        return response()->json([
            'status' => true,
            'message' => 'Level created successfully',
            'data' => new LevelResource($level->load('translations'))
        ], 201);
    }

    /**
     * Update level
     */
    public function update(UpdateLevelRequest $request, String $id): JsonResponse
    {
        $decodedArray = Hashids::decode($id);
        if (empty($decodedArray)) {
            return response()->json([
                "status" => false,
                "message" => "Failed to decode the hashIds $id"
            ]);
        }
        $realId = $decodedArray[0];

        $level = \App\Models\Level::find($realId);

        if (!$level) {
            return response()->json([
                'status' => false,
                'message' => "No level exists with this ID in the database."
            ], 404);
        }

        $data = $request->validated();

        $level->update([
            'group_key' => $data['group_key'] ?? $level->group_key,
            'level_number' => $data['level_number'] ?? $level->level_number,
            'questions_count' => $data['questions_count'] ?? $level->questions_count,
            'order' => $data['order'] ?? $level->order,
            'is_active' => $data['is_active'] ?? $level->is_active,
        ]);

        // Fixed: Expects an indexed array list of maps matching store()
        if (isset($data['translations']) && is_array($data['translations'])) {
            foreach ($data['translations'] as $t) {
                if (!empty(trim($t['name'] ?? ''))) {
                    $level->translations()->updateOrCreate(
                        ['locale' => $t['locale']],
                        [
                            'name' => $t['name'],
                            'description' => $t['description'] ?? null,
                        ]
                    );
                }
            }
        }

        return response()->json([
            'status' => true,
            'message' => 'Level updated successfully',
            'data' => new LevelResource($level->load('translations'))
        ]);
    }

    /**
     * Delete level
     */
    public function destroy(String $id): JsonResponse
    { {
            $decodedArray = Hashids::decode($id);

            if (empty($decodedArray)) {
                return response()->json([
                    'status' => false,
                    'message' => "Laravel failed to decode the Hash ID: '$id'"
                ], 404);
            }

            $realId = $decodedArray[0];

            $level = \App\Models\Level::find($realId);

            if (!$level) {
                return response()->json([
                    'status' => false,
                    'message' => "Decoded ID is $realId, but no level exists with this ID in database."
                ], 404);
            }

            $deletedOrder = $level->order;
            $level->delete();

            \App\Models\Level::where('order', '>', $deletedOrder)->decrement('order');

            return response()->json([
                'status' => true,
                'message' => 'Deleted and reordered successfully'
            ]);
        }
    }
}
