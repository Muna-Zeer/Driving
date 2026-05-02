<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class LevelTranslation extends Model
{
    use HasFactory;

    protected $fillable = [
        'level_id',
        'locale',
        'name',
        'description'
    ];

    public function level()
    {
        return $this->belongsTo(Level::class);
    }
}
