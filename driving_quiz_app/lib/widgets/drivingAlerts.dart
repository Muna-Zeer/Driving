import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:driving_quiz_app/widgets/AppColors.dart';
class AppAlerts {
  static void showAlert(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Row(
     children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              ),
              
            ),
            
            
          ],
          
      ),
      backgroundColor: AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration:const Duration(seconds: 3),
      )
   );
  }
}
