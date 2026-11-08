<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateQuestionRequest extends FormRequest
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
           
'translations' => 'sometimes|required|array|min:1',
'translations.*.locale' => 'required|in:en,ar',
'translations.*.text' => 'required|string',

'options' => 'sometimes|required|array|min:1',
'options.*.identifier' => 'required|in:A,B,C,D',
'options.*.is_correct' => 'required|boolean',
'options.*.image_url' => 'sometimes|nullable|string',

'options.*.translations' => 'required|array|min:1',
'options.*.translations.*.locale' => 'required|in:en,ar',
'options.*.translations.*.text' => 'required|string',

        ];
    }
}
