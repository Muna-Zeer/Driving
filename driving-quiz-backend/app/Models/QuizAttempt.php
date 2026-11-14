<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class QuizAttempt extends Model
{
    use HasFactory;
     protected $fillable = [
        'uuid',
        'user_id',
        'level_id',
        'correct_answers',
        'wrong_answers',
        'xp_points',
        'status',
        'started_at',
        'completed_at',
    ];
    protected $casts = [
        'started_at' =>'datetime',
        'completed_at'=>'datetime',
    ];
    protected static function booted():void{
 static::creating(function ($attempt){
    if(empty($attempt->uuid)){
        $attempt->uuid = (string)Str::uuid();
    }
 });
    }
    
    public function user():BelongsTo{
        return $this->belongsTo(User::class);
    }
    public function level():BelongsTo{
        return $this->belongsTo(Level::class);
    }
    public function answers():HasMany{
        return $this->hasMany(QuizAttemptAnswer::class,'attempt_id');
    }
}
