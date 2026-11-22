<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Level;
use App\Models\Option;
use App\Models\Question;
use App\Models\QuizAttempt;
use App\Models\QuizAttemptAnswer;
use Vinkla\Hashids\Facades\Hashids;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class QuizAttemptController extends Controller
{
     private function decodeId($id)
    {
        $decoded = Hashids::decode($id);
        return !empty($decoded) ? $decoded[0] : null;
    }
    private function encodeId($id)
{
    return Hashids::encode($id);
}


    //
  
public function startQuizAttempt(Request $request)
{
    $validated = $request->validate([
        'level_id' => 'required|string',
    ]);

    // Decode the encoded level ID received from Flutter.
    $levelId = $this->decodeId($validated['level_id']);

    if (!$levelId || !is_numeric($levelId)) {
        return response()->json([
            'status' => false,
            'message' => 'Invalid level ID.',
        ], 422);
    }

    // Verify that the level exists.
    $level = Level::find($levelId);

    if (!$level) {
        return response()->json([
            'status' => false,
            'message' => 'Level not found.',
        ], 404);
    }

    $userId = auth()->id();

    $attempt = DB::transaction(function () use ($userId, $levelId) {

        // Find an existing unfinished attempt.
        $existingAttempt = QuizAttempt::where('user_id', $userId)
            ->where('level_id', $levelId)
            ->where('status', 'in_progress')
            ->latest('id')
            ->lockForUpdate()
            ->first();

        if ($existingAttempt) {
            return $existingAttempt;
        }

        // Create a new attempt only if no unfinished attempt exists.
        return QuizAttempt::create([
            'uuid' => (string) Str::uuid(),
            'user_id' => $userId,
            'level_id' => $levelId,
            'status' => 'in_progress',
            'correct_answers' => 0,
            'wrong_answers' => 0,
            'xp_points' => 0,
        ]);
    });

    return response()->json([
        'status' => true,
        'message' => 'Quiz attempt started or resumed successfully.',
        'data' => [
            'attempt_id' => $attempt->uuid,
            'status' => $attempt->status,
            'correct_answers' => (int) $attempt->correct_answers,
            'wrong_answers' => (int) $attempt->wrong_answers,
            'xp_points' => (int) $attempt->xp_points,
        ],
    ], 200);
}

public function submitAnswer(Request $request, string $uuid)
{
    $validated = $request->validate([
        'question_id' => 'required|string',
        'selected_option' => 'required|string|size:1',
    ]);

    // Decode the encoded question ID.
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

    $result = DB::transaction(function () use (
        $request,
        $uuid,
        $validated,
        $questionId
    ) {
        // Find and lock the current attempt.
        $attempt = QuizAttempt::where('uuid', $uuid)
            ->where('user_id', $request->user()->id)
            ->lockForUpdate()
            ->firstOrFail();

        if ($attempt->status !== 'in_progress') {
            throw ValidationException::withMessages([
                'attempt_id' => ['This attempt is not in progress.'],
            ]);
        }

        // Find the question belonging to this level.
        $question = Question::where('id', $questionId)
            ->where('level_id', $attempt->level_id)
            ->firstOrFail();

        // Verify the selected option belongs to this question.
        $option = Option::where('question_id', $question->id)
            ->where('identifier', $validated['selected_option'])
            ->first();

        if (!$option) {
            throw ValidationException::withMessages([
                'selected_option' => [
                    'The selected option does not belong to this question.',
                ],
            ]);
        }

        // Evaluate the answer.
        $isCorrect = (bool) $option->is_correct;
        $expectedXp = $isCorrect ? 10 : 0;

        // Lock the existing answer, if autosave already created it.
        $existingAnswer = QuizAttemptAnswer::where('attempt_id', $attempt->id)
            ->where('question_id', $question->id)
            ->lockForUpdate()
            ->first();

        $alreadyAnswered = $existingAnswer !== null;

        // Determine if this answer was already evaluated with the same result.
        $wasAlreadyEvaluated = $existingAnswer !== null
            && $existingAnswer->selected_option === $option->identifier
            && (bool) $existingAnswer->is_correct === $isCorrect
            && (int) $existingAnswer->xp_earned === $expectedXp;

        // XP earned by this submission (not total attempt XP).
        $xpEarned = (!$wasAlreadyEvaluated && $isCorrect)
            ? $expectedXp
            : 0;

        if ($existingAnswer) {
            // Update the autosaved or previous answer.
            $existingAnswer->selected_option = $option->identifier;
            $existingAnswer->is_correct = $isCorrect;
            $existingAnswer->xp_earned = $expectedXp;
            $existingAnswer->save();
        } else {
            // Create a new answer if autosave did not create it.
            QuizAttemptAnswer::create([
                'attempt_id' => $attempt->id,
                'question_id' => $question->id,
                'selected_option' => $option->identifier,
                'is_correct' => $isCorrect,
                'xp_earned' => $expectedXp,
            ]);
        }

        // Recalculate statistics using the actual saved answers.
        $stats = DB::table('quiz_attempt_answers')
            ->where('attempt_id', $attempt->id)
            ->selectRaw(
                'COALESCE(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END), 0) AS correct_answers'
            )
            ->selectRaw(
                'COALESCE(SUM(CASE WHEN is_correct = 0 THEN 1 ELSE 0 END), 0) AS wrong_answers'
            )
            ->selectRaw(
                'COALESCE(SUM(xp_earned), 0) AS xp_points'
            )
            ->first();

        // Synchronize the attempt statistics.
        $attempt->correct_answers = (int) $stats->correct_answers;
        $attempt->wrong_answers = (int) $stats->wrong_answers;
        $attempt->xp_points = (int) $stats->xp_points;

        $attempt->save();
        $attempt->refresh();

        return [
            'already_answered' => $alreadyAnswered,
            'is_correct' => $isCorrect,
            'selected_option' => $option->identifier,
            'xp_earned' => $xpEarned,
            'attempt' => $attempt,
        ];
    });

    $attempt = $result['attempt'];

    return response()->json([
        'status' => true,
        'message' => $result['already_answered']
            ? 'Existing answer evaluated or updated successfully.'
            : 'Answer recorded successfully.',
        'data' => [
            'already_answered' => $result['already_answered'],
            'selected_option' => $result['selected_option'],
            'is_correct' => $result['is_correct'],
            'xp_earned' => $result['xp_earned'],
            'correct_answers' => (int) $attempt->correct_answers,
            'wrong_answers' => (int) $attempt->wrong_answers,
            'xp_points' => (int) $attempt->xp_points,
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

public function getProgress(string $uuid)
{
    $attempt = QuizAttempt::where('uuid', $uuid)
        ->where('user_id', auth()->id())
        ->with('answers')
        ->first();

    if (!$attempt) {
        return response()->json([
            'status' => false,
            'message' => 'Quiz attempt not found.',
        ], 404);
    }

    // Calculate statistics from saved answers.
    $answers = $attempt->answers;

    $correctAnswers = $answers->where('is_correct', true)->count();
    $wrongAnswers = $answers->where('is_correct', false)->count();

    $xpPoints = $answers->sum('xp_earned');

    // Synchronize attempt statistics.
    $attempt->correct_answers = $correctAnswers;
    $attempt->wrong_answers = $wrongAnswers;
    $attempt->xp_points = $xpPoints;
    $attempt->save();

    return response()->json([
        'status' => true,
        'data' => [
            'attempt_id' => $attempt->uuid,
            'status' => $attempt->status,
            'correct_answers' => $correctAnswers,
            'wrong_answers' => $wrongAnswers,
            'xp_points' => $xpPoints,

            'answers' => $answers->map(function ($answer) {
                return [
                    // Use the same ID format as Flutter's question models.
                    'question_id' => $this->encodeId($answer->question_id),
                    'selected_option' => $answer->selected_option,
                    'is_correct' => (bool) $answer->is_correct,
                    'xp_earned' => (int) $answer->xp_earned,
                ];
            })->values(),
        ],
    ]);
}
public function saveAnswer(Request $request, string $uuid)
{
    $validated = $request->validate([
        'question_id' => 'required|string',
        'selected_option' => 'required|string|size:1',
    ]);

    $attempt = QuizAttempt::where('uuid', $uuid)
        ->where('user_id', auth()->id())
        ->first();

    if (!$attempt) {
        return response()->json([
            'status' => false,
            'message' => 'Quiz attempt not found.',
        ], 404);
    }

    if ($attempt->status === 'completed') {
        return response()->json([
            'status' => false,
            'message' => 'This exam attempt is already completed.',
        ], 403);
    }

    // Decode the encoded question ID.
    $questionId = $this->decodeId($validated['question_id']);

    if (!$questionId) {
        return response()->json([
            'status' => false,
            'message' => 'Invalid question ID.',
        ], 422);
    }

    // Confirm that the question exists.
    $question = Question::find($questionId);

    if (!$question) {
        return response()->json([
            'status' => false,
            'message' => 'Question not found.',
        ], 404);
    }

    $selectedOption = strtoupper($validated['selected_option']);

    $answer = QuizAttemptAnswer::where('attempt_id', $attempt->id)
        ->where('question_id', $questionId)
        ->first();

    // Do not overwrite an answer that has already been checked.
    if ($answer && $answer->is_correct !== null) {
        return response()->json([
            'status' => true,
            'message' => 'Answer was already checked.',
            'data' => [
                'question_id' => $validated['question_id'],
                'selected_option' => $answer->selected_option,
                'is_correct' => $answer->is_correct,
                'already_checked' => true,
            ],
        ]);
    }

    $answer = QuizAttemptAnswer::updateOrCreate(
        [
            'attempt_id' => $attempt->id,
            'question_id' => $questionId,
        ],
        [
            'selected_option' => $selectedOption,
            'is_correct' => null,
            'answered_at' => now(),
        ]
    );

    return response()->json([
        'status' => true,
        'message' => 'Answer saved successfully.',
        'data' => [
            'question_id' => $validated['question_id'],
            'selected_option' => $answer->selected_option,
            'is_correct' => $answer->is_correct,
            'already_checked' => false,
        ],
    ]);
}
}