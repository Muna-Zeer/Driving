<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Vinkla\Hashids\Facades\Hashids;

class QuestionResource extends JsonResource
{
    private function normalizeLocale($locale): string
    {
        return match ((string) $locale) {
            '0', 'ar' => 'ar',
            '1', 'en' => 'en',
            default => '',
        };
    }

    public function toArray(Request $request): array
    {
        $translations = $this->translations
            ->map(function ($translation) {
                return [
                    'locale' => $this->normalizeLocale($translation->locale),
                    'text' => $translation->text,
                ];
            })
            ->filter(fn ($translation) => $translation['locale'] !== '')
            ->unique('locale')
            ->values();

        $options = $this->options;

        $currentLocale = app()->getLocale();

        $localizedQuestion = $translations
            ->firstWhere('locale', $currentLocale)['text'] ?? '';

        return [
            'id' => Hashids::encode($this->id),
            'level_id' => Hashids::encode($this->level_id),
            'image_url' => $this->image_url
                ? url($this->image_url)
                : null,
            'order' => (int) $this->order,
            'question' => $localizedQuestion,
            'all_question_translations' => $translations,
            'options' => OptionResource::collection($options),
        ];
    }
}