<?php

namespace Database\Factories;

use App\Models\Level;
use App\Models\Question;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Question>
 */
class QuestionFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    protected $model = Question::class;
    public function definition(): array
    {
       $sampleSigns = ['warning.png', 'stop.png', 'yield.png', 'speed_50.png', 'no_entry.png'];
        return [
            'level_id'=>Level::factory(),
             'image_url'=>$this->faker->boolean(60) ? 'storage/signs/' . $this->faker->randomElement($sampleSigns) : null,
             'order'=>1
        ];
    }
}
