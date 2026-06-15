<?php

namespace App\Http\Requests;

use App\Models\Category;
use Illuminate\Foundation\Http\FormRequest;

class StoreCategoryRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array

    {
     
        return [
            'image_url' => 'nullable|string',
            'type' => 'required|string|max:50',
            'order' =>'nullable|integer',
            'is_active' => 'boolean',
            'translations' => 'required|array',
            'translations.*.locale' => 'required|string|max:2',
            'translations.*.name'   => 'required|string|max:255',
            'translations.*.badge'  => 'nullable|string|max:50',
        ];
    }
}
