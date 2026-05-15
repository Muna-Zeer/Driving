<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Question extends Model
{
    use HasFactory;
    protected $fillable = ['level_id','image_url','order','question_text'];
    public function answer(){
        return $this->hasMany(Answer::class);
    }
    public function level(){
        return $this->belongsTo(Level::class);
    }

    public function options(){
        return $this->hasMany(Options::class);
    }
    public function translations(){
      return $this->morphMany(QuestionTranslation::class, 'translatable');
    }
}
