import 'package:flutter/material.dart';

class QuizStatsHeader extends StatelessWidget {
  final int correctAnswers;
  final int wrongAnswers;
  final int xpPoints;
  final int lastXpEarned;

  final int attemptNumber;
  final int totalAttempts;
  final int remainingAttempts;

  // Retry functionality
  final bool isCompleted;
  final VoidCallback? onRetry;

  const QuizStatsHeader({
    super.key,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.xpPoints,
    required this.lastXpEarned,
    this.attemptNumber = 1,
    this.totalAttempts = 3,
    this.remainingAttempts = 2,
    this.isCompleted = false,
    this.onRetry,
  });

  Widget _buildState({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              key: ValueKey(value),
              tween: Tween<double>(
                begin: value == 0 ? 0 : (value - 1).toDouble(),
                end: value.toDouble(),
              ),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, animationValue, child) {
                return Text(
                  animationValue.round().toString(),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptInfo() {
    final progress = totalAttempts > 0
        ? (attemptNumber / totalAttempts).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.replay_rounded,
                  size: 18,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Attempt $attemptNumber of $totalAttempts',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              isCompleted
                  ? '$remainingAttempts remaining'
                  : '$remainingAttempts left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: remainingAttempts > 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    if (!isCompleted) {
      return const SizedBox.shrink();
    }

    if (remainingAttempts <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'You have used all your exam attempts.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange,
            fontSize: 13,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          'Retry Exam ($remainingAttempts attempts remaining)',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attempt information
        _buildAttemptInfo(),

        const SizedBox(height: 14),

        // Existing statistics
        Row(
          children: [
            _buildState(
              icon: Icons.bolt_rounded,
              color: Colors.amber,
              label: 'XP points',
              value: xpPoints,
            ),
            const SizedBox(width: 8),
            _buildState(
              icon: Icons.cancel_rounded,
              color: Colors.red,
              label: 'Wrong',
              value: wrongAnswers,
            ),
            const SizedBox(width: 8),
            _buildState(
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              label: 'Correct',
              value: correctAnswers,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Existing XP animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.8),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: lastXpEarned > 0
              ? Text(
                  '+${lastXpEarned.toString()} XP',
                  key: ValueKey(lastXpEarned),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : const SizedBox(
                  key: ValueKey('no-xp'),
                  height: 18,
                ),
        ),

        // Retry button appears only after completion
        if (isCompleted) ...[
          const SizedBox(height: 12),
          _buildRetryButton(),
        ],
      ],
    );
  }
}
