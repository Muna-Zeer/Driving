<?php

namespace App\Http\Resources;

use Hashids\Hashids;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $hashids = new Hashids(config('app.key'), 10);
        return[
          'id' => $hashids->encode($this->id),
          'image' => $this->image_url ? asset('storage/' . $this->image_url) : asset('images/default-cat.png'),
          'type'=>$this->type,
          'order'=>$this->order,
          'name'=>$this->translations()->where('locale',app()->getLocale())->first()->name ??
          $this->translations->first()->name ?? 'N/A',
          'is_active'=>(bool)$this->is_active,
          'created_at'=>$this->created_at->format('Y-m-d'),

        ];
    }
}
