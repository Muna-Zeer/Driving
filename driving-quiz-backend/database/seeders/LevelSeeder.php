<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Level;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class LevelSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
       public function run(): void
    {

    $category=Category::first();
    if(!$category){
        $this->command->error("No categories found, please run category seeder");
    }
        $levels=Level::factory()
            ->count(500)
            ->create(
                ['category_id' => $category->id]
            )
            ->each(function ($level) {

                // Arabic
                $level->translations()->create([
                    'locale' => 'ar',
                    'name' => "المستوى {$level->level_number}",
                    'description' => "مجموعة أسئلة تدريبية لامتحان التوريا - المستوى {$level->level_number}",
                ]);

                // English
                $level->translations()->create([
                    'locale' => 'en',
                    'name' => "Level {$level->level_number}",
                    'description' => "Driving theory practice questions - Level {$level->level_number}",
                ]);
                });

    }
}
