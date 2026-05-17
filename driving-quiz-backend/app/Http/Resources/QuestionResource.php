<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Vinkla\Hashids\Facades\Hashids;

class QuestionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $currentLocale = app()->getLocale();
        $localizedQuestion = $this->translations->where('locale', $currentLocale)->first()?->text() ?? $this->translations->first()?->text();
        return [
            'id'         => Hashids::encode($this->id),
            'level_id'   => Hashids::encode($this->level_id),
            'image_url'  => $this->image_url ? url($this->image_url) : null,
            'order'      => (int) $this->order,
            'question'   => $localizedQuestion,
            'option'     => OptionResource::collection($this->whenLoaded('options')),
            'all_question_translations' => TranslationResource::collection($this->whenLoaded('translations')),
        ];
    }
}
