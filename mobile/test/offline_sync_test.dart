import 'package:flutter_test/flutter_test.dart';
import 'package:raize_mobile/core/network/api_client.dart';
import 'package:raize_mobile/core/sync/sync_manager.dart';

void main() {
  group('Offline Synchronization Engine Tests', () {
    late SyncManager syncManager;

    setUp(() {
      syncManager = SyncManager(apiClient: ApiClient());
    });

    test('1. Enqueue mutations generates unique IDs, timestamps, and idempotency keys', () {
      expect(syncManager.pendingCount, 0);

      final mut1 = syncManager.enqueueMutation(
        type: 'log_set',
        payload: {
          'sessionId': 'sess_123',
          'exerciseId': 'ex_bench',
          'weightKg': 80.0,
          'repsCompleted': 8,
        },
      );

      final mut2 = syncManager.enqueueMutation(
        type: 'log_nutrition',
        payload: {
          'mealType': 'dinner',
          'calories': 590,
          'foodName': 'Pounded Yam',
        },
      );

      expect(syncManager.pendingCount, 2);
      expect(mut1.id, isNotEmpty);
      expect(mut2.id, isNotEmpty);
      expect(mut1.id, isNot(equals(mut2.id)));
      expect(mut1.idempotencyKey, startsWith('idemp_log_set-'));
      expect(mut2.idempotencyKey, startsWith('idemp_log_nutrition-'));
      expect(mut1.status, 'pending');
    });

    test('2. Drain queue offline marks items as processed and empties pending outbox', () async {
      syncManager.enqueueMutation(
        type: 'log_set',
        payload: {'reps': 10},
      );
      syncManager.enqueueMutation(
        type: 'manual_activity',
        payload: {'durationMinutes': 30},
      );

      expect(syncManager.pendingCount, 2);

      final result = await syncManager.drainQueue(syncBackend: false);

      expect(result.isSuccess, isTrue);
      expect(result.processedIds.length, 2);
      expect(syncManager.pendingCount, 0);
      expect(syncManager.outboxQueue.isEmpty, isTrue);
    });

    test('3. Delta fetch provides synchronization timestamp', () async {
      final since = DateTime.now().subtract(const Duration(hours: 12));
      final delta = await syncManager.fetchDelta(since: since, syncBackend: false);

      expect(delta, isNotNull);
      expect(delta!['since'], since.toIso8601String());
      expect(delta['delta'], isNotNull);
    });
  });
}

