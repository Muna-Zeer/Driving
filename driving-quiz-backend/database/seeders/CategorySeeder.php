<?php


namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run()
    {
        Category::factory(20)->create()->each(function ($cat) {
            $hasBadge = rand(0, 1);

            $cat->translations()->create([
                'locale' => 'ar',
                'name'   => 'أسئلة تؤوريا ' . ($cat->type == 'car' ? 'خصوصي' : 'شحن خفيف'),
                'badge'  => $hasBadge ? 'استكمالي' : null,
            ]);

            $cat->translations()->create([
                'locale' => 'en',
                'name'   => 'Theory Questions ' . ucfirst($cat->type),
                'badge'  => $hasBadge ? 'Supplementary' : null, 
            ]);
        });
    }
}
