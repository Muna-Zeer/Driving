<?php

namespace App\Http\Requests;

use Vinkla\Hashids\Facades\Hashids;
use Illuminate\Foundation\Http\FormRequest;

class StoreLevelRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }


protected function prepareForValidation()
{
    if ($this->has('category_id') && is_string($this->category_id)) {
        $decoded = Hashids::decode($this->category_id);

        if (!empty($decoded)) {
            $this->merge([
                'category_id' => $decoded[0],
            ]);
        }
    }
}
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'group_key' => ['required', 'string', 'max:100'],
            'level_number' => [
                'required',
                'integer',
                'min:1',
                'unique:levels,level_number,NULL,id,group_key,' . $this->group_key
            ],
            'category_id' => 'required|exists:categories,id',
            'questions_count' => ['required', 'integer', 'min:1'],
            'order' => ['nullable', 'integer'],
            'is_active' => ['boolean'],

            'translations' => 'required|array|min:1',
            'translations.*.locale' => 'required|string|max:2',
            'translations.*.name' => 'nullable|string|max:255',
        ];
    }
}
