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
    Schema::create('quiz_attempt_answers', function (Blueprint $table) {
        $table->id();

        $table->foreignId('attempt_id')
            ->constrained('quiz_attempts')
            ->cascadeOnDelete();

        $table->foreignId('question_id')
            ->constrained('questions')
            ->cascadeOnDelete();

        $table->char('selected_option', 1);
        $table->boolean('is_correct');
        $table->unsignedInteger('xp_earned')->default(0);

        $table->timestamp('answered_at')->useCurrent();

     
        $table->unique(
            ['attempt_id', 'question_id'],
            'unique_attempt_question'
        );
    });
}


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quiz_attempt_answers');
    }
};
