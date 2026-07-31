import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import 'api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStore: ref.watch(tokenStoreProvider)),
);
