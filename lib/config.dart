import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Values given at compile time with `--dart-define` (or `--dart-define-from-file=.env`).
///
/// Without them, a release build uses the production API, so that the APK built by the CI
/// works as it is, and a debug build uses the API started on this machine.
abstract class CompiledConfig {
  static const String productionDataUrl = 'https://api.floraccess.florobart.fr';
  static const String developmentDataUrl = 'http://localhost:26001';

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Floraccess',
  );

  static const String dataUrl = String.fromEnvironment(
    'DATA_URL',
    defaultValue: kReleaseMode ? productionDataUrl : developmentDataUrl,
  );
}

/// Configuration of the application, loaded once at startup.
///
/// The fields are `late final`: they are assigned only once, at runtime, after the
/// `.env` file is read. They can not be `const`, which would require values known at compile time.
class Config {
  static late final String appName;
  static late final String dataUrl;

  /// Loads the configuration, in this order of priority:
  /// 1) the `.env` file served with the web application (nginx serves it at runtime);
  /// 2) the values given at compile time with `--dart-define`;
  /// 3) the default values of [CompiledConfig].
  ///
  /// The `.env` file is optional: the Android, iOS and desktop applications do not bundle it,
  /// and stopped at startup when it was required.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);

    appName = _resolve('APP_NAME', CompiledConfig.appName);
    dataUrl = _resolve('DATA_URL', CompiledConfig.dataUrl);
  }

  /// Gives the value of the `.env` file when it is set, otherwise the compile time value.
  static String _resolve(String key, String compileTimeValue) {
    final runtimeValue = dotenv.maybeGet(key)?.trim();
    if (runtimeValue == null || runtimeValue.isEmpty) {
      return compileTimeValue;
    }

    return runtimeValue;
  }
}
