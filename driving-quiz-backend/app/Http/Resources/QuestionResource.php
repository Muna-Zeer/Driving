<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Vinkla\Hashids\Facades\Hashids;

class QuestionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $currentLocale = app()->getLocale();

        // Extract translations cleanly
        $translationsCollection = collect($this->relations['translations'] ?? $this->translations);
        $localizedItem = $translationsCollection->firstWhere('locale', $currentLocale)
            ?? $translationsCollection->first();
        $localizedQuestion = $localizedItem ? $localizedItem->text : '';

        // Safely extract options array directly
        $optionsCollection = collect($this->relations['options'] ?? $this->options);

        return [
            'id'         => Hashids::encode($this->id),
            'level_id'   => Hashids::encode($this->level_id),
            'image_url'  => $this->image_url ? url($this->image_url) : null,
            'order'      => (int) $this->order,
            'question'   => $localizedQuestion,

            // Directly process the collection to eliminate relationship lookup glitches
            'options'    => OptionResource::collection($optionsCollection),

            'all_question_translations' => $translationsCollection->map(function ($t) {
                return [
                    'locale' => $t->locale,
                    'text'   => $t->text
                ];
            })->all(),
        ];
    }
}
