import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veena/core/theme/app_colors.dart';
import 'package:veena/features/notifications/presentation/providers/notification_provider.dart';
import 'package:veena/features/notifications/presentation/widgets/notification_item.dart';
import 'package:veena/features/notifications/presentation/widgets/notification_detail_dialog.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => context.read<NotificationProvider>().markAllAsRead(),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return _buildErrorState(provider.error!);
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(refresh: true),
            color: AppColors.primary,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                  );
                }

                final notification = provider.notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () {
                    provider.markAllAsRead(); // Following user instruction literalmente
                    showNotificationDetail(context, notification);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We will notify you when something happens.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<NotificationProvider>().loadNotifications(refresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
