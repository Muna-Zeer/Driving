<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateQuestionRequest;
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
        $nextOrder = Question::where('level_id', $levelId)->max('order') + 1;

        return DB::transaction(function () use ($request, $levelId, $nextOrder) {

            $question = Question::create([
                'level_id'  => $levelId,
                'image_url' => $request->image_url,
                'order'     => $nextOrder,
            ]);


            // Save question translations.
            $questionTranslations = $request->input('translations', []);

            foreach ($questionTranslations as $translation) {
                $locale = $translation['locale'] ?? '';
                $text = trim((string) ($translation['text'] ?? ''));

                if (in_array($locale, ['en', 'ar'], true) && $text !== '') {
                    $question->translations()->create([
                        'locale' => $locale,
                        'text' => $text,
                    ]);
                }
            }

            // Save options and their translations.
            foreach ($request->input('options', []) as $optionData) {
                $option = $question->options()->create([
                    'identifier' => $optionData['identifier'],
                    'is_correct' => (bool) $optionData['is_correct'],
                    'image_url' => $optionData['image_url'] ?? null,
                ]);

                foreach ($optionData['translations'] ?? [] as $translation) {
                    $locale = $translation['locale'] ?? '';
                    $text = trim((string) ($translation['text'] ?? ''));

                    if (in_array($locale, ['en', 'ar'], true) && $text !== '') {
                        $option->translations()->create([
                            'locale' => $locale,
                            'text' => $text,
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


    public function update(UpdateQuestionRequest $request, $id): JsonResponse
    {
        $realId = $this->decodeId($id);

        $question = Question::findOrFail($realId);

        // Use the validation rules from UpdateQuestionRequest.
        $validated = $request->validated();

        return DB::transaction(function () use ($validated, $question) {

            // 1. Update basic question fields.
            if (array_key_exists('order', $validated)) {
                $question->order = $validated['order'];
            }

            if (array_key_exists('image_url', $validated)) {
                $question->image_url = $validated['image_url'];
            }

            $question->save();

            // 2. Update submitted question translations.
            if (array_key_exists('translations', $validated)) {
                $this->saveTranslations(
                    $question->translations(),
                    $validated['translations']
                );
            }

            // 3. Update options and their submitted translations.
            if (array_key_exists('options', $validated)) {

                foreach ($validated['options'] as $optionData) {

                    $option = $question->options()
                        ->where('identifier', $optionData['identifier'])
                        ->firstOrFail();

                    $option->is_correct = $optionData['is_correct'];

                    if (array_key_exists('image_url', $optionData)) {
                        $option->image_url = $optionData['image_url'];
                    }

                    $option->save();

                    $this->saveTranslations(
                        $option->translations(),
                        $optionData['translations']
                    );
                }
            }

            // 4. Reload updated database values.
            $question->refresh();

            $question->load([
                'translations',
                'options.translations',
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Question updated successfully.',
                'data' => new QuestionResource($question),
            ]);
        });
    }


    /**
     * Save translations using their actual locale.
     */
    private function saveTranslations($relation, array $translations): void
    {
        $savedLocales = [];

        foreach ($translations as $translation) {

            $locale = $translation['locale'];

            if (!in_array($locale, ['en', 'ar'], true)) {
                continue;
            }

            if (in_array($locale, $savedLocales, true)) {
                throw \Illuminate\Validation\ValidationException::withMessages([
                    'translations' => [
                        "Duplicate translation locale: {$locale}"
                    ]
                ]);
            }

            $savedLocales[] = $locale;

            $relation->updateOrCreate(
                [
                    'locale' => $locale
                ],
                [
                    'text' => $translation['text'] ?? ''
                ]
            );
        }
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
