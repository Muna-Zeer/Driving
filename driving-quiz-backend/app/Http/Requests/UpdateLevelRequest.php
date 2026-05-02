<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateLevelRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return false;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $levelId = $this->route('level')->id;
        $groupKey = $this->group_key ?? $this->route('level')->group_key;

        return [
            'group_key' => ['sometimes', 'string'],
            'level_number' => [
                'sometimes',
                'integer',
                'min:1',
                "unique:levels,level_number,$levelId,id,group_key,$groupKey"
            ],
            'questions_count' => ['sometimes', 'integer', 'min:1'],
            'order' => ['nullable', 'integer'],
            'is_active' => ['boolean'],

            'translations' => ['sometimes', 'array'],
            'translations.ar.name' => ['required_with:translations', 'string'],
            'translations.*.name' => ['required_with:translations', 'string'],
        ];
    }
}
