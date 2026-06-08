<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class SuperAdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::create([
             'name'=>'منى الزير',
             'email'=>'superAdmin@syiaqa.com',
             'password'=>Hash::make('hkSmn092%@&ZDuh!!'),
             'role'=>'super_admin'
        ]);
    }
}
