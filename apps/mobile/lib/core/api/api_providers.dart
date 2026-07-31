import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    tokenStore: ref.watch(tokenStoreProvider),
    onSessionExpired: () => ref.read(authSessionProvider.notifier).expire(),
  ),
);
