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

  UserNotification markRead() => UserNotification(
    id: id,
    userId: userId,
    type: type,
    title: title,
    message: message,
    isRead: true,
    createdAt: createdAt,
  );

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

class UserMeeting {
  const UserMeeting({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.category,
    required this.locationName,
    required this.meetingAt,
    this.place,
    this.memo,
  });

  final int id;
  final int clubId;
  final String clubName;
  final String category;
  final String locationName;
  final DateTime meetingAt;
  final String? place;
  final String? memo;

  factory UserMeeting.fromJson(Map<String, dynamic> json) {
    int parseId(Object? value, String field) {
      if (value is int) return value;
      if (value is num && value == value.toInt()) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw FormatException('모임의 $field 값이 올바르지 않습니다.');
    }

    final clubName = json['club_name'];
    final category = json['category_name'];
    final locationName = json['location_name'];
    final rawMeetingAt = json['meeting_at'];
    final place = json['place'];
    final memo = json['memo'];
    if (clubName is! String ||
        category is! String ||
        locationName is! String ||
        rawMeetingAt is! String ||
        (place != null && place is! String) ||
        (memo != null && memo is! String)) {
      throw const FormatException('모임 정보 응답 형식이 올바르지 않습니다.');
    }
    final meetingAt = DateTime.tryParse(rawMeetingAt);
    if (meetingAt == null) {
      throw const FormatException('모임 날짜 응답 형식이 올바르지 않습니다.');
    }

    return UserMeeting(
      id: parseId(json['id'], 'ID'),
      clubId: parseId(json['club_id'], '동호회 ID'),
      clubName: clubName,
      category: category,
      locationName: locationName,
      meetingAt: meetingAt.toLocal(),
      place: place as String?,
      memo: memo as String?,
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
  List<UserMeeting> _meetings = [];
  bool _isLoadingNotifications = true;
  bool _isLoadingMeetings = true;
  String? _notificationsError;
  String? _meetingsError;
  int _notificationsGeneration = 0;
  int _meetingsGeneration = 0;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _notificationsGeneration++;
    _meetingsGeneration++;
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadNotifications(), _loadMeetings()]);
  }

  Future<void> _loadNotifications() async {
    final generation = ++_notificationsGeneration;
    final token = authToken;
    setState(() {
      _isLoadingNotifications = true;
      _notificationsError = null;
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

      if (!mounted || generation != _notificationsGeneration) return;
      setState(() {
        _notifications = notifications;
        unreadNotificationsCount.value = notifications
            .where((notification) => !notification.isRead)
            .length;
      });
    } on ApiException catch (error) {
      if (!mounted || generation != _notificationsGeneration) return;
      setState(() => _notificationsError = error.message);
    } on FormatException catch (error) {
      if (!mounted || generation != _notificationsGeneration) return;
      setState(() => _notificationsError = error.message);
    } finally {
      if (mounted && generation == _notificationsGeneration) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  Future<void> _loadMeetings() async {
    final generation = ++_meetingsGeneration;
    setState(() {
      _isLoadingMeetings = true;
      _meetingsError = null;
    });

    try {
      final response = await apiGet('/users/me/meetings', token: authToken);
      final rawMeetings = response['meetings'];
      if (rawMeetings is! List) {
        throw const FormatException('다가오는 모임 목록 응답 형식이 올바르지 않습니다.');
      }
      final meetings = rawMeetings.map((rawMeeting) {
        if (rawMeeting is! Map<String, dynamic>) {
          throw const FormatException('모임 정보 응답 형식이 올바르지 않습니다.');
        }
        return UserMeeting.fromJson(rawMeeting);
      }).toList();

      if (!mounted || generation != _meetingsGeneration) return;
      setState(() => _meetings = meetings);
    } on ApiException catch (error) {
      if (!mounted || generation != _meetingsGeneration) return;
      setState(() => _meetingsError = error.message);
    } on FormatException catch (error) {
      if (!mounted || generation != _meetingsGeneration) return;
      setState(() => _meetingsError = error.message);
    } finally {
      if (mounted && generation == _meetingsGeneration) {
        setState(() => _isLoadingMeetings = false);
      }
    }
  }

  Future<void> _markNotificationRead(UserNotification notification) async {
    if (notification.isRead) return;
    try {
      await apiPatch(
        '/users/me/notifications/${notification.id}/read',
        const {},
        token: authToken,
      );
      if (!mounted) return;
      setState(() {
        _notifications = [
          for (final item in _notifications)
            if (item.id == notification.id) item.markRead() else item,
        ];
        unreadNotificationsCount.value = _notifications
            .where((item) => !item.isRead)
            .length;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingNotifications &&
        _isLoadingMeetings &&
        _notifications.isEmpty &&
        _meetings.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshAll,
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
              _buildSectionTitle('다가오는 모임', _meetings.length),
              const SizedBox(height: 10),
              if (_isLoadingMeetings)
                const Center(child: CircularProgressIndicator())
              else if (_meetingsError != null)
                _InlineLoadError(
                  message: _meetingsError!,
                  onRetry: _loadMeetings,
                )
              else if (_meetings.isEmpty)
                const _InlineEmptyMessage(message: '예정된 모임이 없습니다.')
              else
                for (final meeting in _meetings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MeetingTile(meeting: meeting),
                  ),
              const SizedBox(height: 18),
              _buildSectionTitle('알림', _notifications.length),
              const SizedBox(height: 10),
              if (_isLoadingNotifications)
                const Center(child: CircularProgressIndicator())
              else if (_notificationsError != null)
                _InlineLoadError(
                  message: _notificationsError!,
                  onRetry: _loadNotifications,
                )
              else if (_notifications.isEmpty)
                const _EmptyNotifications()
              else
                for (final notification in _notifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationTile(
                      notification: notification,
                      onTap: () => _markNotificationRead(notification),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
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

class _InlineEmptyMessage extends StatelessWidget {
  const _InlineEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({required this.meeting});

  final UserMeeting meeting;

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(meeting.category);
    final date = meeting.meetingAt;
    final dateLabel =
        '${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: category.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.clubName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateLabel · ${meeting.place ?? meeting.locationName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (meeting.memo?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    meeting.memo!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final UserNotification notification;
  final VoidCallback onTap;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
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
        ),
      ),
    );
  }
}
