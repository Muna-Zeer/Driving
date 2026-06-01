<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Option extends Model
{
    use HasFactory;

    protected $table = 'options';
    protected $fillable = ['question_id', 'is_correct', 'identifier'];

    public function question()
    {
        return $this->belongsTo(Question::class);
    }

    public function translations()
    {
        return $this->morphMany(QuestionTranslation::class, 'translatable');
    }
}
