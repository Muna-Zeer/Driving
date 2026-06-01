<?php

namespace Database\Factories;

use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Category>
 */

class CategoryFactory extends Factory
{
    protected $model = Category::class;

    public function definition(): array
    {
        return [
            'image_url' => 'categories/' . $this->faker->word() . '.png',
            'type'      => $this->faker->randomElement(['truck', 'car', 'motorcycle', 'tractor']),
            'order'     => $this->faker->unique()->numberBetween(1, 100),
            'is_active' => true,
        ];
    }
}
