<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OptionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $currentLocale = app()->getLocale();
        $localizedText = $this->translations->where('locale', $currentLocale)->first()?->text
            ?? $this->translations->first()?->text;


        return [
            'identifier'=>$this->identifier,
            'is_correct'=>(bool)$this->is_correct,
            'text'=>$localizedText,
            'translations' => TranslationResource::collection($this->whenLoaded('translations')),
        ];
    }
}
