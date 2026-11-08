import 'dart:math';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import 'models/sync_mutation.dart';

class SyncBatchResult {
  final List<String> processedIds;
  final List<String> quarantinedIds;
  final bool isSuccess;

  const SyncBatchResult({
    required this.processedIds,
    required this.quarantinedIds,
    required this.isSuccess,
  });
}

class SyncManager {
  final ApiClient apiClient;
  final List<SyncMutation> _outbox = [];

  SyncManager({required this.apiClient});

  List<SyncMutation> get outboxQueue => List.unmodifiable(_outbox);
  int get pendingCount => _outbox.where((m) => m.status == 'pending').length;

  String generateIdempotencyKey(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = Random().nextInt(999999).toString().padLeft(6, '0');
    return '$prefix-$timestamp-$randomSuffix';
  }

  SyncMutation enqueueMutation({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    final id = 'mut_${DateTime.now().microsecondsSinceEpoch}';
    final idempotencyKey = generateIdempotencyKey('idemp_$type');
    final mutation = SyncMutation(
      id: id,
      type: type,
      payload: payload,
      clientTimestamp: DateTime.now(),
      idempotencyKey: idempotencyKey,
      status: 'pending',
    );

    _outbox.add(mutation);
    return mutation;
  }

  Future<SyncBatchResult> drainQueue({bool syncBackend = false}) async {
    final pending = _outbox.where((m) => m.status == 'pending').toList();
    if (pending.isEmpty) {
      return const SyncBatchResult(
        processedIds: [],
        quarantinedIds: [],
        isSuccess: true,
      );
    }

    if (!syncBackend) {
      // Offline mock resolution
      final processed = pending.map((m) => m.id).toList();
      _outbox.removeWhere((m) => processed.contains(m.id));
      return SyncBatchResult(
        processedIds: processed,
        quarantinedIds: [],
        isSuccess: true,
      );
    }

    try {
      final batchIdempotencyKey = generateIdempotencyKey('batch');
      final payload = {
        'mutations': pending.map((m) => m.toBatchPayload()).toList(),
      };

      final response = await apiClient.client.post(
        '/sync/batch',
        data: payload,
        options: Options(
          headers: {'Idempotency-Key': batchIdempotencyKey},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final processed = List<String>.from(data['processedIds'] ?? []);
        final quarantined = List<String>.from(data['quarantinedIds'] ?? []);

        _outbox.removeWhere((m) => processed.contains(m.id));

        // Mark quarantined items
        for (int i = 0; i < _outbox.length; i++) {
          if (quarantined.contains(_outbox[i].id)) {
            _outbox[i] = _outbox[i].copyWith(status: 'quarantined');
          }
        }

        return SyncBatchResult(
          processedIds: processed,
          quarantinedIds: quarantined,
          isSuccess: true,
        );
      } else {
        return const SyncBatchResult(
          processedIds: [],
          quarantinedIds: [],
          isSuccess: false,
        );
      }
    } catch (_) {
      return const SyncBatchResult(
        processedIds: [],
        quarantinedIds: [],
        isSuccess: false,
      );
    }
  }

  Future<Map<String, dynamic>?> fetchDelta({
    DateTime? since,
    bool syncBackend = false,
  }) async {
    if (!syncBackend) {
      return {
        'since': (since ?? DateTime.now().subtract(const Duration(days: 1))).toIso8601String(),
        'delta': {
          'sessions': [],
          'nutrition': [],
          'activities': [],
        },
      };
    }

    try {
      final queryParam = since != null ? '?since=${since.toIso8601String()}' : '';
      final response = await apiClient.client.get('/sync/delta$queryParam');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

