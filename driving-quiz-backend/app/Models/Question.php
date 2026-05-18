<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Question extends Model
{
    use HasFactory;

    // Removed 'question_text' from fillable
    protected $fillable = ['level_id', 'image_url', 'order'];

    public function level()
    {
        return $this->belongsTo(Level::class);
    }

    /**
     * Updated to point to the correct singular Option class model
     */
    public function options()
    {
        return $this->hasMany(Option::class, 'question_id');
    }

    public function translations()
    {
        return $this->morphMany(QuestionTranslation::class, 'translatable');
    }
}
