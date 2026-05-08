<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;


class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run()
    {
        // 1. Generate 20 categories using the factory
        Category::factory(20)->create()->each(function ($cat) {



            $cat->translations()->create([
                'locale' => 'ar',
                'name'   =>  '  اسم التصنيف  ' . $cat->id,
            ]);

            $cat->translations()->create([
                'locale' => 'en',
                'name'   => 'Category Name ' . $cat->id,
            ]);
        });
    }

}
