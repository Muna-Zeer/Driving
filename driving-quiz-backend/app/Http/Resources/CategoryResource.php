<?php

namespace App\Http\Resources;

use Vinkla\Hashids\Facades\Hashids;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $currentLocale = app()->getLocale();

        $localized = $this->translations->where('locale', $currentLocale)->first()
            ?? $this->translations->first();

        return [
            'id'         => Hashids::encode($this->id),
            'image'      => $this->image_url ? asset('storage/' . $this->image_url) : asset('images/default-cat.png'),
            'type'       => $this->type,
            'order'      => (int) $this->order,
            'name'       => $localized->name ?? 'N/A',
            'is_active'  => (bool) $this->is_active,
            'created_at' => $this->created_at ? $this->created_at->format('Y-m-d') : null,

            'levels'     => LevelResource::collection($this->whenLoaded('levels')),
        ];
    }
}
