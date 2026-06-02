<?php

namespace App\Http\Resources;

use Vinkla\Hashids\Facades\Hashids;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LevelResource extends JsonResource
{

    public function toArray(Request $request): array
    {
        $currentLocale = app()->getLocale();

        $translation = $this->translations->where('locale', $currentLocale)->first()
            ?? $this->translations->where('locale', 'ar')->first()
            ?? $this->translations->first();

        return [
            'id'              => Hashids::encode($this->id),
            'category_id'     => Hashids::encode($this->category_id),
            'group_key'       => $this->group_key,
            'level_number'    => (int) $this->level_number,
            'questions_count' => (int) ($this->questions_count ?? $this->questions()->count()),
            'is_active'       => (bool) $this->is_active,

            'name'            => $translation->name ?? null,
            'description'     => $translation->description ?? null,

            'questions'       => QuestionResource::collection($this->whenLoaded('questions')),
        ];

        }
}
