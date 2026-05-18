<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Option extends Model
{
    use HasFactory;

    protected $table = 'options';

    protected $fillable = ['question_id', 'is_correct', 'identifier'];

    /**
     * Polymorphic translations relationship for multi-language option choices (A, B, C, D)
     */
    public function translations()
    {
        return $this->morphMany(QuestionTranslation::class, 'translatable');
    }
}
