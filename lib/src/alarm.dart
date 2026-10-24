import 'package:flutter/material.dart';
import 'package:habl/src/api_client.dart';
import 'package:habl/src/auth.dart';
import 'package:habl/src/theme.dart';

class UserNotification {
  const UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    int parseId(Object? value, String field) {
      if (value is int) return value;
      if (value is num && value == value.toInt()) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw FormatException('알림의 $field 값이 올바르지 않습니다.');
    }

    final type = json['type'];
    final title = json['title'];
    final message = json['message'];
    final rawIsRead = json['is_read'];
    final rawCreatedAt = json['created_at'];
    if (type is! String ||
        title is! String ||
        message is! String ||
        rawCreatedAt is! String) {
      throw const FormatException('알림 정보 응답 형식이 올바르지 않습니다.');
    }

    final isRead = switch (rawIsRead) {
      bool value => value,
      num value when value == 0 => false,
      num value when value == 1 => true,
      _ => throw const FormatException('알림 읽음 상태 응답 형식이 올바르지 않습니다.'),
    };
    final createdAt = DateTime.tryParse(rawCreatedAt);
    if (createdAt == null) {
      throw const FormatException('알림 날짜 응답 형식이 올바르지 않습니다.');
    }

    return UserNotification(
      id: parseId(json['id'], 'ID'),
      userId: parseId(json['user_id'], '사용자 ID'),
      type: type,
      title: title,
      message: message,
      isRead: isRead,
      createdAt: createdAt.toLocal(),
    );
  }
}

class Alarm extends StatefulWidget {
  const Alarm({super.key});

  @override
  State<Alarm> createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  List<UserNotification> _notifications = [];
  bool _isLoading = true;
  String? _loadError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final generation = ++_loadGeneration;
    final token = authToken;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await apiGet('/users/me/notifications', token: token);
      final rawNotifications = response['notifications'];
      if (rawNotifications is! List) {
        throw const FormatException('알림 목록 응답 형식이 올바르지 않습니다.');
      }

      final notifications = rawNotifications.map((rawNotification) {
        if (rawNotification is! Map<String, dynamic>) {
          throw const FormatException('알림 정보 응답 형식이 올바르지 않습니다.');
        }
        return UserNotification.fromJson(rawNotification);
      }).toList();

      if (!mounted || generation != _loadGeneration) return;
      setState(() => _notifications = notifications);
    } on ApiException catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error.message);
    } on FormatException catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loadError = error.message);
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _notifications.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null && _notifications.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadNotifications,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadNotifications,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              const Text(
                '알림',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              if (_loadError != null)
                _InlineLoadError(
                  message: _loadError!,
                  onRetry: _loadNotifications,
                )
              else if (_notifications.isEmpty)
                const _EmptyNotifications()
              else
                for (final notification in _notifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationTile(notification: notification),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          SizedBox(height: 14),
          Text(
            '새로운 알림이 없습니다.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final UserNotification notification;

  String get _createdAtLabel {
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);
    if (difference.isNegative || difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    return '${notification.createdAt.month}월 ${notification.createdAt.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.surface : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _createdAtLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
