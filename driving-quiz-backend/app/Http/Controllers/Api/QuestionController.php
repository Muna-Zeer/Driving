<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Http\Resources\QuestionResource;
use App\Models\Question;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Vinkla\Hashids\Facades\Hashids;

class QuestionController extends Controller
{
    /**
     * Decode Hashids private helper.
     */
    private function decodeId($id)
    {
        $decoded = Hashids::decode($id);
        return !empty($decoded) ? $decoded[0] : null;
    }

    /**
     * Display a listing of the resource (Admin overview with optional filter).
     */
    /**
     * Display a listing of the resource (Admin overview with optional filter).
     */
    public function index(Request $request): JsonResponse
    {
        $realLevelId = $request->query('level_id') ? $this->decodeId($request->query('level_id')) : null;

        // CRITICAL: Force load options cleanly and safely
        $questions = Question::with(['translations', 'options', 'options.translations'])
            ->when($realLevelId, function ($query) use ($realLevelId) {
                return $query->where('level_id', $realLevelId);
            })
            ->orderBy('level_id', 'asc')
            ->orderBy('order', 'asc')
            ->paginate(15);

        return response()->json([
            'status' => true,
            'data'   => QuestionResource::collection($questions)
        ]);
    }

    /**
     * Mobile app dedicated fetch to load a level's complete sequential quiz grid.
     */
    public function getQuestionByLevel($levelId): JsonResponse
    {
        $realLevelId = $this->decodeId($levelId);

        if (!$realLevelId) {
            return response()->json(['status' => false, 'message' => 'Invalid Level ID'], 400);
        }

        // CRITICAL: Force load options cleanly and safely
        $questions = Question::with(['translations', 'options', 'options.translations'])
            ->where('level_id', $realLevelId)
            ->orderBy('order', 'asc')
            ->get();

        return response()->json([
            'status' => true,
            'data'   => QuestionResource::collection($questions)
        ]);
    }
    /**
     * Store a newly created resource in storage (Admin Only).
     */
    public function store(Request $request): JsonResponse
    {
        $levelId = $this->decodeId($request->level_id);

        if (!$levelId) {
            return response()->json([
                'status'  => false,
                'message' => 'The provided level_id is invalid or could not be decoded.'
            ], 422);
        }

        $count = Question::where('level_id', $levelId)->count();
        if ($count >= 60) {
            return response()->json([
                'status'  => false,
                'message' => 'This level is already full (30 questions)'
            ], 422);
        }

        return DB::transaction(function () use ($request, $levelId, $count) {

            $question = Question::create([
                'level_id'  => $levelId,
                'image_url' => $request->image_url,
                'order'     => $request->order ?? ($count + 1),
            ]);

            if ($request->has('question_text')) {
                foreach ($request->question_text as $locale => $text) {
                    $question->translations()->create([
                        'locale' => $locale,
                        'text'   => $text
                    ]);
                }
            }

            if ($request->has('options')) {
                foreach ($request->options as $optionData) {
                    $option = $question->options()->create([
                        'identifier' => $optionData['identifier'],
                        'is_correct' => (bool)$optionData['is_correct']
                    ]);

                    foreach ($optionData['translations'] as $locale => $text) {
                        $option->translations()->create([
                            'locale' => $locale,
                            'text'   => $text
                        ]);
                    }
                }
            }

            return response()->json([
                'status'  => true,
                'message' => 'Question and options created successfully.',
                'data'    => new QuestionResource($question->load(['translations', 'options.translations']))
            ], 201);
        });
    }
    /**
     * Display the specified resource (Loads a single item details form into Admin dashboard).
     */
    public function show($id): JsonResponse
    {
        $realId = $this->decodeId($id);
        $question = Question::with(['translations', 'options.translations'])->findOrFail($realId);

        return response()->json([
            'status' => true,
            'data'   => new QuestionResource($question)
        ]);
    }

    /**
     * Update the specified resource in storage (Admin Only).
     */
    public function update(Request $request, $id): JsonResponse
    {
        $realId = $this->decodeId($id);
        $question = Question::findOrFail($realId);

        return DB::transaction(function () use ($request, $question) {
            if ($request->has('image_url')) {
                $question->image_url = $request->image_url;
            }
            if ($request->has('order')) {
                $question->order = $request->order;
            }
            $question->save();

            if ($request->has('question_text')) {
                foreach ($request->question_text as $locale => $text) {
                    $question->translations()->updateOrCreate(
                        ['locale' => $locale],
                        ['text' => $text]
                    );
                }
            }

            // Fixed: Cleaned up option lookup queries and variable loops
            if ($request->has('options')) {
                foreach ($request->options as $optionData) {
                    $option = $question->options()->where('identifier', $optionData['identifier'])->first();

                    if ($option) {
                        $option->update([
                            'is_correct' => (bool)$optionData['is_correct']
                        ]);

                        foreach ($optionData['translations'] as $locale => $text) {
                            $option->translations()->updateOrCreate(
                                ['locale' => $locale],
                                ['text' => $text]
                            );
                        }
                    }
                }
            }

            return response()->json([
                'status'  => true,
                'message' => 'Question structural modifications updated successfully.',
                'data'    => new QuestionResource($question->load(['translations', 'options.translations']))
            ]);
        });
    }

    /**
     * Remove the specified resource from storage (Admin Only).
     */
    public function destroy($id): JsonResponse
    {
        $question = Question::findOrFail($this->decodeId($id));
        $question->delete();

        return response()->json([
            'status'  => true,
            'message' => 'Question deleted successfully'
        ]);
    }
}
