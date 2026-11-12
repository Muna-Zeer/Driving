import 'package:flutter/material.dart';

class QuizStatsHeader extends StatelessWidget {
  final int correctAnswers;
  final int wrongAnswers;
  final int xpPoints;
  final int lastXpEarned;

  const QuizStatsHeader({
    super.key,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.xpPoints,
    required this.lastXpEarned,
  });

  Widget _buildState({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
  }) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                  key: ValueKey(value),
                  tween: Tween<double>(
                    begin: value == 0 ? 0 : (value - 1).toDouble(),
                    end: value.toDouble(),
                  ),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  builder: (context, animationValue, child) {
                    return Transform.scale(
                        scale:
                            1.0 + (0.12 * (1 - animationValue - value).abs()),
                        child: Text(animationValue.round().toString(),
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: color,
                            )));
                  }),
              const SizedBox(height: 3),
              Text(label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  )),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          _buildState(
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              label: 'correct',
              value: correctAnswers),
          const SizedBox(width: 10),
          _buildState(
            icon: Icons.cancel_rounded,
            color: Colors.red,
            label: 'Wrong',
            value: wrongAnswers,
          ),
          const SizedBox(width: 10),
          _buildState(
              icon: Icons.bolt_rounded,
              color: Colors.amber,
              label: 'XP points',
              value: xpPoints),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.8),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child));
            },
            child: lastXpEarned > 0
                ? Text('+${lastXpEarned.toString()} XP',
                    key: ValueKey(lastXpEarned),
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ))
                : const SizedBox(
                    key: ValueKey('no-xp'),
                    height: 18,
                  ),
          ),
        ])
      ],
    );
  }
}
