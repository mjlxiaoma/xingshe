import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xingshe/core/permissions/app_permissions.dart';

void main() {
  test(
    'requests permissions only on demand and publishes each status',
    () async {
      final requested = <AppPermission>[];
      final container = ProviderContainer(
        overrides: [
          permissionRequesterProvider.overrideWithValue((permission) async {
            requested.add(permission);
            return PermissionStatus.granted;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appPermissionsProvider), isEmpty);
      expect(requested, isEmpty);

      await container
          .read(appPermissionsProvider.notifier)
          .request(AppPermission.camera);
      await container
          .read(appPermissionsProvider.notifier)
          .request(AppPermission.photos);

      expect(requested, [AppPermission.camera, AppPermission.photos]);
      expect(
        container.read(appPermissionsProvider),
        containsPair(AppPermission.camera, PermissionStatus.granted),
      );
      expect(
        container.read(appPermissionsProvider),
        containsPair(AppPermission.photos, PermissionStatus.granted),
      );
    },
  );
}
