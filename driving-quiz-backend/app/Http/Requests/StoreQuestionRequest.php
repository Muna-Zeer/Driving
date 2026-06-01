<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreQuestionRequest extends FormRequest
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
            'level_id'=>'required|string',
            'image_url'=>'nullable|string',
            'question_translations'=>'required|array',
            'options'=>'required|array|size:4',
            'options.*.identifier'=>'required|string|max:1',
            'options.*.is_correct'=>'required|boolean',
            'options.*.translations'=>'required|array'
        ];
    }
}
