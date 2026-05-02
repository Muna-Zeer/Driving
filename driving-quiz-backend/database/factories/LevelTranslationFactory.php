<?php

namespace Database\Factories;

use App\Models\LevelTranslation;
use Illuminate\Database\Eloquent\Factories\Factory;

class LevelTranslationFactory extends Factory
{
    protected $model = LevelTranslation::class;

    public function definition(): array
    {
        return [
            'locale' => 'ar',
            'name' => 'المستوى ' . $this->faker->numberBetween(1, 500),
            'description' => 'أسئلة تدريبية لامتحان التوريا في فلسطين',
        ];
    }

    public function arabic()
    {
        return $this->state(function () {
            return [
                'locale' => 'ar',
                'name' => 'المستوى ' . $this->faker->unique()->numberBetween(1, 500),
                'description' => 'أسئلة تدريبية لامتحان التوريا',
            ];
        });
    }

    public function english()
    {
        return $this->state(function () {
            return [
                'locale' => 'en',
                'name' => 'Level ' . $this->faker->unique()->numberBetween(1, 500),
                'description' => 'Driving theory practice questions',
            ];
        });
    }
}
