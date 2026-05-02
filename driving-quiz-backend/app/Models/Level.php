<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\LevelTranslation;
use App\Models\LevelTranslation as ModelsLevelTranslation;




class Level extends Model
{
    use HasFactory;

    protected $fillable = [
        'group_key',
        'level_number',
        'questions_count',
        'order',
        'is_active'
    ];

    public function questions()
    {
        return $this->hasMany(Question::class);
    }

    public function translations()
    {
        return $this->hasMany(LevelTranslation::class);
    }

    public function category()
{
    return $this->belongsTo(Category::class);
}
}
