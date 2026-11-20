<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Option;
use App\Models\Question;
use App\Models\QuizAttempt;
use App\Models\QuizAttemptAnswer;
use Vinkla\Hashids\Facades\Hashids;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Validator;

class QuizAttemptController extends Controller
{
     private function decodeId($id)
    {
        $decoded = Hashids::decode($id);
        return !empty($decoded) ? $decoded[0] : null;
    }

    //
  
public function start(Request $request)
{
    // Decode the hashed/encoded level ID
    $decodedLevelId = $this->decodeId($request->level_id);

    // Validate the actual database ID
    $validated = Validator::make([
        'level_id' => $decodedLevelId,
    ], [
        'level_id' => 'required|integer|exists:levels,id',
    ])->validate();

    $attempt = QuizAttempt::create([
        'user_id' => $request->user()->id,
        'level_id' => $validated['level_id'],
        'status' => 'in_progress',
    ]);

    return response()->json([
        'status' => 'true',
        'message' => 'Quiz started successfully',
        'data' => [
            'attempt_id' => $attempt->uuid,
            'correct_answers' => 0,
            'wrong_answers' => 0,
            'xp_points' => 0,
        ]
    ], 201);
}


   public function submitAnswer(Request $request, String $uuid)
{
    // Validate the encoded question ID as a string.
    $validated = $request->validate([
        'question_id' => 'required|string',
        'selected_option' => 'required|string|size:1',
    ]);

    // Decode the question ID.
    try {
        $questionId = $this->decodeId($validated['question_id']);

        if (!is_numeric($questionId) || (int) $questionId <= 0) {
            throw new \Exception('Invalid question ID.');
        }

        $questionId = (int) $questionId;

    } catch (\Throwable $e) {
        throw ValidationException::withMessages([
            'question_id' => ['The provided question ID is invalid.'],
        ]);
    }

    $result = DB::transaction(function () use ($request, $uuid, $validated, $questionId) {

        $attempt = QuizAttempt::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->lockForUpdate()
            ->firstOrFail();

        if ($attempt->status !== 'in_progress') {
            throw ValidationException::withMessages([
                'attempt_id' => [
                    'This attempt is not in progress and cannot accept answers.'
                ],
            ]);
        }

        // Find the question using its decoded database ID.
        $question = Question::where('id', $questionId)
            ->where('level_id', $attempt->level_id)
            ->firstOrFail();

        // Check whether the question was already answered.
        $existingAnswer = QuizAttemptAnswer::where('attempt_id', $attempt->id)
            ->where('question_id', $question->id)
            ->first();

        if ($existingAnswer) {
            return [
                'already_answered' => true,
                'is_correct' => $existingAnswer->is_correct,
                'xp_earned' => $existingAnswer->xp_earned,
                'selected_option' => $existingAnswer->selected_option,
                'attempt' => $attempt,
            ];
        }

        // Verify that the selected option belongs to this question.
        $option = Option::where('question_id', $question->id)
            ->where('identifier', $validated['selected_option'])
            ->first();

        if (!$option) {
            throw ValidationException::withMessages([
                'selected_option' => [
                    'The selected option does not belong to this question.'
                ],
            ]);
        }

        $isCorrect = $option->is_correct;
        $xpEarned = $isCorrect ? 10 : 0;

        // Save the answer using the actual database question ID.
        QuizAttemptAnswer::create([
            'attempt_id' => $attempt->id,
            'question_id' => $question->id,
            'selected_option' => $option->identifier,
            'is_correct' => $isCorrect,
            'xp_earned' => $xpEarned,
        ]);

        $attempt->increment(
            $isCorrect ? 'correct_answers' : 'wrong_answers'
        );

        if ($xpEarned > 0) {
            $attempt->increment('xp_points', $xpEarned);
        }

        $attempt->refresh();

        return [
            'already_answered' => false,
            'is_correct' => $isCorrect,
            'xp_earned' => $xpEarned,
            'selected_option' => $option->identifier,
            'attempt' => $attempt,
        ];
    });

    $attempt = $result['attempt'];

    return response()->json([
        'status' => true,
        'message' => $result['already_answered']
            ? 'Question was already answered.'
            : 'Answer recorded successfully.',

        'data' => [
            'already_answered' => $result['already_answered'],
            'selected_option' => $result['selected_option'],
            'is_correct' => $result['is_correct'],
            'xp_earned' => $result['xp_earned'],
            'correct_answers' => $attempt->correct_answers,
            'wrong_answers' => $attempt->wrong_answers,
            'xp_points' => $attempt->xp_points,
        ],
    ]);
}
public function show($uuid)
{
    $attempt = QuizAttempt::where('uuid', $uuid)
        ->where('user_id', auth()->id())
        ->first();

    if (!$attempt) {
        return response()->json([
            'status' => false,
            'message' => 'Quiz attempt not found.',
        ], 404);
    }

    return response()->json([
        'status' => true,
        'message' => 'Quiz attempt retrieved successfully.',
        'data' => [
            'attempt_id' => $attempt->uuid,
            'correct_answers' => $attempt->correct_answers ?? 0,
            'wrong_answers' => $attempt->wrong_answers ?? 0,
            'xp_points' => $attempt->xp_points ?? 0,
        ],
    ], 200);
}

}