<?php

namespace App\Http\Requests;

use App\Models\Level;
use Vinkla\Hashids\Facades\Hashids;
use Illuminate\Foundation\Http\FormRequest;

class UpdateLevelRequest extends FormRequest
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
    $hashedParam = $this->route('id') ?? $this->route('level');

    $levelId = null;
    if (is_string($hashedParam)) {
        $decodedArray = Hashids::decode($hashedParam);
        $levelId = !empty($decodedArray) ? $decodedArray[0] : null;
    }

    $level = $levelId ? Level::find($levelId) : null;

    $groupKey = $this->group_key ?? ($level ? $level->group_key : null);

    return [
        'group_key' => ['sometimes', 'string'],
        'level_number' => [
            'sometimes',
            'integer',
            'min:1',
            "unique:levels,level_number," . ($levelId ?? 'NULL') . ",id,group_key," . ($groupKey ?? 'NULL')
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
