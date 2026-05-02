<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
   public function up(): void
{
    Schema::create('levels', function (Blueprint $table) {
        $table->id();
    
        $table->string('group_key');

        $table->integer('level_number');

        $table->integer('questions_count')->default(30);

        // ترتيب
        $table->integer('order')->default(0);

        $table->boolean('is_active')->default(true);

        $table->timestamps();

        $table->unique(['group_key', 'level_number']);
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('levels');
    }
};
