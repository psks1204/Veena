import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veena/core/theme/app_colors.dart';
import 'package:veena/features/notifications/data/models/notification_model.dart';

class NotificationDetailDialog extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailDialog({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MMMM dd, yyyy - hh:mm a').format(notification.createdAt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Notification Detail',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if available
                    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(notification.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    
                    // Title
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Date
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    Text(
                      notification.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Action
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show the dialog
void showNotificationDetail(BuildContext context, NotificationModel notification) {
  showDialog(
    context: context,
    builder: (context) => NotificationDetailDialog(notification: notification),
  );
}
