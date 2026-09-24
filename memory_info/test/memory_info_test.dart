import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('macOS plugin bundles its disk-space privacy manifest', () {
    final podspec = File('macos/memory_info.podspec').readAsStringSync();
    final manifest = File('macos/Resources/PrivacyInfo.xcprivacy');

    expect(
      podspec,
      contains(
        "s.resource_bundles = {'memory_info_privacy' => ['Resources/PrivacyInfo.xcprivacy']}",
      ),
    );
    expect(manifest.existsSync(), isTrue);
    final contents = manifest.readAsStringSync();
    expect(contents, contains('NSPrivacyAccessedAPICategoryDiskSpace'));
    expect(contents, contains('85F4.1'));
  });
}
