<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateQuestionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // Question translations: Arabic, English, or both.
            'translations' => ['sometimes', 'required', 'array', 'min:1'],
            'translations.*.locale' => ['required', 'string', 'in:en,ar'],
            'translations.*.text' => ['required', 'string'],

            // Options
            'options' => ['sometimes', 'required', 'array', 'size:4'],
            'options.*.identifier' => [
                'required',
                'string',
                'in:A,B,C,D',
            ],
            'options.*.is_correct' => ['required', 'boolean'],
            'options.*.image_url' => ['sometimes', 'nullable', 'string'],

            // Each option can have one or two translations.
            'options.*.translations' => [
                'required',
                'array',
                'min:1',
            ],
            'options.*.translations.*.locale' => [
                'required',
                'string',
                'in:en,ar',
            ],
            'options.*.translations.*.text' => [
                'required',
                'string',
            ],
        ];
    }
}
