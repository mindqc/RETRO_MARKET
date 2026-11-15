import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/base_view_model.dart';
import '../models/notification_item_model.dart';
import '../repositories/communication_engagement_repository.dart';

/// Supported Notification Filter Tabs (M-NT-01)
enum NotificationTabFilter {
  all,
  order,
  auction,
  system,
}

extension NotificationTabFilterExtension on NotificationTabFilter {
  String get label {
    switch (this) {
      case NotificationTabFilter.all:
        return 'TẤT CẢ';
      case NotificationTabFilter.order:
        return 'ĐƠN HÀNG';
      case NotificationTabFilter.auction:
        return 'ĐẤU GIÁ';
      case NotificationTabFilter.system:
        return 'HỆ THỐNG';
    }
  }

  String? get categoryQueryParam {
    switch (this) {
      case NotificationTabFilter.all:
        return null;
      case NotificationTabFilter.order:
        return 'ORDER';
      case NotificationTabFilter.auction:
        return 'AUCTION';
      case NotificationTabFilter.system:
        return 'SYSTEM';
    }
  }
}

/// ViewModel for In-App Notification Center (M-NT-01)
class NotificationViewModel extends BaseViewModel<List<NotificationItemModel>> {
  final CommunicationEngagementRepository repository;

  final List<NotificationItemModel> _notifications = [];
  int _unreadCount = 0;
  NotificationTabFilter _selectedTab = NotificationTabFilter.all;

  NotificationViewModel({required this.repository});

  List<NotificationItemModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  NotificationTabFilter get selectedTab => _selectedTab;

  /// Filtered items based on active tab
  List<NotificationItemModel> get filteredNotifications {
    if (_selectedTab == NotificationTabFilter.all) {
      return List.unmodifiable(_notifications);
    }
    return _notifications.where((n) {
      switch (_selectedTab) {
        case NotificationTabFilter.order:
          return n.isOrderType;
        case NotificationTabFilter.auction:
          return n.isAuctionType;
        case NotificationTabFilter.system:
          return n.isSystemType;
        case NotificationTabFilter.all:
          return true;
      }
    }).toList();
  }

  /// Changes the active filter tab and refreshes or filters notifications
  void selectTab(NotificationTabFilter tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  /// Fetches notifications from backend
  Future<void> fetchNotifications({bool refresh = false}) async {
    setLoading();
    try {
      final res = await repository.fetchNotifications(
        category: _selectedTab.categoryQueryParam,
      );
      final items = res['items'] as List<NotificationItemModel>;
      _unreadCount = res['unread_count'] as int? ?? 0;

      _notifications.clear();
      _notifications.addAll(items);
      setSuccess(List.unmodifiable(_notifications));
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Marks a single notification as read and updates count
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      final updated = _notifications[index].copyWith(isRead: true);
      _notifications[index] = updated;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();

      try {
        await repository.markNotificationAsRead(notificationId);
      } catch (_) {
        // Optimistic update; silently ignore network failure
      }
    }
  }

  /// Marks all notifications as read (M-NT-01 CTA)
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await repository.markAllNotificationsAsRead();
    } catch (_) {
      // Optimistic update; silently ignore network failure
    }
  }

  /// Handles tap on a notification: marks as read and navigates to target route (AC-P711-02)
  void handleNotificationTap(BuildContext context, NotificationItemModel notification) {
    markAsRead(notification.id);

    final route = notification.deepLinkRoute;
    if (route != null && route.isNotEmpty) {
      context.push(route);
      return;
    }

    // Fallback based on target_type and target_id
    if (notification.targetType != null && notification.targetId != null) {
      switch (notification.targetType!.toUpperCase()) {
        case 'ORDER':
          context.push('/orders/${notification.targetId}');
          break;
        case 'AUCTION':
          context.push('/auctions/${notification.targetId}');
          break;
        case 'PRODUCT':
          context.push('/products/${notification.targetId}');
          break;
        case 'CONVERSATION':
          context.push('/messages/${notification.targetId}');
          break;
        default:
          break;
      }
    }
  }
}

/// Riverpod provider for NotificationViewModel
final notificationViewModelProvider = ChangeNotifierProvider.autoDispose<NotificationViewModel>((ref) {
  final repo = ref.watch(communicationEngagementRepositoryProvider);
  return NotificationViewModel(repository: repo);
});
