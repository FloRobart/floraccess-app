import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Les variables sont immuables une fois chargées au démarrage.
///
/// Remarque importante : il est impossible d'avoir des `const` qui proviennent
/// d'un fichier `.env` lu à l'exécution. `const` en Dart signifie valeur connue
/// à la compilation. Ici nous utilisons `late final` : les champs sont assignés
/// une seule fois (immutables ensuite) mais doivent être initialisés au runtime
/// après l'appel à `dotenv.load(...)`.
class Config {
  static late final String appName;
  static late final String dataUrl;

  /// Charge les valeurs depuis `dotenv`. Appeler après `await dotenv.load(...)`.
  static void load() {
    appName = dotenv.get('APP_NAME', fallback: 'Floraccess');
    dataUrl = dotenv.get('DATA_URL', fallback: 'http://localhost:26001');
  }
}
