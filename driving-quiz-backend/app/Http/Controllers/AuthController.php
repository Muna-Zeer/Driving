<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{

    public function guestAuthenticate(Request $request)
    {
        $request->validate([
            'device_id' => 'required|string'
        ]);


        $user = User::firstOrCreate(
            ['device_id' => $request->device_id],
            [
                'name' => 'زائر مجهول',
                'role' => 'guest'
            ]
        );

        $token = $user->createToken('guest_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'token' => $token,
            'role' => $user->role,
            'name' => $user->name
        ], 200);
    }

    // 2. ترقية حساب الزائر إلى مستخدم دائم (عند محاولة إضافة قسم أو سؤال)
    public function upgradeGuestAccount(Request $request)
    {
        $user = $request->user(); // جلب المستخدم الحالي من التوكن

        if (!$user || $user->role !== 'guest') {
            return response()->json(['error' => 'إجراء غير صالح أو غير مسموح به'], 400);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
        ], [
            'email.unique' => 'البريد الإلكتروني مسجل بالفعل لدينا.',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 أحرف.',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }


        $user->update([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'device_id' => null 
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'تم ترقية الحساب بنجاح',
            'user' => [
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role
            ]
        ], 200);
    }
}
