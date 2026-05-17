<?php

namespace App\Http\Controllers;

use App\Http\Resources\QuestionResource;
use App\Models\Question;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\JsonResponse;

class QuestionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {



    }

    public function getQuestionByLevel($level_id){
        $realLevel_id = $this->decodeId($level_id);
        $question = Question::with(['translations','options.translations'])
        ->where('level_id',$realLevel_id)
        ->orderBy('order','asc')
        ->get();
        return response()->json([
        'status'=>true,
        'data'=>QuestionResource::collection($question)
        ]);
        }
    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
  public function store(Request $request)
{
    return DB::transaction(function () use ($request) {

        $levelId = $this->decodeId($request->level_id);


        $count = Question::where('level_id', $levelId)->count();
        if ($count >= 30) {

            return response()->json([
                'status'  => false,
                'message' => 'This level is already full (30 questions)'
            ], 422);
        }

        $question = Question::create([
            'level_id'  => $levelId,
            'image_url' => $request->image_url,
            'order'     => $request->order ?? ($count + 1),
            'question_text'=>$request->question_text
        ]);

        // 4. Handle Question Text Polymorphic Translations
        foreach ($request->question_text as $locale => $text) {
            $question->translations()->create([
                'locale' => $locale,
                'text'   => $text
            ]);
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
        ], 21);
    });
}
    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $realId = $this->decoded($id);
        $question = Question::with(['translations','options.translations'])->findOrFail($realId);

        return response()->json([
            'status'=>true,
            'data'=>new QuestionResource($question)
        ]);

    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
   public function destroy($id): JsonResponse {
    $question = Question::findOrFail($this->decodeId($id));
    $question->delete();
    return response()->json(['status' => true, 'message' => 'Deleted']);
}

}
