<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $currentLocale = app()->getLocale();

        // Safe fallback for option text localization
        $localizedText = $this->translations->where('locale', $currentLocale)->first()?->text
            ?? $this->translations->first()?->text;

        return [
            'identifier' => $this->identifier,
            'is_correct' => (bool) $this->is_correct,
            'text'       => $localizedText,

            // FIXED: Map directly to an array instead of calling an external Resource class
            'all_option_translations' => $this->translations->map(function ($translation) {
                return [
                    'locale' => $translation->locale,
                    'text'   => $translation->text
                ];
            }),
        ];
    }
}
