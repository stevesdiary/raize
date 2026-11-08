import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'sync_manager.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SyncManager(apiClient: apiClient);
});

