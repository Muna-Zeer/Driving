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
    public function index(Request $request): JsonResponse
    {
        $query = Level::with('translations')->where('is_active',true);

        if($request->has('category_id')){
            $hashedId = $request->get('category_id');
            $decoded = Hashids::decode($hashedId);
            if(!empty($decoded)){
                $query->where('category_id',$decoded[0]);
            }
            else{
                return response()->json(['status'=>false,'message'=>'Invalid Category Hash'],400);
            }
        }

       if($request->has('group_key')){
           $query->where('group_key',$request->get('group_key'));
       }
       $levels = $query->orderBy('order')->get();

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
    public function update(UpdateLevelRequest $request, Level $level): JsonResponse
    {
        $data = $request->validated();

        $level->update([
            'group_key' => $data['group_key'] ?? $level->group_key,
            'level_number' => $data['level_number'] ?? $level->level_number,
            'questions_count' => $data['questions_count'] ?? $level->questions_count,
            'order' => $data['order'] ?? $level->order,
            'is_active' => $data['is_active'] ?? $level->is_active,
        ]);

        if (isset($data['translations'])) {
            foreach ($data['translations'] as $locale => $t) {
                $level->translations()->updateOrCreate(
                    ['locale' => $locale],
                    [
                        'name' => $t['name'],
                        'description' => $t['description'] ?? null,
                    ]
                );
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
    public function destroy(Level $level): JsonResponse
    {
        $level->delete();

        return response()->json([
            'status' => true,
            'message' => 'Level deleted successfully'
        ]);
    }
}
