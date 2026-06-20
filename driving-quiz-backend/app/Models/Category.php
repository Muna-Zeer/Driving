<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Hashids\Hashids;
class Category extends Model
{
    use HasFactory;

    protected $fillable = ['image_url', 'type', 'order', 'is_active'];

    protected $appends = ['hashed_id', 'current_name', 'current_badge'];


    public function getHashedIdAttribute()
    {

        $hashids = new Hashids((string)config('app.key'), 10);
        return $hashids->encode($this->id);
    }

    public function translations()
    {
        return $this->hasMany(CategoryTranslation::class);
    }
    public function getCurrentNameAttribute()
    {
        $translation = $this->translations()->where('locale', app()->getLocale())->first();
        return $translation ? $translation->name : optional($this->translations()->first())->name;
    }
  public function getCurrentBadgeAttribute()
    {
        $translation = $this->translations()->where('locale', app()->getLocale())->first();
        return $translation ? $translation->badge : null;
    }

    public function levels()
    {
        return $this->hasMany(Level::class);
    }
}
