<?php

namespace Database\Factories;

use App\Models\Level;
use Illuminate\Database\Eloquent\Factories\Factory;

class LevelFactory extends Factory
{
    protected $model = Level::class;

    public function definition(): array
    {
        static $levelNumber = 1;

        return [
            'group_key' => 'private_driving_theory',
            'level_number' => $levelNumber++, 
            'questions_count' => 30,
            'order' => $levelNumber,
            'is_active' => true,
        ];
    }
}
