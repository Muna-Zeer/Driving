<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCategoryRequest;
use App\Http\Requests\UpdateCategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Hashids\Hashids;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\JsonResponse;

class CategoryController extends Controller
{
    protected $hashids;
    public function __construct()
    {
        $this->hashids = new Hashids(config('app.key'), 10);
    }

    private function decodeId($hashedId)
    {
        $decoded = $this->hashids->decode($hashedId);
        return $decoded[0] ?? abort(404, 'Category not found.');
    }
    /**
     * Display a listing of the resource.
     */
    public function index(): JsonResponse
    {
        $categories = Category::with(['translations', 'levels'])
            ->where('is_active', true)
            ->orderBy('order')
            ->get();
        return response()->json([
            'status' => true,
            'data' => CategoryResource::collection($categories)
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreCategoryRequest $request): JsonResponse
    {
        //
        $category = Category::create($request->only(['image_url', 'type', 'order', 'is_active']));
        foreach ($request->translations as $locale => $data) {
            $category->translations()->create([
                'locale' => $locale,
                'name' => $data['name']
            ]);
        }
        return response()->json([
            'status' => true,
            'message' => "Category created successfully",
            'data' => new CategoryResource($category->load('translations'))
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($id): JsonResponse
    {
        //
        $realId = $this->decodeId($id);
        $category = Category::with('translations')->findOrFail($realId);
        return response()->json([
            'status' => true,
            'data' => new CategoryResource($category)
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateCategoryRequest $request, $id): JsonResponse
    {
        //
        $realId = $this->decodeId($id);
        $category = Category::with('translations')->findOrFail($realId);
        $category->update($request->only(['image_url', 'type', 'order', 'is_active']));

        if ($request->has('translations')) {
            foreach ($request->translations as $locale => $data) {
                $category->translations()->updateOrCreate(
                    ['locale' => $locale],
                    ['name' => $data['name']]
                );
            }
        }
        return response()->json([
            'status' => true,
            'message' => 'Category updated successfully',
            'data' => new CategoryResource($category->load('translations'))
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id):JsonResponse
    {
        //
        $realId = $this->decodeId($id);
        Category::findOrFail($realId)->delete();

        return response()->json([
            'status' => true,
            'message' => 'Category deleted successfully'
        ]);
    }
}
