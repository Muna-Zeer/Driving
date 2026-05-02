<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LevelResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = $request->get('lang', 'ar');

        $translation = $this->relationLoaded('translations')
            ? $this->translations->where('locale', $locale)->first()
            : null;

        $translation ??= $this->translations->where('locale', 'ar')->first()
            ?? $this->translations->first();

        return [
            'id' => $this->id,
            'group_key' => $this->group_key,
            'level_number' => $this->level_number,
            'questions_count' => $this->questions_count,
            'is_active' => $this->is_active,

            'name' => $translation->name ?? null,
            'description' => $translation->description ?? null,
        ];
    }
}
