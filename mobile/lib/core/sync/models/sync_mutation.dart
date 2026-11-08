class SyncMutation {
  final String id;
  final String type; // 'log_set', 'create_session', 'log_nutrition', 'manual_activity'
  final Map<String, dynamic> payload;
  final DateTime clientTimestamp;
  final String idempotencyKey;
  final int retryCount;
  final String status; // 'pending', 'syncing', 'quarantined', 'synced'

  const SyncMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.clientTimestamp,
    required this.idempotencyKey,
    this.retryCount = 0,
    this.status = 'pending',
  });

  Map<String, dynamic> toBatchPayload() => {
    'id': id,
    'type': type,
    'payload': payload,
    'clientTimestamp': clientTimestamp.toIso8601String(),
  };

  SyncMutation copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? clientTimestamp,
    String? idempotencyKey,
    int? retryCount,
    String? status,
  }) {
    return SyncMutation(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
    );
  }
}

