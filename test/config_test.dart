import 'package:floraccess_app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /* The fields of Config are assigned only once: the whole loading is checked by a single test */
  test('starts without a .env file, like the Android application which does not bundle it', () async {
    await Config.load();

    /* The tests run in debug mode: without .env nor --dart-define, the local API is used */
    expect(Config.dataUrl, CompiledConfig.developmentDataUrl);
    expect(Config.appName, 'Floraccess');
  });
}
