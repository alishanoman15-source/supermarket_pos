/// An in-app notification (SPEC §19, §63). Table `notifications`.
class AppNotification {
  final String id;
  final String type; // LOW_STOCK | OUT_OF_STOCK | EXPIRING_SOON | ...
  final String title;
  final String? body;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.isRead,
    required this.data,
    required this.createdAt,
    this.body,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        type: (map['type'] as String?) ?? 'GENERAL',
        title: (map['title'] as String?) ?? '',
        body: map['body'] as String?,
        isRead: (map['is_read'] as bool?) ?? false,
        data: map['data'] == null
            ? const {}
            : Map<String, dynamic>.from(map['data'] as Map),
        createdAt: map['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['created_at'] as String).toLocal(),
      );
}
