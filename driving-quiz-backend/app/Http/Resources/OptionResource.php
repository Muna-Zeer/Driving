<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OptionResource extends JsonResource
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

        $currentLocale = app()->getLocale();

        $localizedText = $translations
            ->firstWhere('locale', $currentLocale)['text'] ?? '';

        return [
            'identifier' => $this->identifier,
            'is_correct' => (bool) $this->is_correct,
            'text' => $localizedText,
            'image_url' => $this->image_url
                ? url($this->image_url)
                : null,
            'all_option_translations' => $translations,
        ];
    }
}