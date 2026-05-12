<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCategoryRequest extends FormRequest
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
            //
            'image_url' => 'nullable|string',
            'type' => 'required|string|max:50',
            'order' => 'integer',
            'is_active' => 'boolean',
            'translations' => 'sometimes|array',
            'translations.*.name' => 'required|string|max:255',
        ];
    }
}
