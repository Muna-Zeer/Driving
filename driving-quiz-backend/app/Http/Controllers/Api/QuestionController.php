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
        try {
            // Safely attempt to decode the ID
            $realLevelId = $this->decodeId($levelId);
        } catch (\Exception $e) {
            // If decoding throws an error (e.g. invalid hash format), catch it gracefully
            return response()->json([
                'status' => false,
                'message' => 'Invalid Level ID format'
            ], 400);
        }

        if (!$realLevelId) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid Level ID'
            ], 400);
        }

        // Fetch questions using the resolved level ID
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
                    // Handle case where text might be an array or string
                    $textValue = is_array($text) ? ($text['text'] ?? '') : $text;

                    if (!empty(trim((string)$textValue))) {
                        $question->translations()->create([
                            'locale' => $locale,
                            'text'   => $textValue
                        ]);
                    }
                }
            }

            if ($request->has('options')) {
                foreach ($request->options as $optionData) {
                    $option = $question->options()->create([
                        'identifier' => $optionData['identifier'],
                        'is_correct' => (bool)$optionData['is_correct'],
                        'image_url'=>$optionData['image_url'] ?? null,
                    ]);

                    if (isset($optionData['translations'])) {
                        foreach ($optionData['translations'] as $locale => $text) {
                            $textValue = is_array($text) ? ($text['text'] ?? '') : $text;

                            if (!empty(trim((string)$textValue))) {
                                $option->translations()->create([
                                    'locale' => $locale,
                                    'text'   => $textValue
                                ]);
                            }
                        }
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
            // 1. Partially update basic question fields if present
            if ($request->has('image_url')) {
                $question->image_url = $request->image_url;
            }
            if ($request->has('order')) {
                $question->order = $request->order;
            }
            $question->save();

            // 2. Partially update question translations (safely skips empty text)
            if ($request->has('question_text')) {
                $qText = $request->question_text;
                
                $translationsArray = is_array($qText) && array_keys($qText) !== range(0, count($qText) - 1)
                    ? $qText 
                    : collect($qText)->pluck('text', 'locale')->toArray();

                foreach ($translationsArray as $locale => $text) {
                    // Only update if text is not empty; otherwise, delete or skip to prevent null errors
                    if (!empty(trim($text))) {
                        $question->translations()->updateOrCreate(
                            ['locale' => $locale],
                            ['text' => $text]
                        );
                    } else {
                        $question->translations()->where('locale', $locale)->delete();
                    }
                }
            }

            // 3. Partially update options only if provided in the request
            if ($request->has('options')) {
                foreach ($request->options as $optionData) {
                    if (!isset($optionData['identifier'])) continue;

                    $option = $question->options()->where('identifier', $optionData['identifier'])->first();

                    if ($option) {
                        // Update correctness if provided
                        if (isset($optionData['is_correct'])) {
                            $option->update([
                                'is_correct' => (bool)$optionData['is_correct']
                            ]);
                        }

                        // Update option translations if provided
                        if (isset($optionData['translations'])) {
                            $optTranslations = $optionData['translations'];
                            
                            $optTransArray = is_array($optTranslations) && array_keys($optTranslations) !== range(0, count($optTranslations) - 1)
                                ? $optTranslations 
                                : collect($optTranslations)->pluck('text', 'locale')->toArray();

                            foreach ($optTransArray as $locale => $text) {
                                if (!empty(trim($text))) {
                                    $option->translations()->updateOrCreate(
                                        ['locale' => $locale],
                                        ['text' => $text]
                                    );
                                } else {
                                    $option->translations()->where('locale', $locale)->delete();
                                }
                            }
                        }
                    }
                }
            }

            return response()->json([
                'status'  => true,
                'message' => 'Question updated successfully.',
                'data'    => new QuestionResource($question->load(['translations', 'options.translations']))
            ]);
        });
    }
    /**
     * Remove the specified resource from storage (Admin Only).
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

            $question = \App\Models\Question::find($realId);

            if (!$question) {
                return response()->json([
                    'status' => false,
                    'message' => "Decoded ID is $realId, but no question exists with this ID in database."
                ], 404);
            }

            $deletedOrder = $question->order;
            $question->delete();

            \App\Models\Question::where('order', '>', $deletedOrder)->decrement('order');

            return response()->json([
                'status' => true,
                'message' => 'Deleted and reordered successfully'
            ]);
        }
    }
}
