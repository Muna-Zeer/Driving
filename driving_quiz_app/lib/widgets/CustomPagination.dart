import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:flutter/material.dart';

class CustomPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const CustomPagination({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hide the widget entirely if there is only 1 page or none
    if (totalPages <= 1) return const SizedBox.shrink();

    final List<Widget> pageButtons = [];

    pageButtons.add(
      _buildArrowButton(
        icon: Icons.chevron_left,
        isEnabled: currentPage > 1,
        onPressed: () => onPageChanged(currentPage - 1),
      ),
    );

    for (int i = 1; i <= totalPages; i++) {
      if (totalPages > 5 && (i - currentPage).abs() > 2 && i != 1 && i != totalPages) {
        if (pageButtons.last is! Text && (i == 2 || i == totalPages - 1)) {
          pageButtons.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text('...', style: TextStyle(color: Colors.grey)),
          ));
        }
        continue;
      }

      final bool isSelected = i == currentPage;
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: InkWell(
            onTap: () => onPageChanged(i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                ),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Right Arrow / Next Page
    pageButtons.add(
      _buildArrowButton(
        icon: Icons.chevron_right,
        isEnabled: currentPage < totalPages,
        onPressed: () => onPageChanged(currentPage + 1),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageButtons,
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: isEnabled ? AppColors.primaryGreen : Colors.grey.shade300,
      onPressed: isEnabled ? onPressed : null,
    );
  }
}