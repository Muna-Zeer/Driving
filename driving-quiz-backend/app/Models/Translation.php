<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Translation extends Model
{
    use HasFactory;
    protected $table = 'question_translations';

    protected $fillable = ['locale', 'text', 'translatable_type', 'translatable_id'];

    public function translatable()
    {
        return $this->morphTo();
    }
}
