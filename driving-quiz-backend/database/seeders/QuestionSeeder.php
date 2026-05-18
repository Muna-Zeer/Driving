<?php

namespace Database\Seeders;

use App\Models\Level;
use App\Models\Question;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class QuestionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        if (Level::count() === 0) {
            $this->command->error("No levels found! Please run LevelSeeder before running QuestionSeeder.");
            return;
        }

        $this->command->info("Seeding 30 questions and 4 options for every existing level...");

        // Chunk processing prevents high RAM consumption when database sizes scale
        Level::chunk(50, function ($levels) {
            DB::transaction(function () use ($levels) {
                foreach ($levels as $level) {

                    for ($qNum = 1; $qNum <= 30; $qNum++) {

                        // 1. Generate base question structure using its factory definition
                        $question = Question::factory()->create([
                            'level_id' => $level->id,
                            'order' => $qNum,
                        ]);

                        // 2. Attach polymorphic question texts
                        $question->translations()->createMany([
                            [
                                'locale' => 'ar',
                                'text' => "السؤال رقم {$qNum}: ماذا تعني هذه الشاخصة المرورية المحددة؟"
                            ],
                            [
                                'locale' => 'en',
                                'text' => "Question #{$qNum}: What does this specific traffic sign mean?"
                            ]
                        ]);

                        // 3. Inject the 4 interactive multi-choice options directly
                        $identifiers = ['a', 'b', 'c', 'd'];
                        $correctChoice = 'b'; // We will mark answer option 'b' as true dynamically

                        foreach ($identifiers as $char) {
                            $isCorrect = ($char === $correctChoice);

                            $option = $question->options()->create([
                                'identifier' => $char,
                                'is_correct' => $isCorrect
                            ]);

                            // 4. Attach localized text labels to each radio option choice
                            $option->translations()->createMany([
                                [
                                    'locale' => 'ar',
                                    'text' => "خيار الإجابة ({$char}) " . ($isCorrect ? "هو الخيار الصحيح والمثالي" : "خيار خاطئ")
                                ],
                                [
                                    'locale' => 'en',
                                    'text' => "Option choice ({$char}) " . ($isCorrect ? "is the correct option" : "is incorrect")
                                ]
                            ]);
                        }
                    }
                }
            });
        });

        $this->command->info("All levels successfully updated with localized quiz configurations!");
    }
}
